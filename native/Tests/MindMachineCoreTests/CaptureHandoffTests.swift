/* Portable Capture handoff behavior exercised by SwiftPM on Linux and Mac.
 The Mac VaultModel uses this public boundary to acknowledge slow saves safely. */
import XCTest
import MindMachineCore

final class CaptureHandoffTests: XCTestCase {
    @MainActor
    func testHeldStorageDoesNotPreventMainActorDraftEdits() async throws {
        let started = expectation(description: "write entered off main actor")
        let release = DispatchSemaphore(value: 0)
        defer { release.signal() }
        let storage = CaptureStorage(append: { _ in
            started.fulfill()
            guard release.wait(timeout: .now() + 5) == .success else { throw URLError(.timedOut) }
        }, load: { _ in Vault() })
        var handoff = CaptureHandoff()
        let submission = try XCTUnwrap(handoff.begin(source: "**before**", richText: nil))
        let save = Task { try await storage.save(submission.capture) }
        await fulfillment(of: [started], timeout: 2)
        handoff.edited()
        release.signal()
        try await save.value
        XCTAssertFalse(handoff.finish(submission, succeeded: true))
    }

    func testBackgroundSaveAcknowledgesOnlyAfterSourceCanBeReopened() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("vault.json")
        let storage = CaptureStorage(file: VaultFile(url: url))
        let capture = Capture(text: "# e\u{301} 👩🏽‍💻\n**final**")
        try await storage.save(capture)
        let reopened = try VaultFile(url: url).read()
        XCTAssertEqual(reopened.captures.map(\.text), ["# e\u{301} 👩🏽‍💻\n**final**"])
    }

    func testSlowSaveAcknowledgementKeepsFinalCharactersTypedAfterSubmission() throws {
        var handoff = CaptureHandoff()
        let submission = try XCTUnwrap(handoff.begin(source: "# thought", richText: nil))
        handoff.edited()
        // Closing/reopening leaves the same in-memory session alive. The saved
        // snapshot must not acquire, or erase, characters that arrived later.
        XCTAssertFalse(handoff.finish(submission, succeeded: true))
        XCTAssertEqual(submission.capture.text, "# thought")
    }

    func testPendingSaveCannotBeDuplicatedAndFailureAllowsRetryWithoutClearing() throws {
        var handoff = CaptureHandoff()
        XCTAssertNil(handoff.begin(source: " \n\t", richText: nil))
        let submission = try XCTUnwrap(handoff.begin(source: "- [ ] **task**", richText: nil))
        XCTAssertNil(handoff.begin(source: "- [ ] **task**", richText: nil))
        XCTAssertFalse(handoff.finish(submission, succeeded: false))
        let retry = try XCTUnwrap(handoff.begin(source: "- [ ] **task**", richText: nil))
        XCTAssertTrue(handoff.finish(retry, succeeded: true))
        XCTAssertFalse(handoff.finish(retry, succeeded: true), "A repeated completion cannot clear another draft")
    }

    func testSnapshotRetainsMarkdownUnicodeAndExistingAuthoredChecklistRules() throws {
        var handoff = CaptureHandoff()
        let source = "# e\u{301} 👩🏽‍💻\r\n- [ ] **task**\n- [x] [done](url)\n☐ Torch\n☑ Keys\n- ordinary"
        let submission = try XCTUnwrap(handoff.begin(source: source, richText: nil))
        XCTAssertEqual(Data(submission.capture.text.utf8), Data(source.utf8))
        XCTAssertEqual(submission.capture.checklist.map(\.text), ["**task**", "[done](url)", "Torch", "Keys"])
        XCTAssertEqual(submission.capture.checklist.map(\.complete), [false, true, false, true])
        // Editing away and back to the same string is still newer writing.
        handoff.edited()
        handoff.edited()
        XCTAssertFalse(handoff.finish(submission, succeeded: true))
    }
}
