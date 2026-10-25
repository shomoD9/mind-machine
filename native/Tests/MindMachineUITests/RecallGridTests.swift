/* Checks the pure Recall card rules in RecallGrid.swift: arrow-key movement through the two-column
 result grid and how a highlighted preview becomes a card's title and body. SwiftPM runs these in the
 native-ci package-tests job; the Mac self-test and PillAcceptanceTests drive the same rules through
 the real query field. */
import XCTest
import MindMachineUI

final class RecallGridTests: XCTestCase {
    // Five cards in two columns:  0 1 / 2 3 / 4 .
    func testArrowKeysMoveThroughTheGridRowByRow() {
        func move(_ from: Int?, _ direction: RecallGrid.Direction, count: Int = 5) -> RecallGrid.Outcome {
            RecallGrid.move(from: from, direction, count: count)
        }
        // From the query, Down enters at the first card; Left/Right/Up stay with the caret.
        XCTAssertEqual(move(nil, .down), .select(0))
        XCTAssertEqual(move(nil, .up), .ignored)
        XCTAssertEqual(move(nil, .left), .ignored)
        XCTAssertEqual(move(nil, .right), .ignored)
        // Left/Right follow reading order and stop at the ends.
        XCTAssertEqual(move(0, .right), .select(1))
        XCTAssertEqual(move(1, .right), .select(2))
        XCTAssertEqual(move(4, .right), .select(4))
        XCTAssertEqual(move(2, .left), .select(1))
        XCTAssertEqual(move(0, .left), .select(0))
        // Up/Down keep the column; Up from the first row returns to the query.
        XCTAssertEqual(move(0, .down), .select(2))
        XCTAssertEqual(move(1, .down), .select(3))
        XCTAssertEqual(move(3, .up), .select(1))
        XCTAssertEqual(move(1, .up), .field)
        XCTAssertEqual(move(0, .up), .field)
        // Down into a shorter last row lands on its last card; Down on the last row stays.
        XCTAssertEqual(move(3, .down), .select(4))
        XCTAssertEqual(move(2, .down), .select(4))
        XCTAssertEqual(move(4, .down), .select(4))
        // A full last row keeps the column, and a single card is its own last row.
        XCTAssertEqual(move(1, .down, count: 4), .select(3))
        XCTAssertEqual(move(2, .down, count: 4), .select(2))
        XCTAssertEqual(move(0, .down, count: 1), .select(0))
        // No results: every key stays with the query. A stale index is treated as no selection.
        XCTAssertEqual(move(nil, .down, count: 0), .ignored)
        XCTAssertEqual(move(7, .right), .ignored)
        XCTAssertEqual(move(7, .down), .select(0))
    }

    func testCardTitleIsTheFirstLineAndTheBodyKeepsTheMatches() {
        let card = RecallCardText(highlighted: "\n# [Sample] ⟦Garden⟧ plan\n\nMove the tomatoes\n- [ ] Buy ⟦garden⟧ twine\n- [x] Call Sam\n- Seeds")
        XCTAssertEqual(card.title, "[Sample] ⟦Garden⟧ plan")
        XCTAssertEqual(card.body, "Move the tomatoes\n☐ Buy ⟦garden⟧ twine\n☑ Call Sam\n• Seeds")
        let single = RecallCardText(highlighted: "Tonight ⟦telescope⟧ code 7319")
        XCTAssertEqual(single.title, "Tonight ⟦telescope⟧ code 7319")
        XCTAssertEqual(single.body, "")
        XCTAssertEqual(RecallCardText(highlighted: "").title, "")
    }

    // A match below the lines a card can show moves the body to that line, marked with an ellipsis.
    func testBodyStartsAtADeepMatchSoTheCardShowsWhyItMatched() {
        let card = RecallCardText(highlighted: "[Sample] Week\none\ntwo\nthree has ⟦fern⟧\nfour")
        XCTAssertEqual(card.title, "[Sample] Week")
        XCTAssertEqual(card.body, "… three has ⟦fern⟧\nfour")
        let shallow = RecallCardText(highlighted: "[Sample] Week\none\ntwo ⟦fern⟧\nthree")
        XCTAssertEqual(shallow.body, "one\ntwo ⟦fern⟧\nthree")
        let long = RecallCardText(highlighted: "T\n" + (1...20).map { "line \($0)" }.joined(separator: "\n"))
        XCTAssertEqual(long.body.split(separator: "\n").count, 6)
    }
}
