/* Mac XCUITest journey for the real floating pill and shared WorkspaceView.
 MindMachinePillUITests in native-ci clicks/types through accessibility; the
 existing PillSelfTest separately checks App Sandbox, window flags and timing. */
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

    // macOS SwiftUI StaticText exposes displayed text as AXValue. The failure
    // bundle confirms save-status has this value and an empty accessibility label.
    private func expectText(_ element: XCUIElement, _ text: String, file: StaticString = #filePath, line: UInt = #line) {
        let matches = NSPredicate(format: "value == %@", text)
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: matches, object: element)], timeout: 5) == .completed,
                      "Expected \(text.debugDescription), got \(String(describing: element.value))", file: file, line: line)
    }
}
