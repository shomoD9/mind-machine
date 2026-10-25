/* The Mac Capture adapter in RichNoteEditor owns this paragraph styler as its
 coordinator and builds its text view with makeScrollableEditor(). It presents
 Markdown through attributes while text storage and the Capture model retain
 literal source. SwiftPM Mac tests and the typing-cost benchmark drive the same
 factory and delegate. MarkdownCaptureTextView forwards command keys to the
 separate portable-plan adapter in MacMarkdownEditingCommands. */
#if os(macOS)
import AppKit
import Darwin
import MindMachineCore

/// Pasting into Capture always inserts source, regardless of clipboard styling.
public final class MarkdownCaptureTextView: NSTextView {
    public override func paste(_ sender: Any?) { pasteAsPlainText(sender) }

    // Only command keys enter planning; every other text-system action stays native.
    public override func insertNewline(_ sender: Any?) {
        if !MacMarkdownEditingCommands.apply(.newline, to: self) { super.insertNewline(sender) }
    }
    public override func insertTab(_ sender: Any?) {
        if !MacMarkdownEditingCommands.apply(.indent, to: self) { super.insertTab(sender) }
    }
    public override func insertBacktab(_ sender: Any?) {
        if !MacMarkdownEditingCommands.apply(.outdent, to: self) { super.insertBacktab(sender) }
    }
    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if MacMarkdownEditingCommands.isTaskToggle(event),
           MacMarkdownEditingCommands.apply(.toggleTask, to: self) { return true }
        return super.performKeyEquivalent(with: event)
    }
}

@MainActor
public final class MacMarkdownEditor: NSObject, NSTextViewDelegate, NSTextStorageDelegate {
    /// Builds the Capture text view inside its scroll view. RichNoteEditor's
    /// Mac adapter and CaptureTypingCostTests share this, so the benchmark
    /// measures the same TextKit 2 configuration the app runs.
    public static func makeScrollableEditor() -> (NSScrollView, MarkdownCaptureTextView) {
        // Construct the modern engine explicitly; never access layoutManager.
        let scroll = NSScrollView()
        let editor = MarkdownCaptureTextView(usingTextLayoutManager: true)
        scroll.hasVerticalScroller = true
        editor.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        editor.isVerticallyResizable = true
        editor.isHorizontallyResizable = false
        editor.autoresizingMask = [.width]
        editor.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        editor.textContainer?.widthTracksTextView = true
        scroll.documentView = editor
        editor.setAccessibilityIdentifier("capture-editor")
        editor.isRichText = true
        // The page is the panel behind it: no own background, an overlay scroller that appears only
        // while scrolling, and text starting at the view's edge so it lines up with the prompt and tabs.
        scroll.drawsBackground = false
        scroll.scrollerStyle = .overlay
        scroll.autohidesScrollers = true
        editor.drawsBackground = false
        editor.textContainerInset = .zero
        editor.textContainer?.lineFragmentPadding = 0
        editor.importsGraphics = false
        editor.font = RichTextEditing.bodyFont
        return (scroll, editor)
    }

    public var changed: () -> Void = {}
    public private(set) var lastRestyledRange = NSRange(location: 0, length: 0)
    public private(set) var lastStyleMilliseconds = 0.0
    private var editedRange: NSRange?
    private weak var editor: NSTextView?
    private var applying = false
    private var attributeTransaction = false
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
    public func restoreIfNeeded(_ source: String, in editor: NSTextView) {
        if !Self.sourceBytesEqual(editor.string, source) { restore(source, in: editor) }
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

    public func restore(_ source: String, in editor: NSTextView) {
        guard !editor.hasMarkedText(), let storage = editor.textStorage else { return }
        applying = true
        let base = baseAttributes(editor)
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
        // textDidChange; the portable invalidator includes both sides of splits.
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

    // Plain source carries no paragraph style, as in a stock text view: an
    // explicit default style is visually identical but gives TextKit one more
    // paragraph-wide attribute to carry on every edit. List lines add their own.
    private func baseAttributes(_ editor: NSTextView) -> [NSAttributedString.Key: Any] {
        [.font: bodyFont, .foregroundColor: NSColor.labelColor]
    }

    private func restyle(_ editor: NSTextView) {
        guard !applying, !editor.hasMarkedText(), let storage = editor.textStorage,
              let edit = editedRange else { return }
        let start = ProcessInfo.processInfo.systemUptime
        defer { lastStyleMilliseconds = (ProcessInfo.processInfo.systemUptime - start) * 1_000 }
        editedRange = nil
        // Read UTF-16 directly from the backing store. Bridging storage.string
        // and asking for paragraphRange can scan/copy an arbitrarily large note
        // before a parser cap has any chance to reject it.
        let source = storage.mutableString
        guard let range = MarkdownContextInvalidation.affected(by: edit, length: storage.length,
                                                      characterAt: { source.character(at: $0) }) else {
            lastRestyledRange = NSRange(location: min(edit.location, storage.length), length: 0)
            return
        }
        lastRestyledRange = range
        let base = baseAttributes(editor)
        let selection = editor.selectedRanges
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
            assert(editor.selectedRanges == selection)
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
