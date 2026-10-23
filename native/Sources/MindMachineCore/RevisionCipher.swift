/* Authenticated app-side encryption for the CloudKit and fake-engine boundary.
 Content is encrypted before CKRecord.encryptedValues adds Apple's encryption.
 The founder pairs a 256-bit recovery key; no service receives that key. */
import Foundation
import CryptoKit

public enum RevisionCipher {
    private static let context = Data("com.getstatemachine.mindmachine.revision.v1".utf8)
    public static func seal(_ revision: NoteRevision, key: SymmetricKey) throws -> Data {
        try AES.GCM.seal(JSONEncoder().encode(revision), using: key, authenticating: context).combined!
    }
    public static func open(_ data: Data, key: SymmetricKey) throws -> NoteRevision {
        let plaintext = try AES.GCM.open(AES.GCM.SealedBox(combined: data), using: key, authenticating: context)
        return try JSONDecoder().decode(NoteRevision.self, from: plaintext)
    }
}

extension VaultFile {
    /// A resident vault cannot be uploaded into a different iCloud account.
    /// Changing account requires a separate explicit export/new-vault decision.
    public func bindSyncAccount(_ account: String) throws {
        let identity = Data(account.utf8)
        if let previous = try syncValue("account"), previous != identity { throw SyncFailure.accountChanged }
        try setSyncValue("account", identity)
    }
}

public enum SyncFailure: LocalizedError {
    case accountChanged, missingKey, invalidKey, unavailable, remoteReset
    public var errorDescription: String? {
        switch self {
        case .accountChanged: return "iCloud account changed. Sync paused; your local notes are kept. Return to the paired account."
        case .missingKey: return "Pair your private sync key in the companion app before syncing."
        case .invalidKey: return "Enter the 32-byte Base64 private sync key from your paired device."
        case .unavailable: return "Sign into iCloud and enable iCloud Drive to sync. Local saves remain available."
        case .remoteReset: return "The cloud zone was removed. Sync paused; local notes are kept."
        }
    }
}
