/* Public keyboard-workspace behavior checks run by SwiftPM. Native keyboard
 controllers use this session for size, mode, destination and private draft state. */
import XCTest
import MindMachineCore

final class KeyboardWorkspaceTests: XCTestCase {
    // A completed send can clear its old field while another mode is active,
    // but must never erase newer writing added during the request.
    func testSendCompletionPreservesNewerDraftsAndActiveMode() {
        var workspace = KeyboardWorkspace()
        workspace.selectMode(.chat)
        workspace.edit(PrivateDraft(text: "First question"))
        workspace.selectMode(.recall)
        workspace.edit(PrivateDraft(text: "Shelf"))
        workspace.acknowledgeSentDraft("First question", in: .chat)
        XCTAssertEqual(workspace.mode, .recall)
        XCTAssertEqual(workspace.draft.text, "Shelf")
        workspace.selectMode(.chat)
        XCTAssertEqual(workspace.draft.text, "")
        workspace.edit(PrivateDraft(text: "New question"))
        workspace.acknowledgeSentDraft("First question", in: .chat)
        XCTAssertEqual(workspace.draft.text, "New question")
    }

    // Each mode resumes its own writing position without rerouting host input.
    func testModesRestoreIndependentDraftsAndSelections() {
        var workspace = KeyboardWorkspace()
        workspace.edit(PrivateDraft(text: "Note", selection: NSRange(location: 2, length: 0), richText: Data([7])))
        workspace.selectDestination(.app)
        workspace.selectMode(.recall)
        workspace.edit(PrivateDraft(text: "Shelf", selection: NSRange(location: 1, length: 3)))
        workspace.selectMode(.chat)
        workspace.edit(PrivateDraft(text: "Why?", selection: NSRange(location: 4, length: 0)))
        workspace.selectMode(.capture)
        XCTAssertEqual(workspace.draft.text, "Note")
        XCTAssertEqual(workspace.draft.selection, NSRange(location: 2, length: 0))
        XCTAssertEqual(workspace.draft.richText, Data([7]))
        XCTAssertEqual(workspace.destination, .app)
        workspace.selectMode(.recall)
        XCTAssertEqual(workspace.draft.text, "Shelf")
        XCTAssertEqual(workspace.draft.selection, NSRange(location: 1, length: 3))
        workspace.selectMode(.chat)
        XCTAssertEqual(workspace.draft.text, "Why?")
    }

    // Resizing is a layout choice and must preserve the complete writing context.
    func testResizingPreservesDraftSelectionAndDestination() {
        var workspace = KeyboardWorkspace()
        workspace.edit(PrivateDraft(text: "A shelf 🪵", selection: NSRange(location: 2, length: 5),
                                    richText: Data([4, 9]), scrollOffset: 36))
        workspace.selectDestination(.app)
        workspace.resize(.expanded)
        workspace.resize(.minimised)
        XCTAssertEqual(workspace.mode, .capture)
        XCTAssertEqual(workspace.destination, .app)
        XCTAssertEqual(workspace.draft.text, "A shelf 🪵")
        XCTAssertEqual(workspace.draft.selection, NSRange(location: 2, length: 5))
        XCTAssertEqual(workspace.draft.richText, Data([4, 9]))
        XCTAssertEqual(workspace.draft.scrollOffset, 36)
    }
}
