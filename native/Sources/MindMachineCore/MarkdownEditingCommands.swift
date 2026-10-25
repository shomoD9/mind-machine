/* Pure line-local Markdown edit plans, called only for command keys by
 MarkdownCaptureTextView through MacMarkdownEditingCommands. SwiftPM tests
 exercise this portable boundary on Linux; offsets are UTF-16, as in TextKit. */
import Foundation

public enum MarkdownEditingCommands {
    public enum Command { case newline, indent, outdent, toggleTask }
    public struct Edit {
        public let range: NSRange
        public let replacement: String
    }
    public struct Plan {
        /// Non-overlapping edits in ascending source order; apply in reverse.
        public let edits: [Edit]
        public let selection: NSRange
    }

    /// A nil plan leaves the command to the platform's normal text handling.
    public static func plan(line: String, selection: NSRange, command: Command) -> Plan? {
        let source = line as NSString
        guard selection.location >= 0, selection.length >= 0,
              selection.location <= source.length,
              selection.length <= source.length - selection.location,
              !line.contains("\n"), !line.contains("\r") else { return nil }
        // Native selections must not split UTF-16 surrogate pairs. No source
        // reconstruction or Unicode normalization occurs when planning edits.
        func boundary(_ offset: Int) -> Bool {
            offset == 0 || offset == source.length || !(0xDC00...0xDFFF).contains(source.character(at: offset))
        }
        guard boundary(selection.location), boundary(NSMaxRange(selection)) else { return nil }
        var indent = 0
        while indent < source.length, source.character(at: indent) == 32 { indent += 1 }
        guard let marker = marker(in: source, at: indent) else { return nil }
        func result(_ range: NSRange, _ replacement: String, _ caret: NSRange) -> Plan {
            Plan(edits: [Edit(range: range, replacement: replacement)], selection: caret)
        }
        switch command {
        case .newline:
            guard selection.location >= marker.end else { return nil }
            // Empty items become a plain indented line without adding a newline.
            if source.substring(from: marker.end).allSatisfy({ $0 == " " || $0 == "\t" }) {
                return result(NSRange(location: indent, length: source.length - indent), "",
                              NSRange(location: indent, length: 0))
            }
            let insertion = "\n" + String(repeating: " ", count: indent) + marker.next
            return result(selection, insertion,
                          NSRange(location: selection.location + (insertion as NSString).length, length: 0))
        case .indent:
            return result(NSRange(location: 0, length: 0), "  ",
                          NSRange(location: selection.location + 2, length: selection.length))
        case .outdent:
            let count = min(2, indent)
            guard count > 0 else { return Plan(edits: [], selection: selection) }
            let start = max(0, selection.location - count)
            let end = max(0, NSMaxRange(selection) - count)
            return result(NSRange(location: 0, length: count), "", NSRange(location: start, length: end - start))
        case .toggleTask:
            guard let check = marker.check else { return nil }
            return result(NSRange(location: check, length: 1), source.character(at: check) == 32 ? "x" : " ", selection)
        }
    }

    // Prefix recognition is intentionally local: spaces, two bullet spellings,
    // explicit dash tasks and decimal ordered markers. Quote/code context and
    // cross-line container parsing belong to other tickets.
    private struct Marker {
        let end: Int
        let next: String
        var check: Int? = nil
    }
    private static func marker(in source: NSString, at indent: Int) -> Marker? {
        let tail = source.substring(from: indent)
        if tail.hasPrefix("- [ ] ") || tail.hasPrefix("- [x] ") {
            return Marker(end: indent + 6, next: "- [ ] ", check: indent + 3)
        }
        if tail.hasPrefix("- ") || tail.hasPrefix("* ") {
            return Marker(end: indent + 2, next: String(tail.prefix(2)))
        }
        var end = indent
        while end < source.length, (48...57).contains(source.character(at: end)), end - indent < 9 { end += 1 }
        guard end > indent, end + 1 < source.length,
              source.character(at: end) == 46, source.character(at: end + 1) == 32,
              let number = Int(source.substring(with: NSRange(location: indent, length: end - indent))) else { return nil }
        return Marker(end: end + 2, next: "\(number + 1). ")
    }
}
