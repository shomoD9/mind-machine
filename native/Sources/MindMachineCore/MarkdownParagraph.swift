/* Parses the Capture Markdown subset into disposable UTF-16 style ranges.
 MacMarkdownEditor in MindMachineUI consumes these ranges; portable SwiftPM
 tests exercise them on Linux. This never rewrites or normalizes the source. */
import Foundation

public struct MarkdownParagraph: Equatable {
    public enum Block: Equatable {
        case plain, heading(Int), bullet, task(checked: Bool)
    }
    public enum Style: Equatable { case marker, bold, italic, link }
    public struct Span: Equatable {
        public let range: NSRange
        public let style: Style
    }

    // Bound synchronous work, including adversarial delimiters and huge lines.
    // Larger paragraphs remain readable source, without partial formatting.
    public static let maximumUTF16Length = 8_192
    public let block: Block
    public let spans: [Span]

    public init(_ source: String) {
        guard source.utf16.count <= Self.maximumUTF16Length else {
            block = .plain; spans = []; return
        }
        let units = Array(source.utf16)
        var result: [Span] = []
        func span(_ start: Int, _ count: Int, _ style: Style) {
            if count > 0 { result.append(Span(range: NSRange(location: start, length: count), style: style)) }
        }
        var prefix = 0
        if source.hasPrefix("- [ ] ") || source.hasPrefix("- [x] ") {
            block = .task(checked: source.hasPrefix("- [x] ")); prefix = 6
        } else if source.hasPrefix("- ") {
            block = .bullet; prefix = 2
        } else {
            let hashes = units.prefix(while: { $0 == 35 }).count
            if (1...3).contains(hashes), units.count > hashes, units[hashes] == 32 {
                block = .heading(hashes); prefix = hashes + 1
            } else { block = .plain }
        }
        span(0, prefix, .marker)
        // Fenced/indented line starts are left plain. Cross-paragraph fence and
        // container context belongs to ticket 3; no context cache is implied here.
        if source.hasPrefix("```") || source.hasPrefix("~~~") || source.hasPrefix("    ") || source.hasPrefix("\t") {
            spans = []; return
        }

        func whitespace(_ unit: UInt16) -> Bool { unit == 32 || unit == 9 || unit == 10 || unit == 13 }
        var delimiters: [(start: Int, count: Int)] = []
        var bracket: Int?
        var codeRun = 0
        var index = prefix
        while index < units.count {
            // Escaped punctuation stays source. Skipping a UTF-16 code unit is
            // safe here: only ASCII punctuation participates in recognition.
            if units[index] == 92 { index = min(index + 2, units.count); continue }
            if units[index] == 96 {
                var end = index + 1
                while end < units.count, units[end] == 96 { end += 1 }
                let count = end - index
                if codeRun == 0 { codeRun = count } else if codeRun == count { codeRun = 0 }
                index = end; continue
            }
            if codeRun > 0 { index += 1; continue }
            if units[index] == 91 { bracket = index }
            if units[index] == 93, let opening = bracket, index > opening + 1,
               index + 1 < units.count, units[index + 1] == 40 {
                // Balance destination parentheses and skip escaped ones. A
                // failed destination scan ends the line's link attempt, keeping
                // total work linear even for repeated malformed link prefixes.
                var end = index + 2, depth = 1
                while end < units.count, depth > 0, !whitespace(units[end]) {
                    if units[end] == 92 { end = min(end + 2, units.count); continue }
                    if units[end] == 40 { depth += 1 }
                    if units[end] == 41 { depth -= 1 }
                    if depth > 0 { end += 1 }
                }
                if depth == 0, end > index + 2 {
                    span(opening, 1, .marker)
                    span(opening + 1, index - opening - 1, .link)
                    span(index, end - index + 1, .marker)
                    bracket = nil; index = end + 1; continue
                }
                bracket = nil
                index = max(index + 1, end); continue
            }
            if units[index] == 42 {
                var end = index + 1
                while end < units.count, units[end] == 42 { end += 1 }
                let count = end - index
                if count <= 3 {
                    let canClose = index > prefix && !whitespace(units[index - 1])
                    let canOpen = end < units.count && !whitespace(units[end])
                    if canClose, let opening = delimiters.last, opening.count == count {
                        delimiters.removeLast()
                        span(opening.start, count, .marker); span(index, count, .marker)
                        if count >= 2 { span(opening.start + count, index - opening.start - count, .bold) }
                        if count == 1 || count == 3 { span(opening.start + count, index - opening.start - count, .italic) }
                    } else if canOpen { delimiters.append((index, count)) }
                }
                index = end; continue
            }
            index += 1
        }
        spans = result
    }
}
