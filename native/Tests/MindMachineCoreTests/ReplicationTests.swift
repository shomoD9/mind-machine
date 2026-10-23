/* Public encrypted two-vault replication tests. A fake cloud transports opaque
 envelopes only; SwiftPM/macOS CI runs the same merge boundary as CloudKit. */
import XCTest
import CryptoKit
import MindMachineCore

final class ReplicationTests: XCTestCase {
    // Both offline edits survive delivery in either order and repeated fetches.
    func testOfflineConcurrentOriginalsConvergeWithoutResurrection() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let a = VaultFile(url: directory.appendingPathComponent("a/vault.json"))
        let b = VaultFile(url: directory.appendingPathComponent("b/vault.json"))
        let key = SymmetricKey(size: .bits256)
        let cloud = FakeRevisionCloud()
        let original = Capture(text: "Original passport location")
        try a.append(original)
        try cloud.sync(a, key: key)
        try cloud.sync(b, key: key)
        try a.update { $0.captures[0].text = "Phone offline original" }
        try b.update { $0.captures[0].text = "Mac offline original" }
        try cloud.sync(b, key: key)
        try cloud.sync(a, key: key)
        try cloud.sync(b, key: key)
        XCTAssertEqual(Set(try a.read().captures.map(\.text)), ["Phone offline original", "Mac offline original"])
        XCTAssertEqual(try a.read(), try b.read())
        XCTAssertFalse(cloud.payloads.contains { String(data: $0, encoding: .utf8)?.contains("passport") == true })
        // Delete the logical source, then deliver an older offline replica again.
        try a.update { $0.captures.removeAll() }
        try cloud.sync(a, key: key)
        try cloud.sync(b, key: key)
        XCTAssertTrue(try b.search("original").isEmpty)
        XCTAssertTrue(try b.read().captures.isEmpty)
        XCTAssertThrowsError(try RevisionCipher.open(cloud.payloads[0], key: SymmetricKey(size: .bits256)))
    }

    // Editing one concurrent result must retain the other branch and remain
    // stable when an older source revision is delivered again.
    func testEditingConflictCopyPreservesBothBranches() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = VaultFile(url: folder.appendingPathComponent("vault.json"))
        let original = Capture(text: "base")
        let base = NoteRevision(capture: original, parents: [])
        let phone = NoteRevision(noteID: original.id, capture: Capture(id: original.id, text: "phone"), parents: [base.id])
        let mac = NoteRevision(noteID: original.id, capture: Capture(id: original.id, text: "mac"), parents: [base.id])
        try store.merge([base, phone, mac])
        let copy = try XCTUnwrap(try store.read().captures.first { $0.id != original.id })
        let retained = try XCTUnwrap(try store.read().captures.first { $0.id == original.id }).text
        try store.update { vault in
            let index = vault.captures.firstIndex { $0.id == copy.id }!
            vault.captures[index].text = "edited conflict copy"
        }
        try store.merge([base])
        XCTAssertEqual(Set(try store.read().captures.map(\.text)), [retained, "edited conflict copy"])
    }

    // Account changes pause exchange before a single original can cross accounts.
    func testAccountBindingRetainsVaultAndRejectsAnotherAccount() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = VaultFile(url: folder.appendingPathComponent("vault.json"))
        try store.append(Capture(text: "Keep locally after sign out"))
        try store.bindSyncAccount("alice")
        XCTAssertThrowsError(try store.bindSyncAccount("bob"))
        XCTAssertEqual(try store.read().captures.first?.text, "Keep locally after sign out")
        XCTAssertEqual(try store.pendingRevisions().count, 1)
    }
}

private final class FakeRevisionCloud {
    var payloads: [Data] = []
    // A network failure before acknowledgement leaves the same durable queue.
    func sync(_ store: VaultFile, key: SymmetricKey) throws {
        let outgoing = try store.pendingRevisions()
        for revision in outgoing { payloads.append(try RevisionCipher.seal(revision, key: key)) }
        try store.merge(payloads.map { try RevisionCipher.open($0, key: key) })
        try store.acknowledge(outgoing.map(\.id))
    }
}
