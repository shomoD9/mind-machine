/* Companion editor verification in the Simulator-only host. The existing
 MindMachineKeyboardUITests scheme launches --iphone-markdown-probe and reads
 this controller's report. It drives production UIKit/SwiftUI editors, native
 undo and marked input, a real vault reopen, and timed native input calls.
 Nothing here is compiled into the companion or keyboard extension. */
import UIKit
import SwiftUI
import MindMachineCore
import MindMachineUI

@MainActor
final class IPhoneMarkdownProbe: UIViewController {
    private let report = UILabel()
    private var failures: [String] = []
    private var checks = 0
    private var samples: [[String: Any]] = []
    private var hosting: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        report.accessibilityIdentifier = "iphone-markdown-report"
        report.numberOfLines = 0
        report.frame = CGRect(x: 16, y: 70, width: 370, height: 140)
        report.text = "RUNNING"
        view.addSubview(report)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task { await run() }
    }

    private func check(_ value: @autoclosure () -> Bool, _ message: String) {
        checks += 1
        if !value() { failures.append(message) }
    }
    private func bytes(_ actual: String, _ expected: String, _ message: String) {
        check(Data(actual.utf8) == Data(expected.utf8), message + ": " + actual.debugDescription)
    }
    private func settle() async { try? await Task.sleep(for: .milliseconds(10)) }

    private func mount(_ controller: UIViewController) async {
        hosting?.willMove(toParent: nil)
        hosting?.view.removeFromSuperview()
        hosting?.removeFromParent()
        addChild(controller)
        controller.view.frame = CGRect(x: 16, y: 220, width: view.bounds.width - 32, height: 260)
        view.addSubview(controller.view)
        controller.didMove(toParent: self)
        hosting = controller
        view.layoutIfNeeded()
        await settle()
    }

    private func run() async {
        let editor = IPhoneMarkdownEditor.makeEditor()
        let styler = IPhoneMarkdownEditor()
        styler.attach(to: editor)
        let controller = UIViewController()
        controller.view = editor
        await mount(controller)
        editor.inputView = UIView(frame: .zero)
        editor.becomeFirstResponder()
        check(editor.textLayoutManager != nil, "TextKit 2 initially active")
        var published = ""
        styler.changed = { published = editor.text ?? "" }

        // Exact source survives typing, disposable styles and source clipboard.
        let original = "# **e\u{301}** 👩🏽‍💻 *italic* [link](url)"
        styler.restore("", in: editor)
        for character in original { editor.insertText(String(character)) }
        bytes(editor.text, original, "typed source")
        bytes(published, original, "synchronous final-key publication")
        check((editor.textStorage.attribute(.font, at: 5, effectiveRange: nil) as? UIFont)?
            .fontDescriptor.symbolicTraits.contains(.traitBold) == true, "heading bold style")
        check(editor.textStorage.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor == .secondaryLabel,
              "visible muted marker")
        editor.selectedRange = NSRange(location: 0, length: editor.textStorage.length)
        editor.copy(nil)
        bytes(UIPasteboard.general.string ?? "", original, "source copy")
        check(UIPasteboard.general.types == ["public.utf8-plain-text"], "copy advertises plain source only")
        styler.restore("", in: editor)
        editor.paste(nil)
        bytes(editor.text, original, "source paste")
        styler.restore("é", in: editor)
        styler.restoreIfNeeded("e\u{301}", in: editor)
        bytes(editor.text, "e\u{301}", "canonical-equivalent binding replacement")

        // Attribute invalidation must agree with fresh parsing after splits/joins.
        styler.restore("**bold**\nlast", in: editor)
        editor.selectedRange = NSRange(location: 4, length: 0)
        editor.insertText("\n")
        check(styler.lastRestyledRange == NSRange(location: 0, length: 10), "split includes right paragraph")
        check((editor.textStorage.attribute(.font, at: 5, effectiveRange: nil) as? UIFont)?
            .fontDescriptor.symbolicTraits.contains(.traitBold) == false, "right fragment loses stale bold")
        editor.selectedRange = NSRange(location: 5, length: 0)
        editor.deleteBackward()
        bytes(editor.text, "**bold**\nlast", "join source")
        check((editor.textStorage.attribute(.font, at: 2, effectiveRange: nil) as? UIFont)?
            .fontDescriptor.symbolicTraits.contains(.traitBold) == true, "join restores bold")

        // Real UIKit composition: external restore, commands and styling defer.
        styler.restore("- [ ] ", in: editor)
        editor.selectedRange = NSRange(location: 6, length: 0)
        editor.setMarkedText("にほん", selectedRange: NSRange(location: 3, length: 0))
        check(editor.markedTextRange != nil, "native marked range exists")
        let composing = editor.text ?? ""
        let dirty = styler.lastRestyledRange
        styler.textViewDidChange(editor)
        styler.restoreIfNeeded("external", in: editor)
        bytes(editor.text, composing, "restore preserves composition")
        check(styler.lastRestyledRange == dirty, "restyle deferred while marked")
        check(!editor.applyMarkdownCommand(.newline), "command defers to marked input")
        editor.setMarkedText("日本", selectedRange: NSRange(location: 2, length: 0))
        editor.unmarkText()
        bytes(editor.text, "- [ ] 日本", "IME commit source")
        bytes(published, editor.text, "IME commit publication")
        check(editor.markedTextRange == nil, "composition ended")

        // Commands enter through native insertText and undo/redo, with a turn
        // between user actions so UIKit owns its normal event grouping.
        for (source, expected) in [("- item", "- item\n- "), ("- [x] done", "- [x] done\n- [ ] "),
                                   ("9. item", "9. item\n10. "), ("  - [ ] ", "  ")] {
            styler.restore(source, in: editor)
            editor.undoManager?.removeAllActions()
            editor.selectedRange = NSRange(location: editor.textStorage.length, length: 0)
            await settle()
            editor.insertText("\n")
            bytes(editor.text, expected, "continuation/exit")
            await settle()
            check(editor.undoManager?.canUndo == true, "command has native undo")
            editor.undoManager?.undo()
            bytes(editor.text, source, "one undo restores command")
            await settle()
            editor.undoManager?.redo()
            bytes(editor.text, expected, "native redo")
            bytes(published, expected, "redo publication")
        }
        styler.restore("- ", in: editor)
        editor.selectedRange = NSRange(location: 2, length: 0)
        for character in "item" { editor.insertText(String(character)) }
        await settle()
        editor.insertText("\n")
        await settle()
        editor.undoManager?.undo()
        bytes(editor.text, "- item", "command undo keeps preceding typing")
        styler.restore("- [ ] e\u{301} 👩🏽‍💻", in: editor)
        let task = editor.text ?? ""
        editor.selectedRange = NSRange(location: 6, length: 2)
        _ = editor.applyMarkdownCommand(.toggleTask)
        bytes(editor.text, task.replacingOccurrences(of: "[ ]", with: "[x]"), "toggle marker only")
        check(editor.selectedRange == NSRange(location: 6, length: 2), "toggle keeps selection")
        await settle()
        editor.undoManager?.undo()
        bytes(editor.text, task, "toggle undo")

        await bindingAndSave()
        await mount(controller)
        editor.becomeFirstResponder()
        await timing(editor, styler)
        check(editor.textLayoutManager != nil, "TextKit 2 remains active")
        let payload: [String: Any] = ["checks": checks, "failures": failures, "samples": samples,
                                     "platform": UIDevice.current.systemVersion,
                                     "build": "Debug Simulator", "boundary": "insertText return, not pixels"]
        let data = (try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])) ?? Data()
        let json = String(decoding: data, as: UTF8.self)
        print("MM_IPHONE_PROBE " + json)
        editor.resignFirstResponder()
        report.text = (failures.isEmpty ? "PASS " : "FAIL ") + json
    }

    // Drive the real SwiftUI representable, detach immediately after the final
    // key, recreate it, then save and reopen a real vault through the model.
    private func bindingAndSave() async {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("vault.json")
        let model = VaultModel(url: url, notificationAccess: .disabled)
        func host() -> UIHostingController<RichNoteEditor> {
            UIHostingController(rootView: RichNoteEditor(
                text: Binding(get: { model.draft }, set: { model.draft = $0 }),
                richText: Binding(get: { model.richDraft }, set: { model.richDraft = $0 })))
        }
        func find(_ view: UIView) -> IPhoneMarkdownTextView? {
            if let editor = view as? IPhoneMarkdownTextView { return editor }
            return view.subviews.lazy.compactMap { find($0) }.first
        }
        await mount(host())
        guard let editor = hosting.flatMap({ find($0.view) }) else { check(false, "hosted editor exists"); return }
        editor.inputView = UIView(frame: .zero)
        editor.becomeFirstResponder()
        let source = "# **e\u{301}** 👩🏽‍💻 final"
        for character in source { editor.insertText(String(character)) }
        hosting?.view.removeFromSuperview()
        bytes(model.draft, source, "real binding final key before detach")
        check(model.richDraft == nil, "companion publishes no RTF")
        await mount(host())
        if let reopened = hosting.flatMap({ find($0.view) }) {
            bytes(reopened.text, source, "representable recreation")
            check(reopened.textLayoutManager != nil, "hosted TextKit 2")
        } else { check(false, "recreated editor exists") }
        await model.submitCapture()?.value
        do {
            let vault = try VaultFile(url: url).read()
            bytes(vault.captures.first?.text ?? "", source, "durable source reopen")
            check(vault.captures.first?.richText == nil, "saved plain Markdown")
        } catch { check(false, "vault reopen: \(error)") }
    }

    // Report distributions with exact counts and fixed research budgets. Input
    // call duration includes native editing; style is only custom presentation.
    // Layout/draw and physical visible latency require Instruments/video.
    private func timing(_ editor: IPhoneMarkdownTextView, _ styler: IPhoneMarkdownEditor) async {
        func distribution(_ values: [Double]) -> [String: Double] {
            let sorted = values.sorted()
            func percentile(_ p: Double) -> Double { sorted[max(0, Int(ceil(Double(sorted.count) * p)) - 1)] }
            return ["p50": percentile(0.50), "p95": percentile(0.95), "p99": percentile(0.99), "max": sorted.last ?? 0]
        }
        for (name, size, huge) in [("1KiB", 1_024, false), ("10KiB", 10_240, false),
                                   ("100KiB", 102_400, false), ("huge-paragraph", 102_400, true)] {
            let unit = huge ? "a" : "plain source line\n"
            let source = String(repeating: unit, count: size / unit.utf8.count)
            styler.restore(source, in: editor)
            editor.selectedRange = NSRange(location: editor.textStorage.length, length: 0)
            editor.undoManager?.removeAllActions()
            var input: [Double] = [], style: [Double] = []
            for index in 0..<1_000 {
                let start = ProcessInfo.processInfo.systemUptime
                editor.insertText(index % 40 == 39 && !huge ? "\n" : "a")
                input.append((ProcessInfo.processInfo.systemUptime - start) * 1_000)
                style.append(styler.lastStyleMilliseconds)
                await Task.yield()
            }
            samples.append(["fixture": name, "keys": input.count, "inputMilliseconds": distribution(input),
                            "styleMilliseconds": distribution(style), "inputOver100ms": input.filter { $0 > 100 }.count,
                            "styleP95Budget": 2, "styleP99Budget": 4,
                            "visibleP95Budget": 33, "visibleP99Budget": 50])
            check(editor.textStorage.length == source.utf16.count + 1_000, name + " timed input source length")
        }
        let paste = String(repeating: "e\u{301} 👩🏽‍💻\n", count: 60_000)
        styler.restore("", in: editor)
        UIPasteboard.general.string = paste
        let start = ProcessInfo.processInfo.systemUptime
        editor.paste(nil)
        samples.append(["fixture": "1MB-paste", "bytes": paste.utf8.count,
                        "milliseconds": (ProcessInfo.processInfo.systemUptime - start) * 1_000])
        bytes(editor.text, paste, "large paste exact source")
    }
}
