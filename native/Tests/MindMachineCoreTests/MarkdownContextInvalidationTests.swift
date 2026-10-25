/* Verifies Capture's incremental presentation against independent whole-source
 paragraph parsing. SwiftPM runs this portable seam on Linux and macOS; the Mac
 delegate consumes the same invalidation function with direct storage reads. */
import Foundation
import XCTest
@testable import MindMachineCore

final class MarkdownContextInvalidationTests: XCTestCase {
    // Each UTF-16 unit carries the effective portable presentation. Keeping a
    // mutable array models attributes that survive an edit in NSTextStorage.
    private struct Ink: Equatable {
        var block: MarkdownParagraph.Block = .plain
        var traits: Set<String> = []
    }

    private func paint(_ paragraph: String) -> [Ink] {
        let parsed = MarkdownParagraph(paragraph)
        var ink = Array(repeating: Ink(block: parsed.block), count: (paragraph as NSString).length)
        for span in parsed.spans {
            for index in span.range.location..<NSMaxRange(span.range) {
                ink[index].traits.insert(String(describing: span.style))
            }
        }
        return ink
    }

    // This oracle deliberately uses Foundation's unbounded paragraph discovery,
    // independently of the production invalidator and its bounded accessor.
    private func fullParse(_ text: String) -> [Ink] {
        let source = text as NSString
        var result: [Ink] = [], cursor = 0
        while cursor < source.length {
            let paragraph = source.paragraphRange(for: NSRange(location: cursor, length: 0))
            result += paint(source.substring(with: paragraph))
            cursor = NSMaxRange(paragraph)
        }
        return result
    }

    private func invalidated(_ edit: NSRange, in source: NSString) -> NSRange? {
        MarkdownContextInvalidation.affected(by: edit, length: source.length) { source.character(at: $0) }
    }

    private func apply(_ replacement: String, at edit: NSRange, to text: inout String,
                       ink: inout [Ink], file: StaticString = #filePath, line: UInt = #line) {
        // Patch expected UTF-8 independently of Foundation's UTF-16 replacement.
        // Unicode scalar boundaries allow combining marks to be edited alone.
        var byteOffsets = [0: 0], utf16Offset = 0, utf8Offset = 0
        for scalar in text.unicodeScalars {
            utf16Offset += scalar.value > 0xFFFF ? 2 : 1
            utf8Offset += scalar.utf8.count
            byteOffsets[utf16Offset] = utf8Offset
        }
        let bytes = Array(text.utf8)
        let expectedBytes = Data(bytes[..<byteOffsets[edit.location]!]) + Data(replacement.utf8)
            + Data(bytes[byteOffsets[NSMaxRange(edit)]!...])
        // Linux Foundation replacement rounds some scalar boundaries to whole
        // graphemes. Model NSTextStorage's exact UTF-16 mutation directly so the
        // portable oracle can also edit an isolated combining mark or ZWJ.
        var units = Array(text.utf16)
        units.replaceSubrange(edit.location..<NSMaxRange(edit), with: replacement.utf16)
        text = String(decoding: units, as: UTF16.self)
        ink.replaceSubrange(edit.location..<NSMaxRange(edit),
                            with: Array(repeating: Ink(), count: replacement.utf16.count))
        let source = text as NSString
        let changed = NSRange(location: edit.location, length: replacement.utf16.count)
        if let affected = invalidated(changed, in: source) {
            var cursor = affected.location
            while cursor < NSMaxRange(affected) {
                let paragraph = source.paragraphRange(for: NSRange(location: cursor, length: 0))
                ink.replaceSubrange(paragraph.location..<NSMaxRange(paragraph),
                                    with: paint(source.substring(with: paragraph)))
                cursor = NSMaxRange(paragraph)
            }
        }
        XCTAssertEqual(Data(text.utf8), expectedBytes, file: file, line: line)
        let wanted = fullParse(text)
        XCTAssertEqual(ink.count, wanted.count, file: file, line: line)
        if let index = (0..<min(ink.count, wanted.count)).first(where: { ink[$0] != wanted[$0] }) {
            XCTFail("Style mismatch at UTF-16 unit \(index): \(ink[index]) != \(wanted[index]); edit \(edit) -> \(replacement.debugDescription), source \(text.debugDescription)", file: file, line: line)
        }
    }

    func testNewlineSplitRestylesBothSides() {
        var source = "**bold**", ink = fullParse("**bold**")
        apply("\n", at: NSRange(location: 4, length: 0), to: &source, ink: &ink)
        XCTAssertEqual(invalidated(NSRange(location: 4, length: 1), in: source as NSString),
                       NSRange(location: 0, length: 9))
    }

    func testNewlineJoinRestylesBothSides() {
        var source = "**bo\nld**\n# last", ink = fullParse("**bo\nld**\n# last")
        apply("", at: NSRange(location: 4, length: 1), to: &source, ink: &ink)
        XCTAssertTrue(ink[3].traits.contains("bold"))
        XCTAssertEqual(invalidated(NSRange(location: 4, length: 0), in: source as NSString),
                       NSRange(location: 0, length: 9))
    }

    func testIndentChangesReclassifyListTaskAndCodeWithoutTouchingNeighbours() {
        for original in ["- **item**", "- [ ] *task*", "- [x] [done](url)"] {
            var source = "# before\n" + original + "\n# after", ink = fullParse("# before\n" + original + "\n# after")
            for indent in [" ", "   ", "\t"] {
                let oldLength = (source as NSString).paragraphRange(for: NSRange(location: 9, length: 0)).length
                apply(indent, at: NSRange(location: 9, length: 0), to: &source, ink: &ink)
                let affected = invalidated(NSRange(location: 9, length: indent.utf16.count), in: source as NSString)
                XCTAssertEqual(affected, NSRange(location: 9, length: oldLength + indent.utf16.count))
                apply("", at: NSRange(location: 9, length: indent.utf16.count), to: &source, ink: &ink)
            }
        }
    }

    func testEverySplitAndJoinAcrossRecognisedSyntaxAndUnicode() {
        let fixtures = ["# **cafe\u{301} 👩🏽‍💻**", "- [ ] *星* [🔭](url)",
                        "***both***", "[**label**](a(b))", "\\*literal* `**code**`",
                        "## e\u{301}\r\n- item\u{2029}tail"]
        for fixture in fixtures {
            // Scalar boundaries include positions inside a combining sequence,
            // but never split a surrogate pair into invalid Unicode.
            for location in scalarBoundaries(fixture) {
                for separator in ["\n", "\r", "\r\n", "\u{2029}"] {
                    var source = fixture, ink = fullParse(fixture)
                    apply(separator, at: NSRange(location: location, length: 0), to: &source, ink: &ink)
                    apply("", at: NSRange(location: location, length: separator.utf16.count), to: &source, ink: &ink)
                    XCTAssertEqual(Data(source.utf8), Data(fixture.utf8))
                }
            }
        }
    }

    func testPasteReplacementDeletionAndDocumentEdgesMatchFullParse() {
        for replacement in ["\n", "\n# new\n- [ ] **task**\n", "\r\n", "", "👩🏽‍💻e\u{301}\n"] {
            let fixture = "# before\n**bold**\n- [x] *after*\n"
            for location in [0, 9, 13, 17, fixture.utf16.count] {
                for count in [0, min(6, fixture.utf16.count - location), fixture.utf16.count - location] {
                    var source = fixture, ink = fullParse(fixture)
                    apply(replacement, at: NSRange(location: location, length: count), to: &source, ink: &ink)
                }
            }
        }
    }

    func testFenceAndReferenceLookingLinesRetainTheCurrentLiteralSubset() {
        // There is intentionally no fenced-block state or reference resolution.
        // Edits to these lines must agree with today's full parser, including
        // ordinary emphasis on adjacent lines and literal reference-only links.
        var source = "```\n**outside**\n```\n[label][id]\n[id]: destination\n~~~\n*tail*"
        var ink = fullParse(source)
        XCTAssertTrue(ink[6].traits.contains("bold"))
        for replacement in ["\n", "    ", "~~~", "[id]: elsewhere\n", ""] {
            apply(replacement, at: NSRange(location: 0, length: min(3, source.utf16.count)), to: &source, ink: &ink)
        }
    }

    func testOrdinaryTypingReadsAndRestylesOnlyItsParagraphInLargeDocument() {
        let text = String(repeating: "# untouched\n", count: 10_000) + "- **target**\n" + String(repeating: "tail\n", count: 10_000)
        let source = text as NSString
        var reads = 0
        let range = MarkdownContextInvalidation.affected(by: NSRange(location: 120_005, length: 1), length: source.length) {
            XCTAssertTrue((119_999...120_013).contains($0), "Read an unrelated paragraph at \($0)")
            reads += 1
            return source.character(at: $0)
        }
        XCTAssertEqual(range, NSRange(location: 120_000, length: 13))
        XCTAssertLessThanOrEqual(reads, 16)
    }

    func testOversizedParagraphAndBulkInputKeepBoundedNativeFallback() {
        for length in [110_279, 1_000_000_000] {
            for location in [0, length / 2, length] {
                var reads = 0
                XCTAssertNil(MarkdownContextInvalidation.affected(by: NSRange(location: location, length: 0), length: length) { _ in
                    reads += 1; return 120
                })
                XCTAssertLessThanOrEqual(reads, MarkdownParagraph.maximumUTF16Length + 2)
            }
        }
        var reads = 0
        XCTAssertNil(MarkdownContextInvalidation.affected(by: NSRange(location: 0, length: 100_000), length: 100_000) { _ in
            reads += 1; return 120
        })
        XCTAssertEqual(reads, 0)
        let exact = String(repeating: "x", count: 8_191) + "\n"
        XCTAssertEqual(invalidated(NSRange(location: 0, length: 1), in: exact as NSString)?.length, 8_192)
        XCTAssertNil(invalidated(NSRange(location: 0, length: 1), in: ("x" + exact) as NSString))
    }

    func testSeededRandomEditSequencesMatchFullParseAndExactSourceBytes() {
        let fragments = ["a", "**bold**", "*i*", "***both***", "# ", "- ", "- [ ] ", "- [x] ",
                         "\n", "\r", "\r\n", "\u{2029}", " ", "    ", "\t", "[🔭](url)",
                         "👩🏽‍💻", "e\u{301}", "é", "星", "\\*", "`", "```", "~~~", "[id]: url", "[x][id]"]
        for seed in 1...12 {
            var state = UInt64(seed)
            func next(_ upperBound: Int) -> Int {
                state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                return Int((state >> 32) % UInt64(upperBound))
            }
            var source = "# e\u{301} 👩🏽‍💻\n- [ ] **task**\n[link](url)\r\n", ink = fullParse(source)
            for _ in 0..<400 {
                let boundaries = scalarBoundaries(source)
                let start = next(boundaries.count)
                let end = min(boundaries.count - 1, start + next(min(12, boundaries.count - start)))
                let replacement = next(4) == 0 ? "" : fragments[next(fragments.count)]
                apply(replacement, at: NSRange(location: boundaries[start], length: boundaries[end] - boundaries[start]),
                      to: &source, ink: &ink)
            }
        }
    }

    private func scalarBoundaries(_ text: String) -> [Int] {
        var offsets = [0], cursor = 0
        for scalar in text.unicodeScalars {
            cursor += scalar.value > 0xFFFF ? 2 : 1
            offsets.append(cursor)
        }
        return offsets
    }

}
