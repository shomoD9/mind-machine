/* XCUITest acceptance for the production keyboard embedded by KeyboardTestHost.
 MindMachineKeyboardUITests in native-ci drives controls and reads visible text;
 no test reads the vault database or substitutes Capture/Recall operations. The XCTestCase
 extension also supplies snapshot-based text assertions to KeyboardFeelTests.
 IPhoneMarkdownAcceptanceTests launches the companion adapter probe in the same host. */
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
        // UIKit exposes an empty UITextView without a raw AX value. Check that
        // state before typing, then require the exact saved and recalled text.
        expectValue(editor, "")
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
        guard let query = editor.value as? String else {
            XCTFail("Recall editor must expose its query as text")
            return
        }
        // Check every deletion at the retained caret, so a missed edit fails at
        // that key rather than appearing later as a failed search or empty query.
        for remaining in (0..<query.count).reversed() {
            tapKey("delete")
            expectValue(editor, String(query.prefix(remaining)))
        }
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
}

// Both keyboard suites compare completed accessibility snapshots. An outer
// XCTWaiter can cancel XCTest's own in-flight AX query before it returns a value
// (run 40110448639), mistaking observation latency for a product mismatch.
extension XCTestCase {
    func expectValue(_ element: XCUIElement, _ text: String, file: StaticString = #filePath, line: UInt = #line) {
        expectText(element, text, attribute: { snapshot in
            let value = snapshot.value
            // An existing empty UITextView has no raw AX value (run 40113103269).
            // Normalize only that representation; snapshot errors still throw,
            // and other element types or non-string values remain mismatches.
            if value == nil && snapshot.elementType == .textView { return "" }
            return value as? String
        }, file: file, line: line)
    }

    func expectLabel(_ element: XCUIElement, _ text: String, file: StaticString = #filePath, line: UInt = #line) {
        expectText(element, text, attribute: { $0.label }, file: file, line: line)
    }

    private func expectText(_ element: XCUIElement, _ text: String,
                            attribute: (XCUIElementSnapshot) -> String?, file: StaticString, line: UInt) {
        // Keep the five-second settling budget, but allow each AX request its
        // normal XCTest transport deadline. Compare the completed observation;
        // a missing element, invalid attribute or wrong string must still fail.
        let deadline = ProcessInfo.processInfo.systemUptime + 5
        do {
            var actual = attribute(try element.snapshot())
            while actual != text && ProcessInfo.processInfo.systemUptime < deadline {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                actual = attribute(try element.snapshot())
            }
            XCTAssertEqual(actual, text, file: file, line: line)
        } catch {
            XCTFail("Could not snapshot \(element.identifier): \(error)", file: file, line: line)
        }
    }
}

// The same hosted Simulator job verifies the companion adapter through a
// separate host mode; production keyboard journeys above remain unchanged.
final class IPhoneMarkdownAcceptanceTests: XCTestCase {
    func testCompanionSourceCompositionUndoContinuationHandoffAndTiming() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--iphone-markdown-probe"]
        app.launch()
        defer { app.terminate() }
        let report = app.staticTexts["iphone-markdown-report"]
        XCTAssertTrue(report.waitForExistence(timeout: 10))
        let completed = NSPredicate { _, _ in
            let label = report.label
            return label.hasPrefix("PASS ") || label.hasPrefix("FAIL ")
        }
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: completed, object: nil)], timeout: 240)
        XCTAssertEqual(result, .completed, report.label)
        let attachment = XCTAttachment(string: report.label)
        attachment.name = "iPhone Markdown source, UIKit and timing evidence"
        attachment.lifetime = .keepAlways
        add(attachment)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.lifetime = .keepAlways
        add(screenshot)
        XCTAssertTrue(report.label.hasPrefix("PASS "), report.label)
    }
}
