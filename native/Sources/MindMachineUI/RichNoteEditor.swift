/* Native note editor used by WorkspaceView for Capture on the Mac pill and the iPhone companion.
 The editor is a plain writing page: no formatting buttons, no card around it, and an optional prompt
 drawn where the first word will go until the person starts typing. RTF is still restored and stored
 alongside the exact original string. The keyboard (Apps/Keyboard/KeyboardViewController.swift) calls
 RichTextEditing.apply for its own bold/italic/list chips; the Mac and companion editors no longer do,
 and Mac Capture styles Markdown typed in the page through MacMarkdownEditor, keeping the stored text
 literal source with no RTF; the companion keeps RTF. Colours come from Greyscale.swift. */
import SwiftUI
#if os(iOS)
import UIKit
public typealias NativeNoteTextView = UITextView
#else
import AppKit
public typealias NativeNoteTextView = NSTextView
#endif

public enum NoteFormat: String, CaseIterable { case bold = "Bold", italic = "Italic", bullet = "•", checkbox = "☐" }

@MainActor
public enum RichTextEditing {
    /// RTF carries visual formatting; the separately stored string is always the
    /// original retrieval source. A malformed/mismatched rich payload cannot rewrite it.
    public static func restore(text: String, richText: Data?, in editor: NativeNoteTextView) {
        let decoded = richText.flatMap { try? NSAttributedString(data: $0, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) }
        let content = decoded?.string == text ? decoded! : NSAttributedString(string: text, attributes: [.font: bodyFont])
        #if os(iOS)
        editor.attributedText = content
        #else
        editor.textStorage?.setAttributedString(content)
        #endif
    }

    public static func encoded(_ text: NSAttributedString) throws -> Data {
        try text.data(from: NSRange(location: 0, length: text.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
    }

    /// Changes apply to the selected private text, or to subsequent typing at a
    /// collapsed caret. Explicit list controls author visible bullets/checkboxes.
    public static func apply(_ format: NoteFormat, to editor: NativeNoteTextView) {
        #if os(iOS)
        let selection = editor.selectedRange
        let storage = editor.textStorage
        #else
        let selection = editor.selectedRange()
        guard let storage = editor.textStorage else { return }
        #endif
        if format == .bullet || format == .checkbox {
            let prefix = format == .bullet ? "• " : "☐ "
            let original = storage.string as NSString
            let paragraphs = original.paragraphRange(for: selection)
            var starts: [Int] = []
            var cursor = paragraphs.location
            // Collect original paragraph offsets, then insert backwards so each
            // prefix leaves the remaining original offsets valid.
            repeat {
                starts.append(cursor)
                let next = NSMaxRange(original.paragraphRange(for: NSRange(location: cursor, length: 0)))
                if next <= cursor { break }
                cursor = next
            } while cursor < NSMaxRange(paragraphs)
            for start in starts.reversed() {
                storage.insert(NSAttributedString(string: prefix, attributes: editor.typingAttributes), at: start)
            }
            let prefixLength = (prefix as NSString).length
            setSelection(NSRange(location: selection.location + prefixLength,
                                 length: selection.length + prefixLength * (starts.count - 1)), in: editor)
            return
        }
        let font = (selection.length > 0 ? storage.attribute(.font, at: selection.location, effectiveRange: nil) : editor.typingAttributes[.font]) as? NativeFont ?? bodyFont
        let enabled = has(format, in: font)
        if selection.length == 0 {
            var attributes = editor.typingAttributes
            attributes[.font] = toggled(format, font: font, enabled: !enabled)
            editor.typingAttributes = attributes
        } else {
            storage.enumerateAttribute(.font, in: selection) { value, range, _ in
                storage.addAttribute(.font, value: toggled(format, font: value as? NativeFont ?? bodyFont, enabled: !enabled), range: range)
            }
            setSelection(selection, in: editor)
        }
    }

    public static func setSelection(_ selection: NSRange, in editor: NativeNoteTextView) {
        #if os(iOS)
        let count = (editor.text as NSString).length
        #else
        let count = (editor.string as NSString).length
        #endif
        // Native range APIs use UTF-16. Clamp a restored caret if its text changed.
        let location = min(selection.location, count)
        let range = NSRange(location: location, length: min(selection.length, count - location))
        #if os(iOS)
        editor.selectedRange = range
        #else
        editor.setSelectedRange(range)
        #endif
    }

    // The writing font is shared by the live editor, restored plain drafts and the prompt overlay,
    // so the prompt sits exactly where typed text will appear. The Mac page uses 15 pt rather than the
    // 13 pt system size: about 65 characters per line across the 540 pt pill, a comfortable measure.
    #if os(iOS)
    private typealias NativeFont = UIFont
    static var bodyFont: UIFont { .preferredFont(forTextStyle: .body) }
    static var writingFont: Font { .body }
    private static func has(_ format: NoteFormat, in font: UIFont) -> Bool {
        font.fontDescriptor.symbolicTraits.contains(format == .bold ? .traitBold : .traitItalic)
    }
    private static func toggled(_ format: NoteFormat, font: UIFont, enabled: Bool) -> UIFont {
        var traits = font.fontDescriptor.symbolicTraits
        let trait: UIFontDescriptor.SymbolicTraits = format == .bold ? .traitBold : .traitItalic
        if enabled { traits.insert(trait) } else { traits.remove(trait) }
        return font.fontDescriptor.withSymbolicTraits(traits).map { UIFont(descriptor: $0, size: font.pointSize) } ?? font
    }
    #else
    private typealias NativeFont = NSFont
    static var bodyFont: NSFont { .systemFont(ofSize: 15) }
    static var writingFont: Font { .system(size: 15) }
    private static func has(_ format: NoteFormat, in font: NSFont) -> Bool {
        NSFontManager.shared.traits(of: font).contains(format == .bold ? .boldFontMask : .italicFontMask)
    }
    private static func toggled(_ format: NoteFormat, font: NSFont, enabled: Bool) -> NSFont {
        let trait: NSFontTraitMask = format == .bold ? .boldFontMask : .italicFontMask
        return enabled ? NSFontManager.shared.convert(font, toHaveTrait: trait) : NSFontManager.shared.convert(font, toNotHaveTrait: trait)
    }
    #endif
}

public struct RichNoteEditor: View {
    @Binding private var text: String
    @Binding private var richText: Data?
    private let prompt: String?

    /// `prompt` is shown in the page while the note is empty, in the writing font and the faintest ink.
    public init(text: Binding<String>, richText: Binding<Data?>, prompt: String? = nil) {
        _text = text; _richText = richText; self.prompt = prompt
    }
    public var body: some View {
        NativeNoteAdapter(text: $text, richText: $richText)
            .accessibilityLabel("Private note").accessibilityIdentifier("capture-editor")
            // Both native editors have zero text insets and line padding (set below), so the prompt's
            // top-left corner is the caret's. It ignores clicks, which land in the editor underneath.
            .overlay(alignment: .topLeading) {
                if let prompt, text.isEmpty {
                    Text(prompt).font(RichTextEditing.writingFont)
                        .foregroundStyle(Greyscale.inkTertiary.color)
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
            }
    }
}

#if os(iOS)
private struct NativeNoteAdapter: UIViewRepresentable {
    @Binding var text: String
    @Binding var richText: Data?

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> UITextView {
        let editor = UITextView()
        // Native elements need the identifier as well as the SwiftUI wrapper so
        // UI acceptance can focus/type into the actual editor on both platforms.
        editor.accessibilityIdentifier = "capture-editor"
        editor.font = RichTextEditing.bodyFont
        // The page is the screen behind it: no own background, and text starts at the view's edge
        // so it lines up with the prompt and the surrounding layout margins.
        editor.backgroundColor = .clear
        editor.textContainerInset = .zero
        editor.textContainer.lineFragmentPadding = 0
        editor.tintColor = Greyscale.ink.uiColor
        editor.allowsEditingTextAttributes = true
        editor.delegate = context.coordinator
        return editor
    }
    func updateUIView(_ editor: UITextView, context: Context) {
        // Do not replace attributed text during ordinary typing; native selection,
        // undo and composition remain owned by the same live editor.
        if editor.text != text { RichTextEditing.restore(text: text, richText: richText, in: editor) }
        let publish = {
            text = editor.text
            richText = try? RichTextEditing.encoded(editor.attributedText)
        }
        context.coordinator.changed = publish
    }
    final class Coordinator: NSObject, UITextViewDelegate {
        var changed: () -> Void = {}
        func textViewDidChange(_ textView: UITextView) { changed() }
    }
}
#else
private struct NativeNoteAdapter: NSViewRepresentable {
    @Binding var text: String
    @Binding var richText: Data?

    func makeCoordinator() -> MacMarkdownEditor { MacMarkdownEditor() }
    func makeNSView(context: Context) -> NSScrollView {
        let (scroll, editor) = MacMarkdownEditor.makeScrollableEditor()
        context.coordinator.attach(to: editor)
        // Install publication during creation so immediate first-key input has
        // the same handoff as every later representable update.
        context.coordinator.changed = {
            text = editor.string
            richText = nil
        }
        return scroll
    }
    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let editor = scroll.documentView as? NSTextView else { return }
        context.coordinator.restoreIfNeeded(text, in: editor)
        let publish = {
            text = editor.string
            richText = nil // Mac presentation is derived from the exact Markdown source.
        }
        context.coordinator.changed = publish
    }
}
#endif
