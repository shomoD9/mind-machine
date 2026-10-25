/* Mac XCUITest journey for the real floating pill and shared WorkspaceView.
 MindMachinePillUITests in native-ci clicks/types through accessibility; the
 existing PillSelfTest separately checks App Sandbox, window flags and timing. The Capture page has
 no formatting buttons (WorkspaceView/RichNoteEditor); the journey asserts they stay absent. A second
 journey saves clearly fake "[Sample]" notes and checks that Recall lays matches out as equal cards two
 wide (RecallCards.swift), that the arrow keys and Return work from the query (RecallGrid.swift), and
 that the empty state and the Open tasks filter still behave. */
import XCTest

final class PillAcceptanceTests: XCTestCase {
    func testPillCaptureRecallRoundTrip() {
        continueAfterFailure = false
        let app = XCUIApplication()
        // Debug-only entry point: fresh local vault, defaults suite and no sync.
        app.launchArguments = ["--pill-ui-test", UUID().uuidString]
        app.launch()
        defer {
            if testRun?.hasSucceeded == false {
                let image = XCTAttachment(screenshot: app.screenshot())
                image.lifetime = .keepAlways
                add(image)
                let tree = XCTAttachment(string: app.debugDescription)
                tree.lifetime = .keepAlways
                add(tree)
            }
            app.terminate()
        }

        let pill = app.buttons["pill-open"]
        XCTAssertTrue(pill.waitForExistence(timeout: 10))
        pill.click()
        let editor = app.textViews["capture-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        // Capture is a plain page: the former Bold/Italic/bullet/checkbox row must not come back, and
        // the quiet sync glyph that replaced the "Sync setup" button still offers sync details.
        for removed in ["format-bold", "format-italic", "format-bullet", "format-checkbox"] {
            XCTAssertFalse(app.buttons[removed].exists, "\(removed) should not be in the Capture window")
        }
        XCTAssertTrue(app.buttons["sync-setup"].exists)
        editor.click()
        editor.typeText("Tonight telescope code 7319")
        app.buttons["save-capture"].click()
        expectText(app.staticTexts["save-status"], "Saved on this device")

        // Save via the actual button, query via the actual field, inspect the
        // original via its result. No model calls or filesystem assertions.
        app.buttons["pill-mode-1"].click()
        let query = app.textFields["recall-query"]
        XCTAssertTrue(query.waitForExistence(timeout: 5))
        query.click()
        query.typeText("teles")
        let result = app.buttons["capture-result"]
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(identifier: "capture-result").count, 1)
        result.click()
        expectText(app.staticTexts["original-text"], "Tonight telescope code 7319")
        app.buttons["back-to-recall"].click()
        app.buttons["pill-close"].click()
        XCTAssertTrue(pill.waitForExistence(timeout: 5))
    }

    func testRecallShowsMatchesAsTwoColumnCards() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--pill-ui-test", UUID().uuidString]
        app.launch()
        defer {
            if testRun?.hasSucceeded == false {
                let tree = XCTAttachment(string: app.debugDescription)
                tree.lifetime = .keepAlways
                add(tree)
            }
            app.terminate()
        }

        let pill = app.buttons["pill-open"]
        XCTAssertTrue(pill.waitForExistence(timeout: 10))
        pill.click()
        let editor = app.textViews["capture-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        // Typed and saved like any note; the last one is a Markdown task line.
        for note in ["[Sample] Garden plan for spring", "[Sample] Garden shed repair quote",
                     "[Sample] Garden party guest list", "- [ ] [Sample] Buy garden twine"] {
            editor.click()
            editor.typeText(note)
            app.buttons["save-capture"].click()
            // The acknowledgement hides while a note is being written and returns once it is saved.
            expectText(app.staticTexts["save-status"], "Saved on this device")
        }

        app.buttons["pill-mode-1"].click()
        let query = app.textFields["recall-query"]
        XCTAssertTrue(query.waitForExistence(timeout: 5))
        query.click()
        query.typeText("garden")
        let results = app.buttons.matching(identifier: "capture-result")
        XCTAssertTrue(results.element(boundBy: 3).waitForExistence(timeout: 5))
        XCTAssertEqual(results.count, 4)

        // Two columns filled row by row, every card the same size.
        var cards = sortedCards(app)
        let frames = cards.map(\.frame)
        XCTAssertEqual(frames[0].minY, frames[1].minY, accuracy: 1)
        XCTAssertLessThan(frames[0].maxX, frames[1].minX)
        XCTAssertGreaterThanOrEqual(frames[2].minY, frames[0].maxY)
        XCTAssertEqual(frames[2].minX, frames[0].minX, accuracy: 1)
        XCTAssertEqual(frames[3].minX, frames[1].minX, accuracy: 1)
        XCTAssertEqual(frames[3].minY, frames[2].minY, accuracy: 1)
        for frame in frames {
            XCTAssertEqual(frame.width, frames[0].width, accuracy: 1)
            XCTAssertEqual(frame.height, frames[0].height, accuracy: 1)
        }
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "Recall cards with sample notes"
        image.lifetime = .keepAlways
        add(image)

        // Learn which note sits in each grid position by clicking it.
        var texts: [String] = []
        for index in 0..<4 {
            cards[index].click()
            texts.append(openedText(app))
            back(app)
            cards = sortedCards(app)
        }
        XCTAssertEqual(Set(texts).count, 4)

        // A fresh query starts with no card selected. Down, Right, Down reaches the bottom-right card.
        query.click()
        query.typeKey("a", modifierFlags: .command)
        query.typeText("garden")
        XCTAssertTrue(results.element(boundBy: 3).waitForExistence(timeout: 5))
        for key in [XCUIKeyboardKey.downArrow, .rightArrow, .downArrow, .return] { query.typeKey(key, modifierFlags: []) }
        XCTAssertEqual(openedText(app), texts[3])
        back(app)
        // The selection survives the reader: Up moves to the card above it.
        query.click()
        for key in [XCUIKeyboardKey.upArrow, .return] { query.typeKey(key, modifierFlags: []) }
        XCTAssertEqual(openedText(app), texts[1])
        back(app)
        // Up from the top row returns to the query, and Return there opens the first match.
        query.click()
        for key in [XCUIKeyboardKey.upArrow, .upArrow, .return] { query.typeKey(key, modifierFlags: []) }
        XCTAssertEqual(openedText(app), texts[0])
        back(app)

        // No matches still reads "Nothing found yet".
        query.click()
        query.typeKey("a", modifierFlags: .command)
        query.typeText("xylophone")
        XCTAssertTrue(app.staticTexts["recall-empty"].waitForExistence(timeout: 5))
        XCTAssertEqual(results.count, 0)

        // Open tasks keeps only the unfinished task note, still as a card.
        query.typeKey("a", modifierFlags: .command)
        query.typeText("garden")
        XCTAssertTrue(results.element(boundBy: 3).waitForExistence(timeout: 5))
        let toggle = app.descendants(matching: .any).matching(identifier: "open-tasks-toggle").firstMatch
        XCTAssertTrue(toggle.exists)
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).click()
        let one = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 1"), object: results)
        XCTAssertEqual(XCTWaiter.wait(for: [one], timeout: 5), .completed, "Open tasks should leave one card, found \(results.count)")
        results.element(boundBy: 0).click()
        XCTAssertEqual(openedText(app), "- [ ] [Sample] Buy garden twine")
    }

    /// Result cards in reading order (top to bottom, then left to right), independent of accessibility order.
    private func sortedCards(_ app: XCUIApplication) -> [XCUIElement] {
        let results = app.buttons.matching(identifier: "capture-result")
        return (0..<results.count).map { results.element(boundBy: $0) }.sorted { a, b in
            let (first, second) = (a.frame, b.frame)
            return abs(first.minY - second.minY) > 1 ? first.minY < second.minY : first.minX < second.minX
        }
    }

    /// The text of the note open in the reader.
    private func openedText(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) -> String {
        let original = app.staticTexts["original-text"]
        XCTAssertTrue(original.waitForExistence(timeout: 5), "No note opened", file: file, line: line)
        return original.value as? String ?? ""
    }

    private func back(_ app: XCUIApplication) {
        app.buttons["back-to-recall"].click()
        XCTAssertTrue(app.buttons.matching(identifier: "capture-result").firstMatch.waitForExistence(timeout: 5))
    }

    // macOS SwiftUI StaticText exposes displayed text as AXValue. The failure
    // bundle confirms save-status has this value and an empty accessibility label.
    private func expectText(_ element: XCUIElement, _ text: String, file: StaticString = #filePath, line: UInt = #line) {
        let matches = NSPredicate(format: "value == %@", text)
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: matches, object: element)], timeout: 5) == .completed,
                      "Expected \(text.debugDescription), got \(String(describing: element.value))", file: file, line: line)
    }
}
