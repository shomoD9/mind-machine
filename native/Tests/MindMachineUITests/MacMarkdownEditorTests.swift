/* Real TextKit 2/source round-trip checks for RichNoteEditor's Mac coordinator.
 SwiftPM on the hosted Mac runs this against AppKit and the actual vault model. */
#if os(macOS)
import XCTest
import AppKit
import MindMachineCore
import MindMachineUI

final class MacMarkdownEditorTests: XCTestCase {
    @MainActor
    private func makeEditor() -> (MarkdownCaptureTextView, MacMarkdownEditor) {
        _ = NSApplication.shared
        let editor = MarkdownCaptureTextView(usingTextLayoutManager: true)
        editor.font = .systemFont(ofSize: 13)
        let coordinator = MacMarkdownEditor()
        coordinator.attach(to: editor)
        return (editor, coordinator)
    }

    @MainActor
    func testTypingStylesPrefixesAndInlineTraitsWithoutChangingSource() throws {
        let (editor, coordinator) = makeEditor()
        for (prefix, heading) in [("# ", true), ("## ", true), ("### ", true), ("- ", false), ("- [ ] ", false), ("- [x] ", false)] {
            coordinator.restore("", in: editor)
            for character in prefix { editor.insertText(String(character), replacementRange: editor.selectedRange()) }
            editor.insertText("**bold** *italic* [link](url)", replacementRange: editor.selectedRange())
            let source = prefix + "**bold** *italic* [link](url)"
            XCTAssertEqual(Data(editor.string.utf8), Data(source.utf8))
            let storage = try XCTUnwrap(editor.textStorage)
            let string = source as NSString
            let bold = string.range(of: "bold").location
            let italic = string.range(of: "italic").location
            let link = string.range(of: "link").location
            let boldFont = try XCTUnwrap(storage.attribute(.font, at: bold, effectiveRange: nil) as? NSFont)
            let italicFont = try XCTUnwrap(storage.attribute(.font, at: italic, effectiveRange: nil) as? NSFont)
            XCTAssertTrue(NSFontManager.shared.traits(of: boldFont).contains(.boldFontMask))
            XCTAssertTrue(NSFontManager.shared.traits(of: italicFont).contains(.italicFontMask))
            XCTAssertEqual(storage.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor, .secondaryLabelColor)
            XCTAssertEqual(storage.attribute(.underlineStyle, at: link, effectiveRange: nil) as? Int, NSUnderlineStyle.single.rawValue)
            XCTAssertEqual(boldFont.pointSize > 13, heading)
            XCTAssertNotNil(editor.textLayoutManager)
        }
        // Prefix deletion must remove stale heading/list presentation.
        coordinator.restore("# heading", in: editor)
        editor.insertText("", replacementRange: NSRange(location: 0, length: 2))
        XCTAssertEqual((editor.textStorage?.attribute(.font, at: 0, effectiveRange: nil) as? NSFont)?.pointSize, 13)
    }

    @MainActor
    func testOnlyEditedParagraphChangesAndNewlineDoesNotInheritHeading() throws {
        let (editor, coordinator) = makeEditor()
        coordinator.restore("# first\nplain\n- last", in: editor)
        let storage = try XCTUnwrap(editor.textStorage)
        storage.addAttribute(.backgroundColor, value: NSColor.red, range: NSRange(location: 0, length: 7))
        editor.setSelectedRange(NSRange(location: 13, length: 0))
        editor.insertText("!", replacementRange: editor.selectedRange())
        XCTAssertEqual(coordinator.lastRestyledRange, NSRange(location: 8, length: 7))
        XCTAssertEqual(storage.attribute(.backgroundColor, at: 0, effectiveRange: nil) as? NSColor, .red)
        XCTAssertEqual(editor.selectedRange(), NSRange(location: 14, length: 0))
        coordinator.restore("# title", in: editor)
        editor.setSelectedRange(NSRange(location: 7, length: 0))
        editor.insertText("\nplain", replacementRange: editor.selectedRange())
        XCTAssertEqual((storage.attribute(.font, at: 8, effectiveRange: nil) as? NSFont)?.pointSize, 13)
        // Deleting a newline restyles the joined paragraph, never the last one.
        coordinator.restore("# a\nb\nlast", in: editor)
        editor.insertText("", replacementRange: NSRange(location: 3, length: 1))
        XCTAssertEqual(coordinator.lastRestyledRange, NSRange(location: 0, length: 5))
        XCTAssertNotNil(editor.textLayoutManager)
    }

    @MainActor
    func testHugePlainParagraphDoesNotRestyleUnchangedTextOnEachKey() throws {
        let (editor, coordinator) = makeEditor()
        let source = String(repeating: "baseline text ", count: 7_877)
        coordinator.restore(source, in: editor)
        let storage = try XCTUnwrap(editor.textStorage)
        editor.setSelectedRange(NSRange(location: storage.length, length: 0))
        // Observe real attribute-only transactions. Character insertion may
        // legitimately fix native attributes; a style pass must not invalidate
        // the unchanged 100 KiB paragraph after that character transaction.
        var attributeRanges: [NSRange] = []
        let observer = NotificationCenter.default.addObserver(
            forName: NSTextStorage.didProcessEditingNotification, object: storage, queue: nil
        ) { _ in
            if storage.editedMask.contains(.editedAttributes), !storage.editedMask.contains(.editedCharacters) {
                attributeRanges.append(storage.editedRange)
            }
        }
        defer { NotificationCenter.default.removeObserver(observer) }
        for _ in 0..<3 {
            editor.insertText("x", replacementRange: editor.selectedRange())
            print("[style-regression] work=\(coordinator.lastRestyledRange) ms=\(coordinator.lastStyleMilliseconds) attributeEdits=\(attributeRanges)")
            XCTAssertLessThanOrEqual(coordinator.lastRestyledRange.length, MarkdownParagraph.maximumUTF16Length)
        }
        XCTAssertTrue(attributeRanges.isEmpty, "Plain typing must not trigger another attribute transaction: \(attributeRanges)")
        XCTAssertEqual(Data(editor.string.utf8), Data((source + "xxx").utf8))
        XCTAssertNotNil(editor.textLayoutManager)
    }

    @MainActor
    func testBoundedParagraphStillStylesAfterHugeSource() throws {
        let (editor, coordinator) = makeEditor()
        let source = String(repeating: "plain ", count: 20_000) + "\n# tail"
        coordinator.restore(source, in: editor)
        let storage = try XCTUnwrap(editor.textStorage)
        // A bulk restoration is plain; the first local edit must discover just
        // the tail paragraph without traversing the huge preceding paragraph.
        storage.addAttribute(.backgroundColor, value: NSColor.red, range: NSRange(location: 0, length: 1))
        editor.setSelectedRange(NSRange(location: storage.length, length: 0))
        editor.insertText("!", replacementRange: editor.selectedRange())
        XCTAssertEqual(coordinator.lastRestyledRange, NSRange(location: 120_001, length: 7))
        XCTAssertEqual((storage.attribute(.font, at: 120_003, effectiveRange: nil) as? NSFont)?.pointSize, 19)
        XCTAssertEqual(storage.attribute(.backgroundColor, at: 0, effectiveRange: nil) as? NSColor, .red)
        XCTAssertEqual(Data(editor.string.utf8), Data((source + "!").utf8))
        XCTAssertNotNil(editor.textLayoutManager)
    }

    @MainActor
    func testCopySaveReopenPreservesExactUnicodeBytes() throws {
        let (editor, coordinator) = makeEditor()
        let source = "# e\u{301} 👩🏽‍💻\r\n- [ ] **task**\n- [x] *done* [🔭](https://example.org)\n"
        coordinator.restore(source, in: editor)
        editor.setSelectedRange(NSRange(location: 0, length: (source as NSString).length))
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        // Use the formats AppKit advertises for native copy; the multi-type
        // entry declares them before writing. Read back plain source below.
        XCTAssertTrue(editor.writeSelection(to: pasteboard, types: editor.writablePasteboardTypes))
        XCTAssertEqual(Data(try XCTUnwrap(pasteboard.string(forType: .string)).utf8), Data(source.utf8))

        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("vault.json")
        let model = VaultModel(url: url, notificationAccess: .disabled)
        model.draft = editor.string
        model.saveCapture()
        let reopened = VaultModel(url: url, notificationAccess: .disabled)
        let saved = try XCTUnwrap(reopened.vault.captures.first)
        XCTAssertEqual(Data(saved.text.utf8), Data(source.utf8))
        XCTAssertNil(saved.richText)
        let (restored, restyler) = makeEditor()
        restyler.restore(saved.text, in: restored)
        XCTAssertEqual(Data(restored.string.utf8), Data(source.utf8))
        XCTAssertNotNil(restored.textLayoutManager)
    }

    @MainActor
    func testRestylingPreservesNativeUndoAndDefersMarkedText() throws {
        let (editor, coordinator) = makeEditor()
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = editor
        window.makeFirstResponder(editor)
        coordinator.restore("# e\u{301} 👩🏽‍💻", in: editor)
        let source = editor.string
        editor.setSelectedRange(NSRange(location: (source as NSString).length, length: 0))
        editor.insertText("!", replacementRange: editor.selectedRange())
        let undo = try XCTUnwrap(editor.undoManager)
        XCTAssertTrue(undo.canUndo)
        undo.undo()
        XCTAssertEqual(Data(editor.string.utf8), Data(source.utf8))
        undo.redo()
        XCTAssertEqual(Data(editor.string.utf8), Data((source + "!").utf8))
        let previous = coordinator.lastRestyledRange
        editor.setMarkedText("に", selectedRange: NSRange(location: 1, length: 0), replacementRange: editor.selectedRange())
        XCTAssertTrue(editor.hasMarkedText())
        coordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: editor))
        XCTAssertEqual(coordinator.lastRestyledRange, previous)
        editor.insertText("日本", replacementRange: editor.markedRange())
        XCTAssertFalse(editor.hasMarkedText())
        XCTAssertTrue(editor.string.hasSuffix("!日本"))
        XCTAssertNotNil(editor.textLayoutManager)
    }
}
#endif
