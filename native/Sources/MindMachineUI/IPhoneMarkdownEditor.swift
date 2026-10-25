/* UIKit presentation adapter used by RichNoteEditor's iPhone companion.
 The portable core owns parsing, bounded UTF-16 invalidation and command plans.
 TextKit 2 storage retains literal Markdown; this coordinator adds disposable
 attributes outside undo and waits for marked input to commit. The Simulator
 host exercises this same factory, delegate and composition boundary. */
#if os(iOS)
import UIKit
import Darwin
import os
import MindMachineCore

@MainActor
public final class IPhoneMarkdownEditor: NSObject, UITextViewDelegate, NSTextStorageDelegate {
    /// RichNoteEditor and the Simulator harness use this exact TextKit 2 factory.
    public static func makeEditor() -> IPhoneMarkdownTextView {
        let editor = IPhoneMarkdownTextView(usingTextLayoutManager: true)
        editor.accessibilityIdentifier = "capture-editor"
        editor.font = RichTextEditing.bodyFont
        editor.backgroundColor = .clear
        editor.textContainerInset = .zero
        editor.textContainer.lineFragmentPadding = 0
        editor.tintColor = Greyscale.ink.uiColor
        editor.allowsEditingTextAttributes = false
        editor.smartQuotesType = .no
        editor.smartDashesType = .no
        editor.smartInsertDeleteType = .no
        editor.autocorrectionType = .no
        editor.autocapitalizationType = .none
        editor.spellCheckingType = .no
        editor.dataDetectorTypes = []
        return editor
    }

    public var changed: () -> Void = {}
    public private(set) var lastRestyledRange = NSRange(location: 0, length: 0)
    public private(set) var lastStyleMilliseconds = 0.0
    private let signposter = OSSignposter(subsystem: "com.statemachine.mindmachine", category: "iPhone Markdown")
    private var editedRange: NSRange?
    private var applying = false
    private var attributeTransaction = false
    private var bodyFont = UIFont.preferredFont(forTextStyle: .body)

    public func attach(to editor: IPhoneMarkdownTextView) {
        bodyFont = editor.font ?? bodyFont
        editor.delegate = self
        editor.textStorage.delegate = self
        editor.markdown = self
    }

    /// External draft restoration is the only whole-source replacement. RTF is
    /// intentionally disposable on iPhone; source is never reconstructed from it.
    public func restoreIfNeeded(_ source: String, in editor: IPhoneMarkdownTextView) {
        if !Self.sourceBytesEqual(editor.text ?? "", source) { restore(source, in: editor) }
    }

    // NSTextStorage can bridge a foreign UTF-16 string. Materialise UTF-8 before
    // comparing, otherwise withContiguousStorageIfAvailable misses the fast path
    // and Debug performs a generic Swift iteration for every byte on every key.
    // Canonical String equality would miss external NFC/NFD source changes.
    nonisolated static func sourceBytesEqual(_ lhs: String, _ rhs: String) -> Bool {
        var left = lhs, right = rhs
        left.makeContiguousUTF8()
        right.makeContiguousUTF8()
        guard left.utf8.count == right.utf8.count else { return false }
        return left.utf8.withContiguousStorageIfAvailable { a in
            right.utf8.withContiguousStorageIfAvailable { b in
                a.isEmpty || memcmp(a.baseAddress!, b.baseAddress!, a.count) == 0
            }
        }.flatMap { $0 } ?? left.utf8.elementsEqual(right.utf8)
    }

    public func restore(_ source: String, in editor: IPhoneMarkdownTextView) {
        guard editor.markedTextRange == nil, !editor.isSettingMarkedText else { return }
        applying = true
        let storage = editor.textStorage
        let base = baseAttributes(editor)
        // A different external draft starts a new native undo history.
        editor.undoManager?.removeAllActions()
        storage.setAttributedString(NSAttributedString(string: source, attributes: base))
        editor.typingAttributes = base
        applying = false
        editedRange = NSRange(location: 0, length: storage.length)
        restyle(editor)
    }

    public func textStorage(_ textStorage: NSTextStorage, willProcessEditing editedMask: NSTextStorageEditActions,
                            range: NSRange, changeInLength delta: Int) {
        guard !applying, editedMask.contains(.editedCharacters) else { return }
        // Record character edits before native attribute fixing can widen the
        // range through an existing separator. Presentation still waits for
        // textViewDidChange; the portable invalidator includes both sides of splits.
        if let previous = editedRange { editedRange = NSUnionRange(previous, range) }
        else { editedRange = range }
    }

    public func textViewDidChange(_ textView: UITextView) {
        guard let editor = textView as? IPhoneMarkdownTextView else { return }
        restyle(editor)
        changed()
    }

    // UIKit can end composition without another character edit. Retain the
    // accumulated dirty range until unmarking, then style and publish once more.
    func compositionEnded(in editor: IPhoneMarkdownTextView) {
        textViewDidChange(editor)
    }

    // Plain source carries no paragraph style, as in a stock text view: an
    // explicit default style is visually identical but gives TextKit one more
    // paragraph-wide attribute to carry on every edit. List lines add their own.
    private func baseAttributes(_ editor: UITextView) -> [NSAttributedString.Key: Any] {
        [.font: bodyFont, .foregroundColor: UIColor.label]
    }

    private func restyle(_ editor: IPhoneMarkdownTextView) {
        guard !applying, editor.markedTextRange == nil, !editor.isSettingMarkedText,
              let edit = editedRange else { return }
        let interval = signposter.beginInterval("Style")
        let start = ProcessInfo.processInfo.systemUptime
        defer {
            lastStyleMilliseconds = (ProcessInfo.processInfo.systemUptime - start) * 1_000
            signposter.endInterval("Style", interval)
        }
        editedRange = nil
        // Read UTF-16 directly from the backing store. Bridging storage.string
        // and asking for paragraphRange can scan/copy an arbitrarily large note
        // before a parser cap has any chance to reject it.
        let storage = editor.textStorage
        let source = storage.mutableString
        guard let range = MarkdownContextInvalidation.affected(by: edit, length: storage.length,
                                                      characterAt: { source.character(at: $0) }) else {
            lastRestyledRange = NSRange(location: min(edit.location, storage.length), length: 0)
            return
        }
        lastRestyledRange = range
        let base = baseAttributes(editor)
        let selection = editor.selectedRange
        applying = true
        let undo = editor.undoManager
        undo?.disableUndoRegistration()
        defer {
            if attributeTransaction {
                storage.endEditing()
                attributeTransaction = false
            }
            undo?.enableUndoRegistration()
            applying = false
            // No selection or scroll adjustment: native editing owns both.
            assert(editor.selectedRange == selection)
            if !NSDictionary(dictionary: editor.typingAttributes).isEqual(to: base) {
                editor.typingAttributes = base
            }
        }
        // Only bounded paragraphs reach parsing or attribute enumeration. A
        // huge plain paragraph does no attribute work or empty transaction.
        var cursor = range.location
        while cursor < NSMaxRange(range) {
            let paragraph = source.paragraphRange(for: NSRange(location: cursor, length: 0))
            let style = paragraph.length <= MarkdownParagraph.maximumUTF16Length
                ? MarkdownParagraph(source.substring(with: paragraph)) : MarkdownParagraph("")
            var attributes = base
            let bodyFont = base[.font] as! UIFont
            if case let .heading(level) = style.block {
                attributes[.font] = UIFont.systemFont(ofSize: bodyFont.pointSize + CGFloat(4 - level) * 2, weight: .semibold)
            }
            if style.block == .bullet || style.block == .task(checked: false) || style.block == .task(checked: true) {
                let indent = NSMutableParagraphStyle()
                indent.headIndent = bodyFont.pointSize * 1.5
                attributes[.paragraphStyle] = indent
            }
            let desired = NSMutableAttributedString(string: source.substring(with: paragraph), attributes: attributes)
            // Traits compose: bold inside italic, or emphasis in a heading,
            // retains the surrounding font. All ranges are already UTF-16.
            for span in style.spans where span.style == .bold || span.style == .italic {
                desired.enumerateAttribute(.font, in: span.range) { value, run, _ in
                    let font = value as? UIFont ?? bodyFont
                    var traits = font.fontDescriptor.symbolicTraits
                    traits.insert(span.style == .bold ? .traitBold : .traitItalic)
                    if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                        desired.addAttribute(.font, value: UIFont(descriptor: descriptor, size: font.pointSize), range: run)
                    }
                }
            }
            for span in style.spans {
                if span.style == .link {
                    desired.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: span.range)
                } else if span.style == .marker {
                    desired.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: span.range)
                }
            }
            desired.enumerateAttributes(in: NSRange(location: 0, length: desired.length)) { values, run, _ in
                apply(values, in: NSRange(location: paragraph.location + run.location, length: run.length), storage: storage)
            }
            cursor = NSMaxRange(paragraph)
        }
    }

    private func apply(_ attributes: [NSAttributedString.Key: Any], in range: NSRange, storage: NSTextStorage) {
        // Record differences first; mutating while enumerating can merge runs.
        var changes: [NSRange] = []
        storage.enumerateAttributes(in: range) { existing, run, _ in
            if !NSDictionary(dictionary: existing).isEqual(to: attributes) { changes.append(run) }
        }
        guard !changes.isEmpty else { return }
        // One transaction for actual differences; never start/end an empty
        // transaction, which can still ask TextKit to reconsider paragraph layout.
        if !attributeTransaction {
            attributeTransaction = true
            storage.beginEditing()
        }
        for run in changes { storage.setAttributes(attributes, range: run) }
    }
}
#endif
