/* Ticket 6's rejected preview experiment lives only in the SwiftPM Mac tests.
 Existing core-checks/native-ci run this against the production editor factory
 and coordinator. No app target calls the collapsing-marker candidate below.
 It measures a small equivalent of caret-sensitive marker hiding against muted
 markers, retaining source and using TextKit 2 geometry without layoutManager.
 See docs/verification/markdown-preview-comparison.md for the acceptance decision. */
#if os(macOS)
import XCTest
import AppKit
import QuartzCore
import MindMachineCore
import MindMachineUI

@MainActor
final class MarkdownPreviewComparisonTests: XCTestCase {
    // This deliberately small candidate shrinks markers off the caret paragraph.
    // Saving the original font makes reveal reversible without rewriting source.
    // It has no click-sequence deferral or custom accessibility representation.
    @MainActor
    private final class CollapsingMarkers: NSObject, NSTextViewDelegate {
        let editor: NSTextView
        let coordinator: MacMarkdownEditor
        var previousCaret = 0
        var painting = false
        var paintMilliseconds = 0.0
        let originalFont = NSAttributedString.Key("MMPreviewComparisonOriginalFont")

        init(_ editor: NSTextView, _ coordinator: MacMarkdownEditor) {
            self.editor = editor
            self.coordinator = coordinator
            super.init()
            editor.delegate = self
        }

        func textDidChange(_ notification: Notification) {
            coordinator.textDidChange(notification)
            repaint()
        }

        func textViewDidChangeSelection(_ notification: Notification) { repaint() }

        func repaint() {
            guard !painting, !editor.hasMarkedText(), let storage = editor.textStorage else { return }
            let start = ProcessInfo.processInfo.systemUptime
            painting = true
            let undo = editor.undoManager
            undo?.disableUndoRegistration()
            defer {
                undo?.enableUndoRegistration()
                painting = false
                paintMilliseconds += (ProcessInfo.processInfo.systemUptime - start) * 1_000
            }
            let caret = min(editor.selectedRange().location, storage.length)
            let source = storage.mutableString
            // Repaint only the old/new caret paragraphs under the production cap.
            // Huge paragraphs retain source presentation, just as the baseline does.
            var visited: Set<Int> = []
            for offset in [min(previousCaret, storage.length), caret] {
                guard let range = MarkdownStyleRange.affected(by: NSRange(location: offset, length: 0),
                    length: storage.length, characterAt: { source.character(at: $0) }),
                    range.length > 0, visited.insert(range.location).inserted else { continue }
                let paragraph = source.substring(with: range)
                let spans = MarkdownParagraph(paragraph).spans.filter { $0.style == .marker }
                let open = caret >= range.location && (caret < NSMaxRange(range)
                    || caret == storage.length && NSMaxRange(range) == storage.length)
                for span in spans {
                    let marker = NSRange(location: range.location + span.range.location, length: span.range.length)
                    let font = storage.attribute(originalFont, at: marker.location, effectiveRange: nil)
                        ?? storage.attribute(.font, at: marker.location, effectiveRange: nil)
                        ?? NSFont.systemFont(ofSize: 15)
                    storage.addAttributes([originalFont: font,
                        .font: open ? font : NSFont.systemFont(ofSize: 0.1),
                        .foregroundColor: open ? NSColor.secondaryLabelColor : NSColor.clear], range: marker)
                }
            }
            previousCaret = caret
        }
    }

    private func make(_ source: String, hiding: Bool) -> (NSWindow, MarkdownCaptureTextView, MacMarkdownEditor, CollapsingMarkers?) {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 360, height: 240),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let (scroll, editor) = MacMarkdownEditor.makeScrollableEditor()
        window.contentView = scroll
        let coordinator = MacMarkdownEditor()
        coordinator.attach(to: editor)
        coordinator.restore(source, in: editor)
        // Include the real binding-echo comparison, without introducing a model
        // or storage benchmark into this isolated presentation comparison.
        coordinator.changed = { [weak editor, weak coordinator] in
            guard let editor, let coordinator else { return }
            coordinator.restoreIfNeeded(editor.string, in: editor)
        }
        window.orderFrontRegardless()
        window.makeFirstResponder(editor)
        window.contentView?.layoutSubtreeIfNeeded()
        let candidate = hiding ? CollapsingMarkers(editor, coordinator) : nil
        return (window, editor, coordinator, candidate)
    }

    private func segment(_ offset: Int, in editor: NSTextView) throws -> NSRect {
        let manager = try XCTUnwrap(editor.textLayoutManager)
        manager.ensureLayout(for: manager.documentRange)
        let content = try XCTUnwrap(manager.textContentManager)
        let start = try XCTUnwrap(content.location(content.documentRange.location, offsetBy: offset))
        let end = try XCTUnwrap(content.location(start, offsetBy: 1))
        let range = try XCTUnwrap(NSTextRange(location: start, end: end))
        var rect = NSRect.null
        manager.enumerateTextSegments(in: range, type: .standard, options: []) { _, frame, _, _ in
            rect = frame
            return false
        }
        XCTAssertFalse(rect.isNull)
        return rect.offsetBy(dx: editor.textContainerOrigin.x, dy: editor.textContainerOrigin.y)
    }

    func testRevealChangesWrappingSoTheSimpleCandidateIsRejected() throws {
        let source = "outside\nSee [label](https://example.org/" + String(repeating: "destination/", count: 16) + ") tail\nlast"
        let (window, editor, coordinator, candidate) = make(source, hiding: true)
        defer { window.orderOut(nil); window.contentView = nil; withExtendedLifetime((coordinator, candidate)) {} }
        let tail = (source as NSString).range(of: "tail").location
        let label = (source as NSString).range(of: "label").location
        let muted = try segment(tail, in: editor)
        // Visit the link paragraph, then leave it to collapse its markers/address.
        editor.setSelectedRange(NSRange(location: label, length: 0))
        editor.setSelectedRange(NSRange(location: 0, length: 0))
        let hidden = try segment(tail, in: editor)
        XCTAssertEqual(editor.textStorage?.attribute(.foregroundColor, at: label - 1, effectiveRange: nil) as? NSColor, .clear)
        XCTAssertGreaterThan(muted.minY - hidden.minY, 10, "A long hidden destination changes line wrapping")
        editor.setSelectedRange(NSRange(location: label, length: 0))
        let revealed = try segment(tail, in: editor)
        XCTAssertEqual(revealed.minY, muted.minY, accuracy: 1)
        XCTAssertEqual(editor.selectedRange(), NSRange(location: label, length: 0))
        XCTAssertEqual(Data(editor.string.utf8), Data(source.utf8))
        print("MM_PREVIEW_REJECTION gate=wrapping mutedTailY=\(muted.minY) hiddenTailY=\(hidden.minY) revealedTailY=\(revealed.minY) decision=retain-muted")
    }

    func testCandidateRetainsSourceSelectionUndoAndComposition() throws {
        let source = "# e\u{301} 👩🏽‍💻\n**bold** [label](destination)\nlast"
        let (window, editor, coordinator, candidate) = make(source, hiding: true)
        defer { window.orderOut(nil); window.contentView = nil; withExtendedLifetime((coordinator, candidate)) {} }
        editor.setSelectedRange(NSRange(location: 0, length: 0))
        editor.setSelectedRange(NSRange(location: (source as NSString).length, length: 0))
        let undo = try XCTUnwrap(editor.undoManager)
        undo.removeAllActions()
        undo.groupsByEvent = false
        editor.insertText("!", replacementRange: editor.selectedRange())
        XCTAssertEqual(Data(editor.string.utf8), Data((source + "!").utf8))
        undo.undo()
        XCTAssertEqual(Data(editor.string.utf8), Data(source.utf8))
        XCTAssertFalse(undo.canUndo, "Presentation must not add undo steps")
        undo.redo()
        XCTAssertEqual(Data(editor.string.utf8), Data((source + "!").utf8))
        editor.setSelectedRange(NSRange(location: 0, length: (editor.string as NSString).length))
        let selection = editor.selectedRange()
        candidate?.repaint()
        XCTAssertEqual(editor.selectedRange(), selection)
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        XCTAssertTrue(editor.writeSelection(to: pasteboard, types: editor.writablePasteboardTypes))
        XCTAssertEqual(Data(try XCTUnwrap(pasteboard.string(forType: .string)).utf8), Data((source + "!").utf8))
        editor.setSelectedRange(NSRange(location: (editor.string as NSString).length, length: 0))
        editor.setMarkedText("に", selectedRange: NSRange(location: 1, length: 0), replacementRange: editor.selectedRange())
        XCTAssertTrue(editor.hasMarkedText())
        let before = candidate?.paintMilliseconds
        candidate?.repaint()
        XCTAssertEqual(candidate?.paintMilliseconds, before)
        editor.insertText("日本", replacementRange: editor.markedRange())
        XCTAssertFalse(editor.hasMarkedText())
        XCTAssertEqual(Data(editor.string.utf8), Data((source + "!日本").utf8))
        XCTAssertNotNil(editor.textLayoutManager)
    }

    // Raw ordered samples are retained in hosted test logs. Nearest-rank tails
    // describe this diagnostic sample; missing hardware gates cannot pass from it.
    private func report(_ samples: [Double], pass: Int, variant: String, fixture: String, metric: String) throws {
        let sorted = samples.sorted()
        func percentile(_ p: Double) -> Double { sorted[max(0, Int(ceil(Double(sorted.count) * p)) - 1)] }
        let row: [String: Any] = ["pass": pass, "variant": variant, "fixture": fixture, "metric": metric,
            "count": samples.count, "p50Ms": percentile(0.5), "p95Ms": percentile(0.95),
            "p99Ms": percentile(0.99), "maxMs": sorted.last!, "over100Ms": samples.filter { $0 > 100 }.count,
            "samplesMs": samples, "profile": "shared-Mac-Debug-100-keys-diagnostic"]
        print("MM_PREVIEW " + String(decoding: try JSONSerialization.data(withJSONObject: row, options: [.sortedKeys]), as: UTF8.self))
    }

    func testPairedTypingAndPasteDiagnostics() throws {
        let line = "a **bold** word [link](https://example.org)\n"
        func fixture(_ size: Int) -> String {
            String(String(repeating: line, count: size / line.utf8.count + 1).prefix(size - 12)) + "\n**tail**   "
        }
        let fixtures = [("1KiB", fixture(1_024)), ("10KiB", fixture(10_240)),
            ("100KiB", fixture(102_400)), ("100KiB-one-paragraph", String(repeating: "x", count: 102_400))]
        // Reverse order for the second pass to expose first-use/order effects.
        // The full 1,000-key Release/hardware protocol is unnecessary after the
        // wrapping rejection, and is explicitly left unproven by this experiment.
        for pass in 1...2 {
            for hiding in pass == 1 ? [false, true] : [true, false] {
                let variant = hiding ? "collapsed" : "muted"
                for (name, source) in fixtures {
                    XCTAssertEqual(source.utf8.count, name == "1KiB" ? 1_024 : name == "10KiB" ? 10_240 : 102_400)
                    let (window, editor, coordinator, candidate) = make(source, hiding: hiding)
                    defer { window.orderOut(nil); window.contentView = nil; withExtendedLifetime((coordinator, candidate)) {} }
                    editor.setSelectedRange(NSRange(location: (source as NSString).length, length: 0))
                    editor.scrollRangeToVisible(editor.selectedRange())
                    window.displayIfNeeded()
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
                    var dispatch: [Double] = [], draw: [Double] = [], presentation: [Double] = []
                    for _ in 0..<100 {
                        let key = try XCTUnwrap(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [],
                            timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                            context: nil, characters: "x", charactersIgnoringModifiers: "x", isARepeat: false, keyCode: 7))
                        candidate?.paintMilliseconds = 0
                        let start = ProcessInfo.processInfo.systemUptime
                        window.sendEvent(key)
                        dispatch.append((ProcessInfo.processInfo.systemUptime - start) * 1_000)
                        presentation.append(coordinator.lastStyleMilliseconds + (candidate?.paintMilliseconds ?? 0))
                        window.displayIfNeeded()
                        CATransaction.flush()
                        draw.append((ProcessInfo.processInfo.systemUptime - start) * 1_000)
                        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.001))
                    }
                    XCTAssertEqual(Data(editor.string.utf8), Data((source + String(repeating: "x", count: 100)).utf8))
                    XCTAssertNotNil(editor.textLayoutManager)
                    try report(dispatch, pass: pass, variant: variant, fixture: name, metric: "dispatch")
                    try report(draw, pass: pass, variant: variant, fixture: name, metric: "dispatch-to-draw-proxy")
                    try report(presentation, pass: pass, variant: variant, fixture: name, metric: "presentation-only")
                }
                let (window, editor, coordinator, candidate) = make("", hiding: hiding)
                defer { window.orderOut(nil); window.contentView = nil; withExtendedLifetime((coordinator, candidate)) {} }
                let paste = String(repeating: "x", count: 1_048_576)
                let start = ProcessInfo.processInfo.systemUptime
                editor.insertText(paste, replacementRange: editor.selectedRange())
                window.displayIfNeeded()
                try report([(ProcessInfo.processInfo.systemUptime - start) * 1_000], pass: pass,
                           variant: variant, fixture: "1MiB-paste", metric: "insert-to-draw-proxy")
                XCTAssertEqual(Data(editor.string.utf8), Data(paste.utf8))
                XCTAssertNotNil(editor.textLayoutManager)
            }
        }
    }
}
#endif
