/* Behavior checks for the public native workspace presentation interface.
 SwiftPM runs these; native entry adapters call the same activation operation. */
import XCTest
import SecondBrainUI
import SecondBrainCore

final class WorkspaceTests: XCTestCase {
    // Reactivation must open Capture without destroying another mode's writing.
    @MainActor
    func testActivationReturnsToCaptureAndKeepsDrafts() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = VaultModel(url: directory.appendingPathComponent("vault.json"))
        model.draft = "A thought in progress"
        model.query = "old shelf"
        model.chatDraft = "Where did I leave it?"
        model.mode = 2
        model.selectedCapture = UUID()
        model.activateCapture()
        XCTAssertEqual(model.mode, 0)
        XCTAssertNil(model.selectedCapture)
        XCTAssertEqual(model.draft, "A thought in progress")
        XCTAssertEqual(model.query, "old shelf")
        XCTAssertEqual(model.chatDraft, "Where did I leave it?")
    }
}
