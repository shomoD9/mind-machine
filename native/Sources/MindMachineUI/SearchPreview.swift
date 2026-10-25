/* Formats FTS5 match delimiters for shared SwiftUI results. WorkspaceView calls
 this for the iPhone result rows and RecallCard (RecallCards.swift) for the Mac card
 title and body; copy/insert always use the separately retained original. */
import SwiftUI

enum SearchPreview {
    /// `matchFont` and `matchColor` style the matched words; a card body passes a heavier weight and
    /// full ink so its matches stand out against secondary-ink text.
    static func attributed(_ text: String, matchFont: Font = .body.bold(), matchColor: Color? = nil) -> AttributedString {
        var result = AttributedString()
        var matching = false
        var buffer = ""
        func flush() {
            var part = AttributedString(buffer)
            if matching {
                part.font = matchFont
                if let matchColor { part.foregroundColor = matchColor }
            }
            result.append(part); buffer = ""
        }
        // A bounded preview avoids constructing styled copies of long essays.
        for character in text.prefix(500) {
            if character == "⟦" || character == "⟧" {
                flush()
                matching = character == "⟦"
            } else { buffer.append(character) }
        }
        flush()
        return result
    }
}
