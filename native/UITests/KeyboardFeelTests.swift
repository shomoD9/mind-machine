/* XCUITest coverage for how the production keyboard feels next to Apple's: caps lock, long-press
 alternates, sliding from shift or 123, delete repeat, the return key and landscape. It drives KeyboardTestHost (the same
 controller, KeyplaneView and RoutedTextProxy that ship) through real key gestures, like
 KeyboardAcceptanceTests. MindMachineKeyboardUITests in native-ci runs both files. The geometry
 test also saves screenshots of this keyboard and of Apple's keyboard on the same simulator, in
 portrait and landscape, as evidence for docs/verification/keyboard-feel-2026-10-24.md. */
import XCTest
import UIKit

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
            // The screen, not the app: the geometry test ends with the app terminated.
            attach(XCUIScreen.main.screenshot(), name: "failure")
            if app.state == .runningForeground {
                let tree = XCTAttachment(string: app.debugDescription)
                tree.lifetime = .keepAlways
                add(tree)
            }
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

    // MARK: Shift and 123 slides (audit G8)

    func testSlidingFromShiftTypesOneCapital() {
        let editor = launchAndFocusNote()
        tapKey("shift")
        tapKey("a")
        expectValue(editor, "a")
        slide(from: "shift", to: "k")
        expectValue(editor, "aK")
        // Shift is off again after the slide.
        tapKey("l")
        expectValue(editor, "aKl")
    }

    func testSlidingFrom123TypesOneDigitAndReturnsToLetters() {
        let editor = launchAndFocusNote()
        tapKey("shift")
        tapKey("a")
        // The number row replaces the top letter row on touch-down; e's position is 3.
        slide(from: "123", to: "e")
        expectValue(editor, "a3")
        tapKey("b")
        expectValue(editor, "a3b")
    }

    // MARK: Return key (audit G3, G4)

    func testActionReturnKeyIsGrey() {
        launch(extra: ["--host-return-search"])
        let editor = app.textViews["keyboard-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        editor.tap()
        app.buttons["typing-destination"].tap()
        expectLabel(app.buttons["typing-destination"], "Typing into: App")
        let returnKey = key("return")
        let isSearch = NSPredicate { _, _ in returnKey.label.localizedCaseInsensitiveContains("search") }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: isSearch, object: nil)], timeout: 5), .completed,
                       "Return should become Search for a search field, got \(returnKey.label)")
        Thread.sleep(forTimeInterval: 0.5)
        // Sample the key face beside its glyph: Apple's blue must arrive as the panel's prominent grey.
        let frame = returnKey.frame
        let colour = pixel(in: XCUIScreen.main.screenshot(), at: CGPoint(x: frame.minX + 9, y: frame.midY))
        attach(XCUIScreen.main.screenshot(), name: "return-search")
        XCTAssertLessThanOrEqual(max(colour.r, colour.g, colour.b) - min(colour.r, colour.g, colour.b), 6,
                                 "Return key fill must be grey, sampled \(colour)")
        XCTAssertLessThan((colour.r + colour.g + colour.b) / 3, 110, "Light appearance uses the dark prominent fill, sampled \(colour)")
    }

    func testReturnKeyIsInertWhileAnEmptyHostFieldAsksForIt() {
        launch(extra: ["--host-text", "", "--host-return-automatically"])
        let composer = app.textViews["host-composer"]
        let editor = app.textViews["keyboard-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        editor.tap()
        app.buttons["typing-destination"].tap()
        expectLabel(app.buttons["typing-destination"], "Typing into: App")
        tapKey("return")
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertEqual(composer.value as? String ?? "", "", "Return must do nothing in an empty field that asks for it")
        tapKey("x")
        expectValue(composer, "X")
        tapKey("return")
        expectValue(composer, "X\n")
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

    /// Touch one key, hold briefly, slide to where another key sits and lift. Positions are read
    /// before the gesture because the layout under the finger changes on touch-down.
    private func slide(from source: String, to target: String) {
        XCTAssertTrue(key(source).waitForExistence(timeout: 5))
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let start = key(source).frame, end = key(target).frame
        origin.withOffset(CGVector(dx: start.midX, dy: start.midY))
            .press(forDuration: 0.3, thenDragTo: origin.withOffset(CGVector(dx: end.midX, dy: end.midY)))
    }

    /// The 0-255 colour of one screen point in a screenshot.
    private func pixel(in screenshot: XCUIScreenshot, at point: CGPoint) -> (r: Int, g: Int, b: Int) {
        let image = screenshot.image
        guard let cgImage = image.cgImage else { return (0, 0, 0) }
        var data = [UInt8](repeating: 0, count: 4)
        let space = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: &data, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: space,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return (0, 0, 0) }
        let scale = image.scale
        context.draw(cgImage, in: CGRect(x: -point.x * scale, y: -(CGFloat(cgImage.height) - point.y * scale),
                                         width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)))
        return (Int(data[0]), Int(data[1]), Int(data[2]))
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
