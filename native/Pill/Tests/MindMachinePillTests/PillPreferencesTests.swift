/* Tests PillPreferences persistence against a throwaway UserDefaults suite, including a second
 instance reading the same suite to model an app relaunch. Run by `swift test --package-path native/Pill`. */
import XCTest
@testable import MindMachinePill

final class PillPreferencesTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        suiteName = "mm-pill-tests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testFreshInstallHasNoPositionAndShowsPill() {
        let prefs = PillPreferences(defaults: defaults)
        XCTAssertNil(prefs.center)
        XCTAssertTrue(prefs.pillShown)
    }

    func testPositionSurvivesRelaunch() {
        PillPreferences(defaults: defaults).center = CGPoint(x: 812.5, y: -240)
        let relaunched = PillPreferences(defaults: UserDefaults(suiteName: suiteName)!)
        XCTAssertEqual(relaunched.center, CGPoint(x: 812.5, y: -240), "negative y is valid on a display below the main one")
    }

    func testOriginZeroIsAValidStoredPosition() {
        let prefs = PillPreferences(defaults: defaults)
        prefs.center = CGPoint(x: 0, y: 0)
        XCTAssertEqual(prefs.center, CGPoint(x: 0, y: 0))
    }

    func testResetClearsPosition() {
        let prefs = PillPreferences(defaults: defaults)
        prefs.center = CGPoint(x: 1, y: 2)
        prefs.resetPosition()
        XCTAssertNil(prefs.center)
    }

    func testHiddenChoiceSurvivesRelaunch() {
        PillPreferences(defaults: defaults).pillShown = false
        XCTAssertFalse(PillPreferences(defaults: defaults).pillShown)
    }

    func testNonFiniteStoredValueIsIgnored() {
        defaults.set(Double.nan, forKey: "pill.center.x")
        defaults.set(10.0, forKey: "pill.center.y")
        XCTAssertNil(PillPreferences(defaults: defaults).center)
    }
}
