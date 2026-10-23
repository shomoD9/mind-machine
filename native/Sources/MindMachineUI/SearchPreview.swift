/* Formats FTS5 match delimiters for shared SwiftUI results. WorkspaceView calls
 this for previews; copy/insert always use the separately retained original. */
import SwiftUI

enum SearchPreview {
    static func attributed(_ text: String) -> AttributedString {
        var result = AttributedString()
        var matching = false
        var buffer = ""
        // A bounded preview avoids constructing styled copies of long essays.
        for character in text.prefix(500) {
            if character == "⟦" || character == "⟧" {
                var part = AttributedString(buffer)
                if matching { part.font = .body.bold() }
                result.append(part); buffer = ""
                matching = character == "⟦"
            } else { buffer.append(character) }
        }
        var part = AttributedString(buffer)
        if matching { part.font = .body.bold() }
        result.append(part)
        return result
    }
}
