/* Portable editing-command acceptance tests, run by SwiftPM on Linux and Mac.
 MacMarkdownEditorTests separately exercises the same plans through AppKit undo. */
import XCTest
import MindMachineCore

final class MarkdownEditingCommandsTests: XCTestCase {
    // Apply the public edit plan exactly as the text-view adapter does; expected
    // source and carets below are literal examples from the editing contract.
    private func check(_ source: String, _ command: MarkdownEditingCommands.Command,
                       selection: NSRange? = nil, expected: String, caret: NSRange,
                       file: StaticString = #filePath, line: UInt = #line) throws {
        let plan = try XCTUnwrap(MarkdownEditingCommands.plan(line: source,
            selection: selection ?? NSRange(location: (source as NSString).length, length: 0),
            command: command), file: file, line: line)
        let result = NSMutableString(string: source)
        for edit in plan.edits.reversed() { result.replaceCharacters(in: edit.range, with: edit.replacement) }
        XCTAssertEqual(Data((result as String).utf8), Data(expected.utf8), file: file, line: line)
        XCTAssertEqual(plan.selection, caret, file: file, line: line)
        XCTAssertFalse((result as String).contains("\r"), file: file, line: line)
    }

    func testEnterContinuesBulletAtSameNestedIndent() throws {
        try check("- item", .newline, expected: "- item\n- ", caret: NSRange(location: 9, length: 0))
        try check("    * item", .newline, expected: "    * item\n    * ", caret: NSRange(location: 17, length: 0))
    }
    func testEnterContinuesTasksUnchecked() throws {
        for marker in ["- [ ] ", "- [x] "] {
            try check("  " + marker + "task", .newline,
                      expected: "  " + marker + "task\n  - [ ] ", caret: NSRange(location: 21, length: 0))
        }
    }

    func testEnterExitsEmptyItemsKeepingIndent() throws {
        for marker in ["- ", "* ", "- [ ] ", "- [x] ", "9. "] {
            try check("  " + marker, .newline, expected: "  ", caret: NSRange(location: 2, length: 0))
        }
        try check("-    ", .newline, expected: "", caret: NSRange(location: 0, length: 0))
    }

    func testEnterIncrementsNumberedListsAndKeepsNestedIndent() throws {
        try check("1. one", .newline, expected: "1. one\n2. ", caret: NSRange(location: 10, length: 0))
        try check("  9. nine", .newline, expected: "  9. nine\n  10. ", caret: NSRange(location: 16, length: 0))
    }

    func testEnterSplitsBodyAndReplacesSelection() throws {
        try check("- first last", .newline, selection: NSRange(location: 7, length: 1),
                  expected: "- first\n- last", caret: NSRange(location: 10, length: 0))
        try check("- word", .newline, selection: NSRange(location: 2, length: 0),
                  expected: "- \n- word", caret: NSRange(location: 5, length: 0))
    }

    func testTabAndBacktabMoveOnlyIndentAndPreserveSelection() throws {
        try check("- item", .indent, expected: "  - item", caret: NSRange(location: 8, length: 0))
        try check("    - [x] item", .outdent, selection: NSRange(location: 10, length: 4),
                  expected: "  - [x] item", caret: NSRange(location: 8, length: 4))
        try check(" - item", .outdent, selection: NSRange(location: 0, length: 3),
                  expected: "- item", caret: NSRange(location: 0, length: 2))
        try check("1. one", .indent, expected: "  1. one", caret: NSRange(location: 8, length: 0))
        try check("  * item", .outdent, expected: "* item", caret: NSRange(location: 6, length: 0))
        let plan = try XCTUnwrap(MarkdownEditingCommands.plan(line: "- item",
            selection: NSRange(location: 3, length: 0), command: .outdent))
        XCTAssertTrue(plan.edits.isEmpty, "Root outdent is consumed without inserting a tab")
    }

    func testToggleChangesOneMarkerCharacterAndKeepsSelection() throws {
        let source = "  - [ ] keep [x] and [ ]"
        let plan = try XCTUnwrap(MarkdownEditingCommands.plan(line: source,
            selection: NSRange(location: 10, length: 4), command: .toggleTask))
        XCTAssertEqual(plan.edits.count, 1)
        XCTAssertEqual(plan.edits[0].range, NSRange(location: 5, length: 1))
        XCTAssertEqual(plan.edits[0].replacement, "x")
        try check(source, .toggleTask, selection: NSRange(location: 10, length: 4),
                  expected: "  - [x] keep [x] and [ ]", caret: NSRange(location: 10, length: 4))
        try check("- [x] done", .toggleTask, expected: "- [ ] done", caret: NSRange(location: 10, length: 0))
    }

    func testUnicodeBytesAndUTF16CaretsSurviveEveryCommand() throws {
        let source = "- [x] 👩🏽‍💻 e\u{301} 星"
        let length = (source as NSString).length
        try check(source, .newline, expected: source + "\n- [ ] ", caret: NSRange(location: length + 7, length: 0))
        try check(source, .indent, expected: "  " + source, caret: NSRange(location: length + 2, length: 0))
        try check("  " + source, .outdent, expected: source, caret: NSRange(location: length, length: 0))
        try check(source, .toggleTask, expected: "- [ ] 👩🏽‍💻 e\u{301} 星", caret: NSRange(location: length, length: 0))
        try check("- 👩🏽‍💻e\u{301}", .newline, selection: NSRange(location: 9, length: 0),
                  expected: "- 👩🏽‍💻\n- e\u{301}", caret: NSRange(location: 12, length: 0))
    }

    func testPlainCodeMalformedAndMultilineInputsUseNativeFallback() {
        for source in ["plain", "# heading", "> quote", "\t- code", "```", "-word", "1.word", "- item\nnext", "- item\r"] {
            for command: MarkdownEditingCommands.Command in [.newline, .indent, .outdent, .toggleTask] {
                XCTAssertNil(MarkdownEditingCommands.plan(line: source,
                    selection: NSRange(location: (source as NSString).length, length: 0), command: command), source)
            }
        }
        XCTAssertNil(MarkdownEditingCommands.plan(line: "- item", selection: NSRange(location: 1, length: 0), command: .newline))
        XCTAssertNil(MarkdownEditingCommands.plan(line: "- item", selection: NSRange(location: 99, length: 0), command: .indent))
        XCTAssertNil(MarkdownEditingCommands.plan(line: "- item", selection: NSRange(location: 0, length: Int.max), command: .indent))
        XCTAssertNil(MarkdownEditingCommands.plan(line: "- 👩", selection: NSRange(location: 3, length: 0), command: .newline))
        XCTAssertNil(MarkdownEditingCommands.plan(line: "- item", selection: NSRange(location: 6, length: 0), command: .toggleTask))
    }

}
