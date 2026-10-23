/* CKSyncEngine adapter called by VaultModel on app/keyboard activation and after
 local commits. Each process keeps its own cursor; all share the durable outbox.
 Immutable encrypted revision IDs make duplicate uploads safe across processes. */
import Foundation
import CloudKit
import CryptoKit

@available(iOS 17.0, macOS 14.0, *)
public actor PrivateCloudSync: CKSyncEngineDelegate {
    private let store: VaultFile
    private let container: CKContainer
    private let key: SymmetricKey
    private let cursor: String
    private let zone = CKRecordZone.ID(zoneName: "MindMachinePrivateV1", ownerName: CKCurrentUserDefaultName)
    private var engine: CKSyncEngine?
    private var active = false
    private var stopped: Error?
    public private(set) var status = "Private sync ready"

    public init(store: VaultFile, containerIdentifier: String, key: SymmetricKey, client: String) {
        self.store = store; self.container = CKContainer(identifier: containerIdentifier)
        self.key = key; self.cursor = "engine." + client
    }

    // An iCloud identity check precedes every manual exchange. Account-change
    // events stop callbacks too; no sign-out path erases or rehomes the local vault.
    public func synchronize() async throws {
        guard !active else { return }
        if let stopped { throw stopped }
        active = true; defer { active = false }
        do {
            guard try await container.accountStatus() == .available else { throw SyncFailure.unavailable }
            let account = try await container.userRecordID().recordName
            try store.bindSyncAccount(account)
            if engine == nil {
                let data = try store.syncValue(cursor)
                let state = try data.map { try JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: $0) }
                var config = CKSyncEngine.Configuration(database: container.privateCloudDatabase, stateSerialization: state, delegate: self)
                // Explicit foreground requests work inside the keyboard. The OS
                // gives no fixed background delivery deadline to an extension.
                config.automaticallySync = false
                engine = CKSyncEngine(config)
            }
            guard let engine else { return }
            // Bounded batches let a keyboard save overtake an initial backlog.
            // A failed batch leaves its queue durable for the next activation.
            for _ in 0..<5 {
                let pending = try store.pendingRevisions()
                guard !pending.isEmpty else { break }
                engine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: zone))])
                engine.state.add(pendingRecordZoneChanges: pending.map { .saveRecord(recordID($0.id)) })
                try await engine.sendChanges()
                if let stopped { throw stopped }
                if Set(try store.pendingRevisions().map(\.id)) == Set(pending.map(\.id)) { break }
            }
            try await engine.fetchChanges()
            if let stopped { throw stopped }
            status = try store.pendingRevisions().isEmpty ? "Private sync up to date" : "Saved locally · sync pending"
        } catch { status = "Sync waiting: \(error.localizedDescription)"; throw error }
    }

    public func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        guard stopped == nil else { return }
        do {
            switch event {
            case .stateUpdate(let update):
                try store.setSyncValue(cursor, JSONEncoder().encode(update.stateSerialization))
            case .accountChange(let change):
                // Initial sign-in is safe only after the identity check above.
                switch change.changeType {
                case .signIn: break
                case .signOut, .switchAccounts: stopped = SyncFailure.accountChanged
                @unknown default: stopped = SyncFailure.accountChanged
                }
            case .fetchedRecordZoneChanges(let changes):
                var revisions: [NoteRevision] = []
                for modification in changes.modifications where modification.record.recordID.zoneID == zone {
                    guard let bytes = modification.record.encryptedValues["sealedRevision"] as? Data else { throw SyncFailure.invalidKey }
                    let revision = try RevisionCipher.open(bytes, key: key)
                    guard revision.id.uuidString == modification.record.recordID.recordName else { throw SyncFailure.invalidKey }
                    revisions.append(revision)
                }
                try store.merge(revisions)
                // App deletions are encrypted tombstones, never CK record deletes.
                if !changes.deletions.isEmpty { throw SyncFailure.remoteReset }
            case .fetchedDatabaseChanges(let changes):
                if changes.deletions.contains(where: { $0.zoneID == zone }) { throw SyncFailure.remoteReset }
            case .sentRecordZoneChanges(let changes):
                try store.acknowledge(changes.savedRecords.compactMap { UUID(uuidString: $0.recordID.recordName) })
                for failure in changes.failedRecordSaves {
                    switch failure.error.code {
                    case .serverRecordChanged:
                        // Another process may have uploaded the same revision.
                        // Authenticate equality before accepting that acknowledgement.
                        guard let server = failure.error.serverRecord,
                              let bytes = server.encryptedValues["sealedRevision"] as? Data else { throw SyncFailure.invalidKey }
                        let received = try RevisionCipher.open(bytes, key: key)
                        guard let ownBytes = failure.record.encryptedValues["sealedRevision"] as? Data,
                              try RevisionCipher.open(ownBytes, key: key) == received else { throw SyncFailure.invalidKey }
                        try store.acknowledge([received.id])
                        syncEngine.state.remove(pendingRecordZoneChanges: [.saveRecord(server.recordID)])
                    case .zoneNotFound:
                        syncEngine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: zone))])
                        syncEngine.state.add(pendingRecordZoneChanges: [.saveRecord(failure.record.recordID)])
                    default:
                        // The durable outbox is retained for the next activation.
                        status = "Sync waiting: \(failure.error.localizedDescription)"
                    }
                }
            default: break
            }
        } catch {
            // Never persist a later fetch token after decryption/merge failure.
            // Relaunch retries from the last committed cursor and keeps originals.
            stopped = error; status = "Sync paused: \(error.localizedDescription)"
        }
    }

    public func nextRecordZoneChangeBatch(_ context: CKSyncEngine.SendChangesContext, syncEngine: CKSyncEngine) async -> CKSyncEngine.RecordZoneChangeBatch? {
        guard stopped == nil else { return nil }
        do {
            let revisions = try store.pendingRevisions()
            let records = try Dictionary(uniqueKeysWithValues: revisions.prefix(100).map { revision -> (CKRecord.ID, CKRecord) in
                let record = CKRecord(recordType: "MindMachineRevisionV1", recordID: recordID(revision.id))
                record.encryptedValues["sealedRevision"] = try RevisionCipher.seal(revision, key: key) as NSData
                return (record.recordID, record)
            })
            let changes = syncEngine.state.pendingRecordZoneChanges.filter { context.options.scope.contains($0) }.filter { change in
                if case .saveRecord(let id) = change { return records[id] != nil }
                return false
            }
            guard !changes.isEmpty else { return nil }
            return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: changes) { records[$0] }
        } catch { stopped = error; status = "Sync paused: \(error.localizedDescription)"; return nil }
    }
    private func recordID(_ id: UUID) -> CKRecord.ID { CKRecord.ID(recordName: id.uuidString, zoneID: zone) }
}
