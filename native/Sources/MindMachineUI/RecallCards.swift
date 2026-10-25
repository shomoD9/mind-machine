/* The Mac Recall result card and the Mac query field that moves a selection through the cards.
 WorkspaceView (WorkspaceView.swift) lays RecallCards out two wide in a LazyVGrid when Recall has
 matches, and uses RecallQueryField in place of a SwiftUI TextField on the Mac so the arrow keys and
 Return reach the grid while the caret stays in the query. RecallGrid.swift holds the movement and
 title/body rules. PillAcceptanceTests and PillSelfTest find the field as `recall-query` and each
 card as `capture-result`.

 A card is a flat greyscale tile: title in ink, up to three body lines in secondary ink with matched
 words in heavier full ink, and the date in tertiary ink pinned to the bottom. Every card has the same
 height, so the grid reads as even rows. Resting cards have only a hairline border; hover adds a light
 fill, the keyboard selection adds the fill and a darker border, and pressing deepens the fill. */
import SwiftUI
import MindMachineCore
#if os(macOS)
import AppKit
#endif

struct RecallCard: View {
    let hit: SearchHit
    let selected: Bool
    let overdue: Bool
    let open: () -> Void
    @State private var hovering = false

    // Written out because the private hover state would make the memberwise initializer private.
    init(hit: SearchHit, selected: Bool, overdue: Bool, open: @escaping () -> Void) {
        self.hit = hit
        self.selected = selected
        self.overdue = overdue
        self.open = open
    }

    /// Two title lines, or one title line and three body lines, plus the date row and padding.
    static let height: CGFloat = 104
    static let cornerRadius: CGFloat = 8

    var body: some View {
        let text = RecallCardText(highlighted: hit.highlightedText)
        Button(action: open) {
            VStack(alignment: .leading, spacing: 4) {
                Text(SearchPreview.attributed(text.title, matchFont: .system(size: 13, weight: .bold)))
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(Greyscale.ink.color)
                    .lineLimit(2)
                    // The title keeps its lines; the body gives up lines first when space runs out.
                    .layoutPriority(1)
                if !text.body.isEmpty {
                    Text(SearchPreview.attributed(text.body, matchFont: .system(size: 12, weight: .semibold),
                                                  matchColor: Greyscale.ink.color))
                        .font(.system(size: 12)).foregroundStyle(Greyscale.inkSecondary.color)
                        .lineLimit(3)
                }
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    Text(hit.capture.createdAt, style: .date).foregroundStyle(Greyscale.inkTertiary.color)
                    if overdue { Text("Overdue").bold().foregroundStyle(Greyscale.ink.color) }
                }
                .font(.caption).lineLimit(1)
            }
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 11).padding(.vertical, 9)
            .frame(maxWidth: .infinity, minHeight: Self.height, maxHeight: Self.height, alignment: .topLeading)
            .contentShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
        }
        .buttonStyle(RecallCardStyle(selected: selected, hovering: hovering))
        .onHover { hovering = $0 }
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("capture-result")
    }
}

/// Paints a card's state. The fill and border use the shared greyscale tones, with no shadow or blur.
private struct RecallCardStyle: ButtonStyle {
    let selected: Bool
    let hovering: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: RecallCard.cornerRadius, style: .continuous)
        let fill: Color = configuration.isPressed ? Greyscale.fillPressed.color
            : (selected || hovering) ? Greyscale.fill.color : .clear
        return configuration.label
            .background(shape.fill(fill))
            .overlay(shape.strokeBorder(selected ? Greyscale.inkTertiary.color : Greyscale.hairline.color, lineWidth: 1))
    }
}

#if os(macOS)
/// The Mac Recall query: a plain single-line field in the writing font. Its delegate hears the arrow
/// keys and Return before the field editor acts on them, so the grid can be driven without the caret
/// ever leaving the query. Keys the grid does not use (and every key while an input method is
/// composing) fall through to normal text editing.
struct RecallQueryField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    /// Returns true when the key was used by the grid, so the field does not also move its caret.
    let onMove: (RecallGrid.Direction) -> Bool
    let onSubmit: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField(string: text)
        field.isBordered = false
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.cell?.usesSingleLineMode = true
        field.cell?.isScrollable = true
        field.cell?.wraps = false
        field.font = RichTextEditing.bodyFont
        field.textColor = Greyscale.ink.nsColor
        field.placeholderString = placeholder
        field.delegate = context.coordinator
        field.setAccessibilityIdentifier("recall-query")
        // Fill the row like the SwiftUI field did, instead of hugging the typed text.
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        context.coordinator.parent = self
        // Only external changes are written back; echoing every keystroke would reset the caret.
        if field.stringValue != text { field.stringValue = text }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: RecallQueryField
        init(_ parent: RecallQueryField) { self.parent = parent }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            if textView.hasMarkedText() { return false }
            switch selector {
            case #selector(NSResponder.moveUp(_:)): return parent.onMove(.up)
            case #selector(NSResponder.moveDown(_:)): return parent.onMove(.down)
            case #selector(NSResponder.moveLeft(_:)): return parent.onMove(.left)
            case #selector(NSResponder.moveRight(_:)): return parent.onMove(.right)
            // Return opens a card and must not select the query text, which is the field's default.
            case #selector(NSResponder.insertNewline(_:)): parent.onSubmit(); return true
            default: return false
            }
        }
    }
}
#endif
