/* XCUITest acceptance for the production keyboard embedded by KeyboardTestHost.
 MindMachineKeyboardUITests in native-ci drives controls and reads visible text;
 no test reads the vault database or substitutes Capture/Recall operations. */
import XCTest

final class KeyboardAcceptanceTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Each test owns a fresh directory; relaunch within a test reuses it.
        app.launchArguments = ["--vault-id", UUID().uuidString]
        app.launch()
    }

    override func tearDownWithError() throws {
        if testRun?.hasSucceeded == false {
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.lifetime = .keepAlways
            add(screenshot)
            let tree = XCTAttachment(string: app.debugDescription)
            tree.lifetime = .keepAlways
            add(tree)
        }
        app.terminate()
    }

    func testCaptureRecallInsertAndRelaunch() {
        let editor = app.textViews["keyboard-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10), "Production keyboard must appear in the host")
        editor.tap()
        editor.typeText("Tonight telescope code 7319")
        app.buttons["keyboard-save"].tap()
        expectLabel(app.staticTexts["keyboard-status"], "Saved on this device")
        expectValue(app.textViews["host-composer"], "host draft stays here")
        expectValue(editor, "")

        // Prefix and transposition queries must find the exact saved original;
        // an unrelated query must hide it, proving results follow the query.
        selectMode("Recall")
        editor.tap()
        typeQuery("teles")
        let result = app.buttons["keyboard-result"]
        expectResult(result)
        replaceQuery("zz")
        XCTAssertTrue(app.staticTexts["keyboard-results-empty"].waitForExistence(timeout: 5))
        XCTAssertFalse(result.exists)
        replaceQuery("telescpoe")
        expectResult(result)
        result.tap()
        expectValue(editor, "Tonight telescope code 7319")
        expectValue(app.textViews["host-composer"], "host draft stays here")

        // Inspecting never inserts. Only the explicit action changes the host.
        app.buttons["keyboard-insert-original"].tap()
        expectValue(app.textViews["host-composer"], "host draft stays hereTonight telescope code 7319")
        expectLabel(app.staticTexts["keyboard-status"], "Inserted original into app")

        // Terminate the process, then recall through the UI with the same vault
        // UUID. Nothing seeds or reads the database from the test runner.
        app.terminate()
        app.launch()
        XCTAssertTrue(app.textViews["keyboard-editor"].waitForExistence(timeout: 10))
        selectMode("Recall")
        app.textViews["keyboard-editor"].tap()
        typeQuery("teles")
        expectResult(app.buttons["keyboard-result"])
        app.buttons["keyboard-result"].tap()
        expectValue(app.textViews["keyboard-editor"], "Tonight telescope code 7319")
    }

    func testModeAndSizePreserveBothDraftsAndTypingDestination() {
        let editor = app.textViews["keyboard-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        editor.tap()
        editor.typeText("unfinished draft")
        selectMode("Recall")
        editor.tap()
        typeQuery("teles")
        cycleSizes(editor: editor, text: "teles", destination: "Typing into: Private search")
        selectMode("Capture")
        expectValue(editor, "unfinished draft")
        cycleSizes(editor: editor, text: "unfinished draft", destination: "Typing into: Private note")
        // Mode buttons can take native hardware-key focus. On-screen keys keep
        // using the preserved route/caret without tapping and moving the caret.
        tapKey("space")
        for key in "survives" { tapKey(String(key)) }
        expectValue(editor, "unfinished draft survives")
        expectValue(app.textViews["host-composer"], "host draft stays here")

        // Repeat the same transitions with the host selected. A visible key
        // proves input still reaches the host while the private draft survives.
        app.buttons["typing-destination"].tap()
        cycleSizes(editor: editor, text: "unfinished draft survives", destination: "Typing into: App")
        selectMode("Recall")
        expectValue(editor, "teles")
        expectLabel(app.buttons["typing-destination"], "Typing into: App")
        selectMode("Capture")
        tapKey("x")
        expectValue(app.textViews["host-composer"], "host draft stays herex")
        expectValue(editor, "unfinished draft survives")
    }

    func testOnScreenLettersShiftDeleteNumbersAndReturn() {
        let editor = app.textViews["keyboard-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        editor.tap()
        // These are keyplane taps, never typeText: frozen shift/123 layouts or
        // a broken RoutedTextProxy must fail this test.
        tapKey("a")
        expectValue(editor, "A")
        tapKey("b")
        expectValue(editor, "Ab")
        tapKey("shift")
        tapKey("c")
        expectValue(editor, "AbC")
        tapKey("delete")
        expectValue(editor, "Ab")
        tapKey("123")
        for key in ["7", "3", "1", "9", "."] { tapKey(key) }
        expectValue(editor, "Ab7319.")
        tapKey("abc")
        tapKey("return")
        expectValue(editor, "Ab7319.\n")
        tapKey("d")
        tapKey("space")
        tapKey("e")
        expectValue(editor, "Ab7319.\nD e")
        expectValue(app.textViews["host-composer"], "host draft stays here")
    }

    private func selectMode(_ title: String) {
        app.segmentedControls["keyboard-mode"].buttons[title].tap()
    }

    private func replaceQuery(_ text: String) {
        let editor = app.textViews["keyboard-editor"]
        // Delete through the real keyplane at the retained caret; XCTest's
        // hardware focus is unavailable for this embedded Recall editor.
        let count = (editor.value as? String ?? "").count
        for _ in 0..<count { tapKey("delete") }
        expectValue(editor, "")
        typeQuery(text)
    }

    private func typeQuery(_ text: String) {
        // An empty private editor starts a sentence with shift enabled. Turn it
        // off explicitly so the prefix/typo fixtures are entered exactly as given.
        tapKey("shift")
        var prefix = ""
        for key in text {
            tapKey(String(key))
            prefix.append(key)
            // Observe each completed edit before the next gesture. A missed
            // key fails here; the driver never retries or repairs entered text.
            XCTAssertEqual(app.textViews["keyboard-editor"].value as? String, prefix)
        }
        expectValue(app.textViews["keyboard-editor"], text)
    }

    private func expectResult(_ result: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(result.waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertEqual(app.buttons.matching(identifier: "keyboard-result").count, 1, file: file, line: line)
        XCTAssertTrue(result.label.contains("Tonight telescope code 7319"), result.label, file: file, line: line)
    }

    private func cycleSizes(editor: XCUIElement, text: String, destination: String) {
        for title in ["Size: Expanded", "Size: Min", "Size: Default"] {
            app.buttons["pad-size"].tap()
            expectLabel(app.buttons["pad-size"], title)
            expectValue(editor, text)
            expectLabel(app.buttons["typing-destination"], destination)
        }
    }

    private func tapKey(_ key: String, file: StaticString = #filePath, line: UInt = #line) {
        let element = app.descendants(matching: .any).matching(identifier: "keyboard-key-" + key).firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Missing key \(key)", file: file, line: line)
        // KeyboardKit consumes press/release gestures. An explicit short hold
        // gives SwiftUI both phases while Recall re-renders between characters;
        // it stays below long-press and repeat-delete thresholds.
        element.press(forDuration: 0.12)
    }

    private func expectValue(_ element: XCUIElement, _ text: String, file: StaticString = #filePath, line: UInt = #line) {
        let matches = NSPredicate(format: "value == %@", text)
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: matches, object: element)], timeout: 5) == .completed,
                      "Expected \(text.debugDescription), got \(String(describing: element.value))", file: file, line: line)
    }

    private func expectLabel(_ element: XCUIElement, _ text: String, file: StaticString = #filePath, line: UInt = #line) {
        let matches = NSPredicate(format: "label == %@", text)
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: matches, object: element)], timeout: 5) == .completed,
                      "Expected \(text.debugDescription), got \(element.label)", file: file, line: line)
    }
}
