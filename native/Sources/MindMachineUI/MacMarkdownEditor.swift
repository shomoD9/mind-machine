/* The Mac Capture adapter in RichNoteEditor owns this paragraph styler as its
 coordinator. It presents Markdown through attributes while text storage and the
 Capture model retain literal source. SwiftPM Mac tests drive the same delegate. */
#if os(macOS)
import AppKit
import MindMachineCore

/// Pasting into Capture always inserts source, regardless of clipboard styling.
public final class MarkdownCaptureTextView: NSTextView {
    public override func paste(_ sender: Any?) { pasteAsPlainText(sender) }
}

@MainActor
public final class MacMarkdownEditor: NSObject, NSTextViewDelegate, NSTextStorageDelegate {
    public var changed: () -> Void = {}
    public private(set) var lastRestyledRange = NSRange(location: 0, length: 0)
    public private(set) var lastStyleMilliseconds = 0.0
    private var editedRange: NSRange?
    private weak var editor: NSTextView?
    private var applying = false
    private var bodyFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)

    public func attach(to editor: NSTextView) {
        self.editor = editor
        bodyFont = editor.font ?? bodyFont
        editor.delegate = self
        editor.textStorage?.delegate = self
        editor.allowsUndo = true
        // Native substitutions would change the literal Markdown the person
        // typed. Attributes are the only automatic transformation in Capture.
        editor.isAutomaticQuoteSubstitutionEnabled = false
        editor.isAutomaticDashSubstitutionEnabled = false
        editor.isAutomaticTextReplacementEnabled = false
        editor.isAutomaticSpellingCorrectionEnabled = false
        editor.isAutomaticLinkDetectionEnabled = false
        editor.isAutomaticTextCompletionEnabled = false
        editor.smartInsertDeleteEnabled = false
    }

    /// External draft restoration is the only whole-source replacement. RTF is
    /// intentionally disposable on Mac; source is never reconstructed from it.
    public func restore(_ source: String, in editor: NSTextView) {
        guard !editor.hasMarkedText(), let storage = editor.textStorage else { return }
        applying = true
        storage.setAttributedString(NSAttributedString(string: source, attributes: baseAttributes(editor)))
        applying = false
        editedRange = NSRange(location: 0, length: storage.length)
        restyle(editor)
    }

    public func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions,
                            range: NSRange, changeInLength delta: Int) {
        guard !applying, editedMask.contains(.editedCharacters) else { return }
        // AppKit reports a range in the new UTF-16 source. A newline deletion
        // naturally includes the joined paragraph when expanded below.
        if let previous = editedRange { editedRange = NSUnionRange(previous, range) }
        else { editedRange = range }
    }

    public func textDidChange(_ notification: Notification) {
        guard let editor else { return }
        // Work after character processing, avoiding caret movement caused by
        // adding paragraph/font edits inside text storage's processing callback.
        restyle(editor)
        changed()
    }

    private func baseAttributes(_ editor: NSTextView) -> [NSAttributedString.Key: Any] {
        [.font: bodyFont,
         .foregroundColor: NSColor.labelColor, .paragraphStyle: NSParagraphStyle.default]
    }

    private func restyle(_ editor: NSTextView) {
        guard !applying, !editor.hasMarkedText(), let storage = editor.textStorage,
              let edit = editedRange else { return }
        let start = ProcessInfo.processInfo.systemUptime
        defer { lastStyleMilliseconds = (ProcessInfo.processInfo.systemUptime - start) * 1_000 }
        editedRange = nil
        let source = storage.string as NSString
        let location = min(edit.location, source.length)
        let range = source.paragraphRange(for: NSRange(location: location, length: min(edit.length, source.length - location)))
        lastRestyledRange = range
        let base = baseAttributes(editor)
        let selection = editor.selectedRanges
        applying = true
        let undo = editor.undoManager
        undo?.disableUndoRegistration()
        storage.beginEditing()
        defer {
            storage.endEditing()
            undo?.enableUndoRegistration()
            applying = false
            // No selection or scroll adjustment: native editing owns both.
            assert(editor.selectedRanges == selection)
            editor.typingAttributes = base
        }

        // A large paste/restoration or oversized paragraph stays source. This
        // caps parser work on the main thread without an async/context pipeline.
        guard range.length <= 65_536 else {
            apply(base, in: range, storage: storage)
            return
        }
        var cursor = range.location
        while cursor < NSMaxRange(range) {
            let paragraph = source.paragraphRange(for: NSRange(location: cursor, length: 0))
            let style = paragraph.length <= MarkdownParagraph.maximumUTF16Length
                ? MarkdownParagraph(source.substring(with: paragraph)) : MarkdownParagraph("")
            var attributes = base
            let bodyFont = base[.font] as! NSFont
            if case let .heading(level) = style.block {
                attributes[.font] = NSFont.systemFont(ofSize: bodyFont.pointSize + CGFloat(4 - level) * 2, weight: .semibold)
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
                    let font = value as? NSFont ?? bodyFont
                    desired.addAttribute(.font, value: NSFontManager.shared.convert(font,
                        toHaveTrait: span.style == .bold ? .boldFontMask : .italicFontMask), range: run)
                }
            }
            for span in style.spans {
                if span.style == .link {
                    desired.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: span.range)
                } else if span.style == .marker {
                    desired.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: span.range)
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
        for run in changes { storage.setAttributes(attributes, range: run) }
    }
}
#endif
