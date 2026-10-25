/* Portable Capture-subset parsing checks, run by SwiftPM and Linux fast-core.
 MacMarkdownEditorTests separately verifies these ranges on real text storage. */
import XCTest
@testable import MindMachineCore

final class MarkdownParagraphTests: XCTestCase {
    func testPrefixesBecomeStylesOnlyWhenComplete() {
        for level in 1...3 {
            let hashes = String(repeating: "#", count: level)
            XCTAssertEqual(MarkdownParagraph(hashes).block, .plain)
            let parsed = MarkdownParagraph(hashes + " ")
            XCTAssertEqual(parsed.block, .heading(level))
            XCTAssertEqual(parsed.spans.first?.range, NSRange(location: 0, length: level + 1))
        }
        XCTAssertEqual(MarkdownParagraph("#### title").block, .plain)
        XCTAssertEqual(MarkdownParagraph(" # title").block, .plain)
        XCTAssertEqual(MarkdownParagraph("- ").block, .bullet)
        XCTAssertEqual(MarkdownParagraph("- [ ] ").block, .task(checked: false))
        XCTAssertEqual(MarkdownParagraph("- [x] done").block, .task(checked: true))
        XCTAssertEqual(MarkdownParagraph("- [").block, .bullet)
        XCTAssertEqual(MarkdownParagraph("- [x] ").spans.first?.range.length, 6)
        XCTAssertEqual(MarkdownParagraph("-word").block, .plain)
    }

    func testUnicodeRangesAddressTheExactSourceWithoutNormalization() {
        let source = "👩🏽‍💻 e\u{301} **cafe\u{301}** *星* [🔭](https://example.org/a(b))"
        let parsed = MarkdownParagraph(source)
        let string = source as NSString
        func contents(_ style: MarkdownParagraph.Style) -> [String] {
            parsed.spans.filter { $0.style == style }.map { string.substring(with: $0.range) }
        }
        XCTAssertEqual(contents(.bold).map { Data($0.utf8) }, [Data("cafe\u{301}".utf8)])
        XCTAssertEqual(contents(.italic), ["星"])
        XCTAssertEqual(contents(.link), ["🔭"])
        XCTAssertEqual(contents(.marker), ["**", "**", "*", "*", "[", "](https://example.org/a(b))"])
        XCTAssertEqual(parsed.spans.first(where: { $0.style == .bold })?.range,
                       string.range(of: "cafe\u{301}"))
        XCTAssertTrue(parsed.spans.allSatisfy { NSMaxRange($0.range) <= string.length })
    }

    func testNestedTraitsLinksAndVisibleDelimiters() {
        let source = "**bold *both* bold** and ***three*** [**label**](url)"
        let parsed = MarkdownParagraph(source)
        let string = source as NSString
        let styled = { (style: MarkdownParagraph.Style) in
            parsed.spans.filter { $0.style == style }.map { string.substring(with: $0.range) }
        }
        XCTAssertEqual(styled(.italic), ["both", "three"])
        XCTAssertEqual(styled(.bold), ["bold *both* bold", "three", "label"])
        XCTAssertEqual(styled(.link), ["**label**"])
        XCTAssertEqual(styled(.marker).filter { $0 == "**" }.count, 4)
    }

    func testIncompleteEscapedAndCodeTextStayLiteral() {
        for source in ["**unfinished", "* unfinished*", "[label](", "\\*literal\\*", "`**code**`",
                       "```swift **code**", "    **code**", "\t*code*"] {
            XCTAssertTrue(MarkdownParagraph(source).spans.isEmpty, source)
        }
        let parsed = MarkdownParagraph("`*code*` **live**")
        XCTAssertEqual(parsed.spans.filter { $0.style == .bold }.count, 1)
        XCTAssertEqual(MarkdownParagraph("\\# heading").block, .plain)
    }

    func testLongAndAdversarialParagraphsHaveBoundedWork() {
        let huge = "# " + String(repeating: "**a** ", count: 20_000)
        XCTAssertEqual(MarkdownParagraph(huge).block, .plain)
        XCTAssertTrue(MarkdownParagraph(huge).spans.isEmpty)
        let delimiters = MarkdownParagraph(String(repeating: "*", count: 8_192))
        XCTAssertTrue(delimiters.spans.isEmpty)
        XCTAssertTrue(MarkdownParagraph(String(repeating: "[x](", count: 2_048)).spans.isEmpty)
    }

    func testStyleRangeDiscoveryStopsBeforeScanningHugeParagraphs() {
        // Exercise the same accessor used by the Mac delegate, including a
        // virtual gigabyte paragraph without allocating a gigabyte fixture.
        for length in [110_279, 1_000_000_000] {
            for location in [0, length / 2, length] {
                var reads = 0
                let range = MarkdownStyleRange.affected(by: NSRange(location: location, length: 0), length: length) { _ in
                    reads += 1
                    return 120
                }
                XCTAssertNil(range)
                XCTAssertLessThanOrEqual(reads, MarkdownParagraph.maximumUTF16Length + 2)
            }
        }
        var reads = 0
        XCTAssertNil(MarkdownStyleRange.affected(by: NSRange(location: 0, length: 100_000), length: 100_000) { _ in
            reads += 1; return 120
        })
        XCTAssertEqual(reads, 0, "Bulk input must be rejected before any scanning")
    }

    func testStyleRangeMatchesNativeParagraphBoundaries() {
        for text in ["# first\nplain\n- last", "# a\r\nb\r\nlast", "a\u{2029}b", "👩🏽‍💻 e\u{301}\nnext", "last\n", ""] {
            let source = text as NSString
            for location in 0...source.length {
                for count in 0...min(6, source.length - location) {
                    let edit = NSRange(location: location, length: count)
                    let actual = MarkdownStyleRange.affected(by: edit, length: source.length) { source.character(at: $0) }
                    XCTAssertEqual(actual, source.paragraphRange(for: edit), "\(text.debugDescription) \(edit)")
                }
            }
        }
    }
}
