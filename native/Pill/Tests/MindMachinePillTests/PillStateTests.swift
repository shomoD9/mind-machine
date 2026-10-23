/* Tests the pill state machine through its public interface: events in, phase and visibility out.
 Run by `swift test --package-path native/Pill` in the native-ci workflow. */
import XCTest
@testable import MindMachinePill

final class PillStateTests: XCTestCase {
    func testClickExpandsToCaptureAndSecondClickDoesNothing() {
        var state = PillState()
        let first = state.send(.clickPill)
        XCTAssertTrue(first.expanding)
        XCTAssertEqual(state.phase, .expanded(.capture))
        XCTAssertTrue(state.send(.clickPill).isNoOp)
    }

    func testHotkeyTogglesAndAlwaysOpensCapture() {
        var state = PillState()
        state.send(.hotkey)
        state.send(.select(.find))
        XCTAssertEqual(state.phase, .expanded(.find))
        XCTAssertTrue(state.send(.hotkey).collapsing)
        state.send(.hotkey)
        XCTAssertEqual(state.phase, .expanded(.capture))
    }

    func testEscapeCloseAndClickAwayCollapse() {
        for event in [PillEvent.escape, .close, .clickAway] {
            var state = PillState(phase: .expanded(.find))
            XCTAssertTrue(state.send(event).collapsing, "\(event)")
            XCTAssertEqual(state.phase, .collapsed)
        }
    }

    func testClickAwayWhileCollapsedIsNoOp() {
        var state = PillState()
        XCTAssertTrue(state.send(.clickAway).isNoOp)
        XCTAssertTrue(state.send(.escape).isNoOp)
    }

    func testSelectSwitchesBetweenCaptureAndFind() {
        var state = PillState(phase: .expanded(.capture))
        let toFind = state.send(.select(.find))
        XCTAssertTrue(toFind.modeChanged)
        XCTAssertEqual(state.phase, .expanded(.find))
        XCTAssertTrue(state.send(.select(.find)).isNoOp)
        state.send(.select(.capture))
        XCTAssertEqual(state.phase, .expanded(.capture))
    }

    func testReservedThirdModeIsNeverSelectable() {
        var state = PillState(phase: .expanded(.find))
        XCTAssertFalse(PillMode.reserved.isAvailable)
        XCTAssertNil(PillMode.reserved.vaultModeIndex)
        XCTAssertTrue(state.send(.select(.reserved)).isNoOp)
        XCTAssertEqual(state.phase, .expanded(.find))
    }

    func testSelectWhileCollapsedIsIgnored() {
        var state = PillState()
        XCTAssertTrue(state.send(.select(.find)).isNoOp)
        XCTAssertEqual(state.phase, .collapsed)
    }

    func testVaultModeIndexesMatchSharedModel() {
        XCTAssertEqual(PillMode.capture.vaultModeIndex, 0)
        XCTAssertEqual(PillMode.find.vaultModeIndex, 1)
    }

    func testHidingPillHidesWindowButHotkeyStillOpensPanel() {
        var state = PillState()
        let hide = state.send(.toggleVisibility)
        XCTAssertTrue(hide.visibilityChanged)
        XCTAssertFalse(state.windowVisible)

        let open = state.send(.hotkey)
        XCTAssertTrue(open.expanding)
        XCTAssertTrue(open.visibilityChanged)
        XCTAssertTrue(state.windowVisible)

        // Closing returns to the hidden state the user chose.
        let close = state.send(.escape)
        XCTAssertTrue(close.visibilityChanged)
        XCTAssertFalse(state.windowVisible)
    }

    func testShowingPillAgainAfterHide() {
        var state = PillState(pillShown: false)
        state.send(.toggleVisibility)
        XCTAssertTrue(state.windowVisible)
        XCTAssertEqual(state.phase, .collapsed)
    }

    func testTogglingVisibilityWhileExpandedKeepsPanelOpen() {
        var state = PillState(phase: .expanded(.capture))
        state.send(.toggleVisibility)
        XCTAssertTrue(state.windowVisible)
        XCTAssertEqual(state.phase, .expanded(.capture))
    }
}
