/* Native visual note editor used by WorkspaceView on Mac/iPhone. The keyboard
 reuses RichTextEditing for the same bold/italic/list operations and RTF format.
 The editor surface and formatting chips use the Greyscale palette. Mac Capture
 uses MacMarkdownEditor for source-preserving live attributes; iOS keeps RTF. */
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

    #if os(iOS)
    private typealias NativeFont = UIFont
    private static var bodyFont: UIFont { .preferredFont(forTextStyle: .body) }
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
    private static var bodyFont: NSFont { .systemFont(ofSize: NSFont.systemFontSize) }
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
    @StateObject private var controller = NoteEditorController()

    public init(text: Binding<String>, richText: Binding<Data?>) { _text = text; _richText = richText }
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Formatting is optional and never adds an organizing step to capture.
            HStack(spacing: 4) {
                ForEach(NoteFormat.allCases, id: \.rawValue) { format in
                    // Titles stay as authored; the weight or slant previews the effect.
                    Button { controller.apply(format) } label: {
                        Text(format.rawValue)
                            .fontWeight(format == .bold ? .bold : .medium)
                            .italic(format == .italic)
                            .padding(.horizontal, 9).padding(.vertical, 4)
                            .background(Greyscale.fill.color, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    }
                    .buttonStyle(.plain).font(.subheadline).foregroundStyle(Greyscale.ink.color)
                    .accessibilityLabel(format == .checkbox ? "Checkbox" : format == .bullet ? "Bullet" : format.rawValue)
                    .accessibilityIdentifier("format-\(format == .checkbox ? "checkbox" : format == .bullet ? "bullet" : format.rawValue.lowercased())")
                }
            }
            NativeNoteAdapter(text: $text, richText: $richText, controller: controller)
                .padding(6)
                .background(Greyscale.paper.color, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Greyscale.hairline.color, lineWidth: 1))
                .accessibilityLabel("Private note").accessibilityIdentifier("capture-editor")
        }
    }
}

@MainActor
private final class NoteEditorController: NSObject, ObservableObject {
    weak var editor: NativeNoteTextView?
    var changed: () -> Void = {}

    func apply(_ format: NoteFormat) {
        guard let editor else { return }
        RichTextEditing.apply(format, to: editor)
        changed()
    }
}

#if os(iOS)
private struct NativeNoteAdapter: UIViewRepresentable {
    @Binding var text: String
    @Binding var richText: Data?
    let controller: NoteEditorController

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> UITextView {
        let editor = UITextView()
        // Native elements need the identifier as well as the SwiftUI wrapper so
        // UI acceptance can focus/type into the actual editor on both platforms.
        editor.accessibilityIdentifier = "capture-editor"
        editor.font = .preferredFont(forTextStyle: .body)
        // The rounded paper surface is drawn by SwiftUI around this view.
        editor.backgroundColor = .clear
        editor.tintColor = Greyscale.ink.uiColor
        editor.allowsEditingTextAttributes = true
        editor.delegate = context.coordinator
        controller.editor = editor
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
        controller.changed = publish
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
    let controller: NoteEditorController

    func makeCoordinator() -> MacMarkdownEditor { MacMarkdownEditor() }
    func makeNSView(context: Context) -> NSScrollView {
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
        // The rounded paper surface is drawn by SwiftUI around this view.
        scroll.drawsBackground = false
        editor.drawsBackground = false
        editor.importsGraphics = false
        editor.font = .systemFont(ofSize: NSFont.systemFontSize)
        context.coordinator.attach(to: editor)
        controller.editor = editor
        return scroll
    }
    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let editor = scroll.documentView as? NSTextView else { return }
        if !editor.string.utf8.elementsEqual(text.utf8) { context.coordinator.restore(text, in: editor) }
        let publish = {
            text = editor.string
            richText = nil // Mac presentation is derived from the exact Markdown source.
        }
        context.coordinator.changed = publish
        controller.changed = publish
    }
}
#endif
