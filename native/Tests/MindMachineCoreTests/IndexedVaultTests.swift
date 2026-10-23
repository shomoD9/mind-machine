/* Saved-vault acceptance tests run by SwiftPM/macOS CI. They exercise migration,
 durable reopening and Find through the same VaultFile interface as the apps. */
import XCTest
import MindMachineCore

final class IndexedVaultTests: XCTestCase {
    // Migration must preserve the untouched legacy source and its exact original.
    func testLegacyMigrationAndPrefixTypoHighlights() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("vault.json")
        var legacy = Vault()
        let note = Capture(text: "Birthday telescope for Mira — keep original!")
        legacy.captures = [note]
        let source = try JSONEncoder().encode(legacy)
        try source.write(to: url)
        let store = VaultFile(url: url)
        XCTAssertEqual(try store.search("teles").first?.capture, note)
        XCTAssertEqual(try store.search("telescpoe").first?.capture, note)
        XCTAssertEqual(try store.search("teles").first?.highlightedText, "Birthday ⟦telescope⟧ for Mira — keep original!")
        XCTAssertEqual(try Data(contentsOf: url), source)
        XCTAssertEqual(try VaultFile(url: url).read(), legacy)
    }
}
