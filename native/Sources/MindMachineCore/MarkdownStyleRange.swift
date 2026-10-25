/* Bounds the Capture styler's paragraph discovery before it reads source.
 MacMarkdownEditor calls this with NSTextStorage's character accessor so ordinary
 typing never copies or scans the document. Portable tests count those reads. */
import Foundation

public enum MarkdownStyleRange {
    /// Nil means the affected paragraphs exceed the synchronous styling budget.
    /// The caller leaves native attributes alone until a bounded paragraph edit.
    public static func affected(by edit: NSRange, length: Int,
                                characterAt: (Int) -> UInt16) -> NSRange? {
        let limit = MarkdownParagraph.maximumUTF16Length
        let location = min(edit.location, length)
        guard edit.length <= limit else { return nil }
        var start = location
        let count = min(edit.length, length - location)
        var end = location + max(0, count - 1)
        func separator(_ unit: UInt16) -> Bool { unit == 10 || unit == 13 || unit == 0x2029 }

        // Search outward with a shared span budget. CRLF is one separator,
        // including when an insertion or deletion lands between its code units.
        while start > 0 {
            let previous = characterAt(start - 1)
            if separator(previous) {
                if previous != 13 || start == length || characterAt(start) != 10 { break }
            }
            start -= 1
            if end - start > limit { return nil }
        }
        while end < length {
            let unit = characterAt(end)
            end += 1
            if end - start > limit { return nil }
            if separator(unit) {
                if unit == 13, end < length, characterAt(end) == 10 { end += 1 }
                return end - start <= limit ? NSRange(location: start, length: end - start) : nil
            }
        }
        return NSRange(location: start, length: end - start)
    }
}
