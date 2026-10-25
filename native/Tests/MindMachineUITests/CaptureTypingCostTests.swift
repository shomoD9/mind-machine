/* Typing-cost benchmark for the Mac Capture editor on one 100 KiB paragraph.
 SwiftPM on the hosted Mac (native-ci "swift test") runs it with the other
 MindMachineUITests. It compares the editor built by
 MacMarkdownEditor.makeScrollableEditor() with a stock NSTextView, adding one
 Capture setting at a time, and prints MM_EDITOR_BENCH lines. PillSelfTest types
 the same fixture under a 120-second process deadline; these lines attribute a
 slower key turn to a setting. Only correctness is asserted: hosted-runner
 timings are too noisy for a pass/fail budget here. The byte benchmark also
 compares native Swift strings with strings read from Capture's text storage,
 retaining the original comparison as a same-process control. */
#if os(macOS)
import XCTest
import AppKit
import QuartzCore
@testable import MindMachineUI

final class CaptureTypingCostTests: XCTestCase {
    @MainActor
    func testHugeParagraphKeyTurnAgainstStockTextView() {
        _ = NSApplication.shared
        let keys = 10
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        // Same fixture as PillSelfTest's "100KiB-one-paragraph" document.
        let source = String(String(repeating: "baseline text ", count: 102_400 / 14 + 1).prefix(102_400))
        let oldBase: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.labelColor,
                                                      .paragraphStyle: NSParagraphStyle.default]

        // Stock construction, as on main before this ticket.
        func stock() -> (NSScrollView, NSTextView) {
            let scroll = NSTextView.scrollableTextView()
            let editor = scroll.documentView as! NSTextView
            editor.isRichText = true
            scroll.drawsBackground = false
            editor.drawsBackground = false
            editor.importsGraphics = false
            editor.font = font
            return (scroll, editor)
        }
        func seed(_ editor: NSTextView, _ attributes: [NSAttributedString.Key: Any]) {
            editor.textStorage?.setAttributedString(NSAttributedString(string: source, attributes: attributes))
            editor.typingAttributes = attributes
        }

        // Each variant adds one Capture factor to the stock editor, so a slower
        // turn names the setting responsible.
        let variants: [(String, @MainActor () -> (NSScrollView, NSTextView, AnyObject?))] = [
            ("stock", {
                let (scroll, editor) = stock(); seed(editor, [.font: font])
                return (scroll, editor, nil)
            }),
            ("stock+undo", {
                let (scroll, editor) = stock(); editor.allowsUndo = true; seed(editor, [.font: font])
                return (scroll, editor, nil)
            }),
            ("stock+labelColor", {
                let (scroll, editor) = stock(); seed(editor, [.font: font, .foregroundColor: NSColor.labelColor])
                return (scroll, editor, nil)
            }),
            ("stock+labelColor+defaultParagraphStyle", {
                let (scroll, editor) = stock(); seed(editor, oldBase)
                return (scroll, editor, nil)
            }),
            ("stock+coordinator", {
                let (scroll, editor) = stock()
                let coordinator = MacMarkdownEditor()
                coordinator.attach(to: editor)
                coordinator.restore(source, in: editor)
                return (scroll, editor as NSTextView, coordinator as AnyObject)
            }),
            ("capture", {
                let (scroll, editor) = MacMarkdownEditor.makeScrollableEditor()
                let coordinator = MacMarkdownEditor()
                coordinator.attach(to: editor)
                coordinator.restore(source, in: editor)
                return (scroll, editor as NSTextView, coordinator as AnyObject)
            }),
            ("capture+bindingEcho", {
                let (scroll, editor) = MacMarkdownEditor.makeScrollableEditor()
                let coordinator = MacMarkdownEditor()
                coordinator.attach(to: editor)
                coordinator.restore(source, in: editor)
                // RichNoteEditor publishes editor.string to the binding, then
                // updateNSView compares the two byte for byte on every key.
                coordinator.changed = { [weak editor] in
                    guard let editor else { return }
                    let published = editor.string
                    if !editor.string.utf8.elementsEqual(published.utf8) { XCTFail("binding echo diverged") }
                }
                return (scroll, editor as NSTextView, coordinator as AnyObject)
            }),
            ("capture+contiguousBindingEcho", {
                let (scroll, editor) = MacMarkdownEditor.makeScrollableEditor()
                let coordinator = MacMarkdownEditor()
                coordinator.attach(to: editor)
                coordinator.restore(source, in: editor)
                // The production adapter comparison, including foreign-string
                // UTF-8 materialisation. Keep the original variant as control.
                coordinator.changed = { [weak editor, weak coordinator] in
                    guard let editor, let coordinator else { return }
                    let published = editor.string
                    coordinator.restoreIfNeeded(published, in: editor)
                }
                return (scroll, editor as NSTextView, coordinator as AnyObject)
            }),
            ("capture+defaultParagraphStyle", {
                // The previous base attributes, seeded before the delegate attaches.
                let (scroll, editor) = MacMarkdownEditor.makeScrollableEditor()
                seed(editor, oldBase)
                let coordinator = MacMarkdownEditor()
                coordinator.attach(to: editor)
                return (scroll, editor as NSTextView, coordinator as AnyObject)
            })
        ]

        func median(_ samples: [Double]) -> Double { samples.sorted()[samples.count / 2] }
        func format(_ value: Double) -> String { String(format: "%.2f", value) }

        // Two passes, so first-use font and layer setup cannot favour a variant.
        for pass in 1...2 {
            for (name, build) in variants {
                let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 540, height: 420),
                                      styleMask: [.titled], backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false
                let (scroll, editor, retained) = build()
                window.contentView = scroll
                window.orderFrontRegardless()
                window.makeFirstResponder(editor)
                editor.setSelectedRange(NSRange(location: (editor.string as NSString).length, length: 0))
                editor.scrollRangeToVisible(editor.selectedRange())
                window.displayIfNeeded()
                CATransaction.flush()
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))

                // A turn mirrors one PillSelfTest key: insertion, drawing, the
                // Core Animation commit and one short run-loop turn.
                var inserts: [Double] = [], turns: [Double] = []
                for _ in 0..<keys {
                    let start = ProcessInfo.processInfo.systemUptime
                    editor.insertText("x", replacementRange: editor.selectedRange())
                    inserts.append((ProcessInfo.processInfo.systemUptime - start) * 1_000)
                    window.displayIfNeeded()
                    CATransaction.flush()
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.001))
                    turns.append((ProcessInfo.processInfo.systemUptime - start) * 1_000)
                }
                XCTAssertEqual(editor.string.utf8.count, source.utf8.count + keys, name)
                XCTAssertNotNil(editor.textLayoutManager, name)
                print("MM_EDITOR_BENCH pass=\(pass) variant=\(name) keys=\(keys) insertP50Ms=\(format(median(inserts))) turnP50Ms=\(format(median(turns))) turnMaxMs=\(format(turns.max() ?? 0)) height=\(format(editor.frame.height))")
                withExtendedLifetime(retained) {}
                window.orderOut(nil)
                window.contentView = nil
            }
        }
    }
    @MainActor
    func testByteExactComparisonCandidate() {
        _ = NSApplication.shared
        for (left, right) in [("", ""), ("a", "a"), ("a", "b"), ("", "a"),
                              ("é", "e\u{301}"), ("éa", "e\u{301}"),
                              ("👩🏽‍💻", "👩🏽‍💻"), ("x\r\n", "x\n")] {
            XCTAssertEqual(MacMarkdownEditor.sourceBytesEqual(left, right), left.utf8.elementsEqual(right.utf8))
        }
        for bytes in [1_024, 10_240, 102_400] {
            let source = String(repeating: "x", count: bytes)
            let (_, editor) = MacMarkdownEditor.makeScrollableEditor()
            editor.textStorage?.setAttributedString(NSAttributedString(string: source))
            // Keep the native-string probe, then include the actual storage read
            // used by updateNSView. A native-only speedup cannot establish that
            // bridging and UTF-8 materialisation improve the adapter's path.
            for (representation, read) in [("native", { source }), ("textStorage", { editor.string })] {
                let echo = String(decoding: Array(read().utf8), as: UTF8.self)
                for (name, compare) in [("generic", { read().utf8.elementsEqual(echo.utf8) }),
                                         ("contiguous", { MacMarkdownEditor.sourceBytesEqual(read(), echo) })] {
                    var samples: [Double] = []
                    for _ in 0..<100 {
                        let start = ProcessInfo.processInfo.systemUptime
                        let equal = compare()
                        samples.append((ProcessInfo.processInfo.systemUptime - start) * 1_000)
                        XCTAssertTrue(equal)
                    }
                    print("MM_BYTES_BENCH bytes=\(bytes) representation=\(representation) comparison=\(name) p50Ms=\(samples.sorted()[50]) p95Ms=\(samples.sorted()[94])")
                }
            }
        }
    }

}
#endif
