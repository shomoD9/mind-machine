/* Pure layout rules for Recall results shown as a two-column grid of cards: how the arrow keys move a
 selection through the grid, and how one highlighted search preview splits into a card's title and body.
 WorkspaceView (WorkspaceView.swift) calls `RecallGrid.move` from the Mac query field's arrow keys and
 `RecallCardText` from each RecallCard (RecallCards.swift). RecallGridTests covers both. Foundation only,
 so the rules can be checked without drawing anything. */
import Foundation

public enum RecallGrid {
    /// Cards per row. The grid fills row by row, so reading order and index order are the same.
    public static let columns = 2

    public enum Direction: Sendable { case up, down, left, right }

    /// What an arrow key does. `ignored` leaves the key to the query field (caret movement);
    /// `field` clears the selection and hands the keyboard back to the query.
    public enum Outcome: Equatable, Sendable { case select(Int), field, ignored }

    /// Moves a selection through `count` cards laid out `columns` wide.
    /// With nothing selected only Down enters the grid, so Left/Right still move the caret in the query.
    /// Inside the grid every arrow is consumed: Left/Right step in reading order, Up/Down change row,
    /// Up from the first row returns to the query, and Down into a shorter last row lands on its last card.
    public static func move(from current: Int?, _ direction: Direction, count: Int, columns: Int = columns) -> Outcome {
        guard count > 0, columns > 0 else { return .ignored }
        guard let current, current >= 0, current < count else {
            return direction == .down ? .select(0) : .ignored
        }
        switch direction {
        case .left: return .select(max(0, current - 1))
        case .right: return .select(min(count - 1, current + 1))
        case .up: return current >= columns ? .select(current - columns) : .field
        case .down:
            if current + columns < count { return .select(current + columns) }
            let lastRow = (count - 1) / columns
            return current / columns < lastRow ? .select(count - 1) : .select(current)
        }
    }
}

/// A card's two text blocks, still carrying the search match delimiters (⟦ ⟧) for SearchPreview.
/// The title is the first non-blank line; the body is the lines after it. Markdown task, bullet and
/// heading markers become the glyphs a reader expects. When the first match sits deeper than the body's
/// visible lines, the body starts at that line instead, so a card always shows why it matched.
public struct RecallCardText: Equatable, Sendable {
    public let title: String
    public let body: String

    /// Lines of body a card can show; a match on a later line moves the body to it.
    static let visibleBodyLines = 2
    /// Upper bound on lines kept for the body, so a long note never builds a long preview string.
    static let maximumBodyLines = 6

    public init(highlighted text: String) {
        // Delimiters wrap single tokens, so they never cross a line break and lines can be split safely.
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        title = lines.isEmpty ? "" : Self.display(lines.removeFirst())
        var skipped = false
        if let match = lines.firstIndex(where: { $0.contains("⟦") }), match >= Self.visibleBodyLines {
            lines = Array(lines[match...])
            skipped = true
        }
        var shown = lines.prefix(Self.maximumBodyLines).map(Self.display)
        if skipped { shown[0] = "… " + shown[0] }
        body = shown.joined(separator: "\n")
    }

    /// Swaps Markdown line markers for what they mean on screen. Saved text is never changed.
    static func display(_ line: String) -> String {
        for (marker, glyph) in [("- [ ] ", "☐ "), ("* [ ] ", "☐ "), ("- [x] ", "☑ "), ("- [X] ", "☑ "),
                                ("* [x] ", "☑ "), ("* [X] ", "☑ ")] where line.hasPrefix(marker) {
            return glyph + line.dropFirst(marker.count)
        }
        if line.hasPrefix("- ") || line.hasPrefix("* ") { return "• " + line.dropFirst(2) }
        // A heading's hashes say "this is a title"; on a card the position already says that.
        for marker in ["### ", "## ", "# "] where line.hasPrefix(marker) {
            return String(line.dropFirst(marker.count))
        }
        return line
    }
}
