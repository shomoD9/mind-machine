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
        MarkdownStyleRange.affected(by: edit, length: source.length) { source.character(at: $0) }
    }

    private func apply(_ replacement: String, at edit: NSRange, to text: inout String,
                       ink: inout [Ink], file: StaticString = #filePath, line: UInt = #line) {
        // Patch expected UTF-8 independently of Foundation's UTF-16 replacement.
        // Unicode scalar boundaries allow combining marks to be edited alone.
        let before = text as NSString
        let prefix = before.substring(to: edit.location)
        let suffix = before.substring(from: NSMaxRange(edit))
        let expectedBytes = Data(prefix.utf8) + Data(replacement.utf8) + Data(suffix.utf8)
        text = before.replacingCharacters(in: edit, with: replacement)
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
        XCTAssertEqual(ink, fullParse(text), "edit \(edit) -> \(replacement.debugDescription), source \(text.debugDescription)",
                       file: file, line: line)
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
}
