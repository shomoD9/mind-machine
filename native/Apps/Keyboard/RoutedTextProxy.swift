/* The text document KeyboardKit types into. KeyboardViewController installs one instance as
 KeyboardKit's `textInputProxy`, so every key, delete (including word-repeat), double-space
 period, space-bar cursor drag and autocapitalisation check goes through here. Each call asks
 the controller (TextRouteOwner) for the current typing destination: the private note editor,
 the host app's text field, or nothing while a read-only original is displayed. Host writes use
 the controller's validated host proxy; host text is never read into or retained by the note. */
import UIKit

@MainActor
protocol TextRouteOwner: AnyObject {
    /// The editable private editor when it is the typing destination, otherwise nil.
    var privateEditorForTyping: UITextView? { get }
    /// True when keys go to the host app.
    var routesToHost: Bool { get }
    /// The last identified host proxy, for reading traits and context without side effects.
    var hostProxyForReading: UITextDocumentProxy? { get }
    /// Perform a host write through the validated host proxy; shows a visible message if none.
    func writeToHost(_ write: (UITextDocumentProxy) -> Void)
    /// Called after every private edit so drafts, selection and Recall stay current.
    func privateEditorDidChange()
}

@MainActor
final class RoutedTextProxy: NSObject, UITextDocumentProxy {
    weak var owner: TextRouteOwner?
    // The private note is one document for KeyboardKit's purposes; its identity never changes.
    private let privateIdentifier = UUID()
    // Apple's proxy offers a bounded window of context. A bounded window here keeps
    // per-key reads cheap on long essays while covering word and sentence checks.
    private let contextWindow = 512

    private var editor: UITextView? { owner?.privateEditorForTyping }
    private var host: UITextDocumentProxy? { owner?.routesToHost == true ? owner?.hostProxyForReading : nil }

    // MARK: Reading

    var documentContextBeforeInput: String? {
        if let host { return host.documentContextBeforeInput }
        guard let editor else { return nil }
        let text = editor.text as NSString
        let end = min(editor.selectedRange.location, text.length)
        var start = max(0, end - contextWindow)
        // Never split a composed character (emoji, accents) at the window edge.
        if start > 0 { start = NSMaxRange(text.rangeOfComposedCharacterSequence(at: start - 1)) }
        return text.substring(with: NSRange(location: start, length: end - start))
    }

    var documentContextAfterInput: String? {
        if let host { return host.documentContextAfterInput }
        guard let editor else { return nil }
        let text = editor.text as NSString
        let start = min(NSMaxRange(editor.selectedRange), text.length)
        var end = min(text.length, start + contextWindow)
        if end < text.length { end = text.rangeOfComposedCharacterSequence(at: end).location }
        return text.substring(with: NSRange(location: start, length: max(0, end - start)))
    }

    var selectedText: String? {
        if let host { return host.selectedText }
        guard let editor, editor.selectedRange.length > 0 else { return nil }
        return (editor.text as NSString).substring(with: editor.selectedRange)
    }

    var documentInputMode: UITextInputMode? { host?.documentInputMode }
    var documentIdentifier: UUID { host?.documentIdentifier ?? privateIdentifier }
    var hasText: Bool { host?.hasText ?? editor?.hasText ?? false }

    // MARK: Traits — the host's field when typing into the app, the note's editor otherwise

    var autocapitalizationType: UITextAutocapitalizationType {
        get { host?.autocapitalizationType ?? editor?.autocapitalizationType ?? .sentences }
        set {}
    }
    var keyboardType: UIKeyboardType {
        get { host?.keyboardType ?? .default }
        set {}
    }
    var returnKeyType: UIReturnKeyType {
        get { host?.returnKeyType ?? .default }
        set {}
    }
    var keyboardAppearance: UIKeyboardAppearance {
        get { host?.keyboardAppearance ?? .default }
        set {}
    }
    var autocorrectionType: UITextAutocorrectionType {
        get { host?.autocorrectionType ?? .no }
        set {}
    }

    // MARK: Writing

    func insertText(_ text: String) {
        if owner?.routesToHost == true { owner?.writeToHost { $0.insertText(text) }; return }
        guard let editor else { return }
        editor.insertText(text)
        editor.scrollRangeToVisible(editor.selectedRange)
        owner?.privateEditorDidChange()
    }

    func deleteBackward() {
        if owner?.routesToHost == true { owner?.writeToHost { $0.deleteBackward() }; return }
        guard let editor else { return }
        editor.deleteBackward()
        owner?.privateEditorDidChange()
    }

    // KeyboardKit's space-bar drag and sentence handling move the caret by characters.
    // Step over composed character sequences so the caret never lands inside one.
    func adjustTextPosition(byCharacterOffset offset: Int) {
        if owner?.routesToHost == true { owner?.writeToHost { $0.adjustTextPosition(byCharacterOffset: offset) }; return }
        guard let editor, offset != 0 else { return }
        let text = editor.text as NSString
        let selection = editor.selectedRange
        var location = offset < 0 ? selection.location : NSMaxRange(selection)
        for _ in 0..<abs(offset) {
            if offset < 0 {
                guard location > 0 else { break }
                location = text.rangeOfComposedCharacterSequence(at: location - 1).location
            } else {
                guard location < text.length else { break }
                location = NSMaxRange(text.rangeOfComposedCharacterSequence(at: location))
            }
        }
        editor.selectedRange = NSRange(location: location, length: 0)
        editor.scrollRangeToVisible(editor.selectedRange)
        owner?.privateEditorDidChange()
    }

    func setMarkedText(_ markedText: String, selectedRange: NSRange) {
        if owner?.routesToHost == true { owner?.writeToHost { $0.setMarkedText(markedText, selectedRange: selectedRange) }; return }
        editor?.setMarkedText(markedText, selectedRange: selectedRange)
        owner?.privateEditorDidChange()
    }

    func unmarkText() {
        if owner?.routesToHost == true { owner?.writeToHost { $0.unmarkText() }; return }
        editor?.unmarkText()
        owner?.privateEditorDidChange()
    }
}
