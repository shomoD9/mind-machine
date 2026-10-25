/* Source-only UIKit editing used by IPhoneMarkdownEditor/RichNoteEditor.
 Command keys consume portable UTF-16 plans through UITextView's native input
 path, retaining UIKit undo. Clipboard operations expose only literal Markdown.
 The keyboard extension continues to construct its own plain UITextView. */
#if os(iOS)
import UIKit
import MindMachineCore

public final class IPhoneMarkdownTextView: UITextView {
    weak var markdown: IPhoneMarkdownEditor?
    private(set) var isSettingMarkedText = false

    public override func insertText(_ text: String) {
        if text == "\n", applyMarkdownCommand(.newline) { return }
        if text == "\t", applyMarkdownCommand(.indent) { return }
        super.insertText(text)
    }

    // Native input methods can notify changes before markedTextRange is set.
    // Suppress presentation for the entire call, including those callbacks.
    public override func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        isSettingMarkedText = true
        defer { isSettingMarkedText = false }
        super.setMarkedText(markedText, selectedRange: selectedRange)
    }

    public override func unmarkText() {
        super.unmarkText()
        markdown?.compositionEnded(in: self)
    }

    public override func copy(_ sender: Any?) {
        guard selectedRange.length > 0 else { return }
        UIPasteboard.general.string = textStorage.mutableString.substring(with: selectedRange)
    }

    public override func cut(_ sender: Any?) {
        guard isEditable, selectedRange.length > 0, markedTextRange == nil else { return }
        copy(sender)
        super.insertText("")
    }

    public override func paste(_ sender: Any?) {
        guard isEditable, let source = UIPasteboard.general.string else { return }
        // Pasted Markdown is literal input, including a single tab/newline.
        super.insertText(source)
    }

    public override var keyCommands: [UIKeyCommand]? {
        (super.keyCommands ?? []) + [
            UIKeyCommand(input: "\t", modifierFlags: .shift, action: #selector(outdent)),
            UIKeyCommand(input: "\r", modifierFlags: [.command, .shift], action: #selector(toggleTask))
        ]
    }
    @objc private func outdent() { _ = applyMarkdownCommand(.outdent) }
    @objc private func toggleTask() { _ = applyMarkdownCommand(.toggleTask) }

    /// Native selection and super.insertText own replacement and undo. No
    /// attributed-string replacement, source serialization or storage write is
    /// involved. A nil plan leaves input to UIKit, including all marked input.
    @discardableResult
    public func applyMarkdownCommand(_ command: MarkdownEditingCommands.Command) -> Bool {
        guard isEditable, markedTextRange == nil, !isSettingMarkedText else { return false }
        let source = textStorage.mutableString
        let selection = selectedRange
        guard selection.location <= source.length,
              MarkdownStyleRange.affected(by: selection, length: source.length,
                                          characterAt: { source.character(at: $0) }) != nil else { return false }
        let line = source.lineRange(for: NSRange(location: selection.location, length: 0))
        var length = line.length
        if length > 0, source.character(at: NSMaxRange(line) - 1) == 10 { length -= 1 }
        guard let plan = MarkdownEditingCommands.plan(
            line: source.substring(with: NSRange(location: line.location, length: length)),
            selection: NSRange(location: selection.location - line.location, length: selection.length),
            command: command) else { return false }
        for edit in plan.edits.reversed() {
            selectedRange = NSRange(location: line.location + edit.range.location, length: edit.range.length)
            super.insertText(edit.replacement)
        }
        selectedRange = NSRange(location: line.location + plan.selection.location, length: plan.selection.length)
        return true
    }
}
#endif
