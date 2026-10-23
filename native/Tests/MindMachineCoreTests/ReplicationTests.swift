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
