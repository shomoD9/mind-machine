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

    func testCaptureRecallInsertAndRelaunch() {
        let editor = app.textViews["keyboard-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10), "Production keyboard must appear in the host")
        editor.tap()
        editor.typeText("Tonight telescope code 7319")
        app.buttons["keyboard-save"].tap()
        XCTAssertEqual(app.staticTexts["keyboard-status"].label, "Saved on this device")
        XCTAssertEqual(app.textViews["host-composer"].value as? String, "host draft stays here")
    }
}
