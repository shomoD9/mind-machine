/* XCUITest coverage for how the production keyboard feels next to Apple's: caps lock, long-press
 alternates, delete repeat, landscape and the return key. It drives KeyboardTestHost (the same
 controller, KeyplaneView and RoutedTextProxy that ship) through real key gestures, like
 KeyboardAcceptanceTests. MindMachineKeyboardUITests in native-ci runs both files. The geometry
 test also saves screenshots of this keyboard and of Apple's keyboard on the same simulator, in
 portrait and landscape, as evidence for docs/verification/keyboard-feel-2026-10-24.md. */
import XCTest

final class KeyboardFeelTests: XCTestCase {
    private var app: XCUIApplication!
    private let vault = UUID().uuidString

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        if testRun?.hasSucceeded == false {
            attach(app.screenshot(), name: "failure")
            let tree = XCTAttachment(string: app.debugDescription)
            tree.lifetime = .keepAlways
            add(tree)
        }
        app.terminate()
        // Later tests (including KeyboardAcceptanceTests) assume portrait.
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: Caps lock (audit G9)

    func testDoubleTapShiftLocksCapitalsUntilShiftIsTappedAgain() {
        let editor = launchAndFocusNote()
        // An empty note starts a sentence with shift on; turn it off so the double tap starts from lowercase.
        tapKey("shift")
        tapKey("a")
        expectValue(editor, "a")
        // Let the previous shift release age past the double-tap window before the real double tap.
        Thread.sleep(forTimeInterval: 0.8)
        key("shift").doubleTap()
        for letter in ["b", "c", "d"] { tapKey(letter) }
        expectValue(editor, "aBCD")
        // A single tap leaves caps lock; the next letter is lowercase and shift stays off after it.
        tapKey("shift")
        tapKey("e")
        tapKey("f")
        expectValue(editor, "aBCDef")
    }

    // MARK: Long-press alternates (audit G5)

    func testLongPressAndSlideTypesAnAccentedLetter() {
        let editor = launchAndFocusNote()
        tapKey("shift")
        // Hold e until its alternates appear, slide one key to the right and lift.
        key("e").press(forDuration: 1.0, thenDragTo: key("r"))
        let value = editor.value as? String ?? ""
        XCTAssertTrue(["è", "é", "ê", "ë", "ē", "ė", "ę", "ě", "ẽ"].contains(value),
                      "Expected an accented e from the long-press callout, got \(value.debugDescription)")
    }

    func testKeysWithoutAppleAlternatesShowNoAccentCallout() {
        let editor = launchAndFocusNote()
        tapKey("shift")
        // Apple's English keyboard has no alternates on t. Holding t and sliding one key right must
        // not pick an accent (KeyboardKit's open-source table offered ț ť þ here); the release stays
        // within the key's release tolerance, so t itself is typed.
        key("t").press(forDuration: 1.0, thenDragTo: key("y"))
        expectValue(editor, "t")
    }

    // MARK: Delete repeat (audit G6)

    func testHoldingDeleteRepeatsCharactersThenRemovesWholeWords() {
        let words = (1...40).map { "word\($0)" }
        let original = words.joined(separator: " ")
        launch(extra: ["--host-text", original])
        let composer = app.textViews["host-composer"]
        let editor = app.textViews["keyboard-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        editor.tap()
        app.buttons["typing-destination"].tap()
        expectLabel(app.buttons["typing-destination"], "Typing into: App")

        // A short hold repeats: more than the single touch-down delete, far less than everything.
        key("delete").press(forDuration: 1.4)
        let short = composer.value as? String ?? ""
        let shortDeleted = original.count - short.count
        XCTAssertTrue(original.hasPrefix(short), "Delete must only remove text from the end")
        XCTAssertGreaterThan(shortDeleted, 3, "Holding delete must repeat")
        XCTAssertLessThan(shortDeleted, 40, "Repeat must start with single characters")

        // A long hold reaches whole-word deletion: much more is removed and the remainder ends on a word boundary.
        key("delete").press(forDuration: 6.0)
        let long = composer.value as? String ?? ""
        let longDeleted = short.count - long.count
        XCTAssertTrue(original.hasPrefix(long), "Delete must only remove text from the end")
        XCTAssertGreaterThan(longDeleted, 70, "A long hold must accelerate to whole words")
        let boundary = long.isEmpty || long.hasSuffix(" ") || original.dropFirst(long.count).hasPrefix(" ")
        XCTAssertTrue(boundary, "Word deletion must stop on a word boundary, left \(long.suffix(12).debugDescription)")
        // Host deletion never touches the private note.
        expectValue(editor, "")
    }

    // MARK: Landscape (audit G2)

    func testLandscapeShowsShorterKeysAndAWorkingPanel() {
        let editor = launchAndFocusNote()
        let portraitHeight = key("q").frame.height
        XCUIDevice.shared.orientation = .landscapeLeft
        let shorter = NSPredicate { _, _ in self.key("q").frame.height < portraitHeight - 4 }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: shorter, object: nil)], timeout: 10), .completed,
                       "Landscape keys must be shorter than portrait (\(portraitHeight) pt)")
        let window = app.windows.firstMatch.frame
        for name in ["q", "p", "a", "l", "shift", "delete", "123", "space", "return"] {
            let element = key(name)
            XCTAssertTrue(element.isHittable, "\(name) must be hittable in landscape")
            XCTAssertTrue(window.contains(element.frame), "\(name) must lie inside the window in landscape")
        }
        for name in ["keyboard-save", "pad-size", "typing-destination"] {
            XCTAssertTrue(app.buttons[name].isHittable, "\(name) must stay usable in landscape")
        }
        XCTAssertTrue(editor.isHittable, "The note must stay visible in landscape")
        XCTAssertGreaterThanOrEqual(editor.frame.height, 30, "The note must keep at least one line in landscape")
        tapKey("h")
        tapKey("i")
        expectValue(editor, "Hi")
        // Every size keeps the keys inside the window.
        for title in ["Size: Expanded", "Size: Min", "Size: Default"] {
            app.buttons["pad-size"].tap()
            expectLabel(app.buttons["pad-size"], title)
            XCTAssertTrue(window.contains(key("return").frame), "Keys must stay inside the window at \(title)")
            XCTAssertTrue(editor.isHittable, "The note must stay visible at \(title)")
        }
    }

    // MARK: Geometry evidence (audit G1)

    /// Saves both keyboards in both orientations and logs key frames. The assertions only check that
    /// each capture happened; the pixel comparison lives in the audit document.
    func testCaptureGeometryAgainstAppleKeyboard() {
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            let label = orientation == .portrait ? "portrait" : "landscape"
            XCUIDevice.shared.orientation = orientation
            launch()
            XCTAssertTrue(key("q").waitForExistence(timeout: 10))
            Thread.sleep(forTimeInterval: 1.5)
            attach(XCUIScreen.main.screenshot(), name: "mind-machine-\(label)")
            for name in ["q", "w", "p", "a", "shift", "z", "delete", "123", "space", "return"] {
                print("GEOMETRY mind-machine \(label) \(name) \(key(name).frame)")
            }
            app.terminate()

            launch(extra: ["--apple-keyboard-reference"])
            let apple = app.keyboards.firstMatch
            if apple.waitForExistence(timeout: 10) {
                Thread.sleep(forTimeInterval: 1.5)
                attach(XCUIScreen.main.screenshot(), name: "apple-\(label)")
                print("GEOMETRY apple \(label) keyboard \(apple.frame)")
                for element in apple.keys.allElementsBoundByIndex {
                    print("GEOMETRY apple \(label) \(element.label) \(element.frame)")
                }
            } else {
                print("GEOMETRY apple \(label) keyboard-not-shown")
            }
            app.terminate()
        }
    }

    // MARK: Helpers

    private func launch(extra: [String] = []) {
        app.launchArguments = ["--vault-id", vault] + extra
        app.launch()
    }

    @discardableResult
    private func launchAndFocusNote() -> XCUIElement {
        launch()
        let editor = app.textViews["keyboard-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10), "Production keyboard must appear in the host")
        editor.tap()
        return editor
    }

    private func key(_ name: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "keyboard-key-" + name).firstMatch
    }

    private func tapKey(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
        let element = key(name)
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Missing key \(name)", file: file, line: line)
        // Same explicit short hold as KeyboardAcceptanceTests: both gesture phases, below long-press.
        element.press(forDuration: 0.12)
    }

    private func attach(_ screenshot: XCUIScreenshot, name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
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
