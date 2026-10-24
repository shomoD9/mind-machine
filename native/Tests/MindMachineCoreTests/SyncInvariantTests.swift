/* Replays PR #2's four TLC counterexamples through VaultFile's public API.
 SwiftPM/macOS CI checks the visible Recall projection and durable outbox. */
import XCTest
import MindMachineCore

final class SyncInvariantTests: XCTestCase {
    private var folder: URL!
    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }
    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: folder) }
    private func store(_ name: String) -> VaultFile { VaultFile(url: folder.appendingPathComponent(name + "/vault.json")) }

    // Identical offline checkbox changes represent one visible original. Deleting
    // that folded original must also cover both equivalent revision branches.
    func testIdenticalOfflineChecklistEditsFold() throws {
        let a = store("a"), b = store("b")
        let original = Capture(text: "Pack", checklist: [ChecklistItem(text: "Passport")])
        try a.append(original)
        try b.merge(a.pendingRevisions())
        try a.update { $0.captures[0].checklist[0].complete = true }
        try b.update { $0.captures[0].checklist[0].complete = true }
        try a.merge(b.pendingRevisions())
        try b.merge(a.pendingRevisions())
        XCTAssertEqual(try a.read().captures.count, 1, "Identical ticks must show once")
        XCTAssertEqual(try a.read(), try b.read())
        try a.update { $0.captures.removeAll() }
        try b.merge(a.pendingRevisions())
        XCTAssertTrue(try b.read().captures.isEmpty, "Deleting the folded copy must cover both heads")
    }

    func testDeletingConflictCopyKeepsOtherCopy() throws {
        let a = store("a"), b = store("b")
        try a.append(Capture(text: "base"))
        try b.merge(a.pendingRevisions())
        try a.update { $0.captures[0].text = "phone" }
        try b.update { $0.captures[0].text = "mac" }
        try a.merge(b.pendingRevisions())
        let removed = try XCTUnwrap(try a.read().captures.first { $0.text == "phone" })
        try a.update { $0.captures.removeAll { $0.id == removed.id } }
        try b.merge(a.pendingRevisions())
        XCTAssertEqual(try a.read().captures.map(\.text), ["mac"], "Delete only the selected branch")
        XCTAssertEqual(try a.read(), try b.read())
    }

    func testDeletePreservesUnseenOfflineEdit() throws {
        let a = store("a"), b = store("b")
        try a.append(Capture(text: "base"))
        try b.merge(a.pendingRevisions())
        try a.update { $0.captures.removeAll() }
        try b.update { $0.captures[0].text = "unseen offline edit" }
        try a.merge(b.pendingRevisions())
        try b.merge(a.pendingRevisions())
        XCTAssertEqual(try a.read().captures.map(\.text), ["unseen offline edit"], "A delete cannot cover an unseen edit")
        XCTAssertEqual(try a.read(), try b.read())
    }

    // CloudKit can reorder a batch even if the outbox is ordered. Keep the last
    // complete projection until the missing parent arrives, then advance once.
    func testOutOfOrderRevisionsNeverShowStaleCopyBesideNewer() throws {
        let a = store("a"), b = store("b")
        try a.append(Capture(text: "base"))
        let base = try XCTUnwrap(try a.pendingRevisions().first)
        try b.merge([base])
        try a.update { $0.captures[0].text = "middle" }
        let middle = try XCTUnwrap(try a.pendingRevisions().first { $0.capture?.text == "middle" })
        try a.update { $0.captures[0].text = "newest" }
        let newest = try XCTUnwrap(try a.pendingRevisions().first { $0.capture?.text == "newest" })
        try b.merge([newest])
        XCTAssertEqual(try b.read().captures.map(\.text), ["base"], "Incomplete ancestry must not publish a stale conflict")
        try b.merge([middle])
        XCTAssertEqual(try b.read().captures.map(\.text), ["newest"])
        try b.merge([base, newest])
        XCTAssertEqual(try b.search("").map(\.capture.text), ["newest"], "Replay cannot regress Recall")
    }
    // A real outbox crosses its 100-row boundary with 150 queued edits. Reverse
    // each fetched batch to model CloudKit's unordered modifications.
    func testRevisionChainAcrossHundredRecordBatches() throws {
        let a = store("a"), b = store("b")
        try a.append(Capture(text: "version 0"))
        for version in 1...150 {
            try a.update { $0.captures[0].text = "version \(version)" }
        }
        var delivered = 0
        while !(try a.pendingRevisions()).isEmpty {
            let batch = try a.pendingRevisions()
            XCTAssertLessThanOrEqual(batch.count, 100)
            for revision in batch.reversed() {
                try b.merge([revision])
                XCTAssertLessThanOrEqual(try b.read().captures.count, 1, "A missing parent must never create a stale conflict")
            }
            try a.acknowledge(batch.map(\.id))
            delivered += batch.count
        }
        XCTAssertEqual(delivered, 151)
        XCTAssertEqual(try b.read().captures.map(\.text), ["version 150"])
    }

    // An unordered delete cannot identify ancestors hidden behind its missing
    // parent. Once the parent arrives, the applied deletion cannot resurrect.
    func testIncompleteTombstoneWaitsForItsParentBeforeApplyingDelete() throws {
        let a = store("a"), b = store("b")
        try a.append(Capture(text: "base"))
        let base = try XCTUnwrap(try a.pendingRevisions().first)
        try a.update { $0.captures[0].text = "edited" }
        let edit = try XCTUnwrap(try a.pendingRevisions().first { $0.capture?.text == "edited" })
        try a.update { $0.captures.removeAll() }
        let deletion = try XCTUnwrap(try a.pendingRevisions().first { $0.capture == nil })
        try b.merge([base, deletion])
        XCTAssertEqual(try b.read().captures.map(\.text), ["base"])
        try b.merge([edit])
        XCTAssertTrue(try b.read().captures.isEmpty)
        try b.merge([base, edit, deletion])
        XCTAssertTrue(try b.search("").isEmpty, "An applied deletion must never resurrect on replay")
    }

}
