/* Tests placement, display-change restoration, anchored expansion/collapse, drag discrimination and
 motion durations in PillGeometry.swift. Run by `swift test --package-path native/Pill` in native-ci. */
import XCTest
@testable import MindMachinePill

final class PillGeometryTests: XCTestCase {
    // A laptop with a 30 pt menu bar and 80 pt Dock, and an external display to its right.
    let laptop = PillScreen(id: 1, frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                            visibleFrame: CGRect(x: 0, y: 80, width: 1440, height: 790))
    let external = PillScreen(id: 2, frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080),
                              visibleFrame: CGRect(x: 1440, y: 0, width: 1920, height: 1050))
    var both: [PillScreen] { [laptop, external] }

    private func assertInside(_ frame: CGRect, _ visible: CGRect, file: StaticString = #filePath, line: UInt = #line) {
        let area = visible.insetBy(dx: PillGeometry.edgeInset, dy: PillGeometry.edgeInset)
        XCTAssertTrue(area.contains(frame), "\(frame) not inside \(area)", file: file, line: line)
    }

    // MARK: Default and restored position

    func testDefaultIsBottomCentreAboveDock() {
        let frame = PillGeometry.defaultPillFrame(on: laptop)
        XCTAssertEqual(frame.midX, 720, accuracy: 1)
        XCTAssertEqual(frame.minY, 96, accuracy: 0.5)
        XCTAssertEqual(frame.size, PillGeometry.pillSize)
    }

    func testNoStoredPositionUsesDefaultOnFirstScreen() {
        XCTAssertEqual(PillGeometry.resolvePillFrame(storedCenter: nil, screens: both),
                       PillGeometry.defaultPillFrame(on: laptop))
    }

    func testStoredPositionOnExternalDisplayIsRestored() {
        let frame = PillGeometry.resolvePillFrame(storedCenter: CGPoint(x: 2000, y: 500), screens: both)
        XCTAssertEqual(frame.midX, 2000, accuracy: 0.5)
        XCTAssertEqual(frame.midY, 500, accuracy: 0.5)
    }

    func testStoredPositionOnUnpluggedDisplayFallsBackToDefault() {
        let frame = PillGeometry.resolvePillFrame(storedCenter: CGPoint(x: 2000, y: 500), screens: [laptop])
        XCTAssertEqual(frame, PillGeometry.defaultPillFrame(on: laptop))
    }

    func testStoredPositionUnderDockIsClampedIntoUsableArea() {
        let frame = PillGeometry.resolvePillFrame(storedCenter: CGPoint(x: 720, y: 10), screens: [laptop])
        assertInside(frame, laptop.visibleFrame)
    }

    func testStoredPositionAtScreenCornerIsClamped() {
        let frame = PillGeometry.resolvePillFrame(storedCenter: CGPoint(x: 1439, y: 899), screens: [laptop])
        assertInside(frame, laptop.visibleFrame)
    }

    func testNoScreensDoesNotCrash() {
        XCTAssertEqual(PillGeometry.resolvePillFrame(storedCenter: nil, screens: []).size, PillGeometry.pillSize)
    }

    func testClampShrinksFrameLargerThanDisplay() {
        let clamped = PillGeometry.clamp(CGRect(x: -50, y: -50, width: 5000, height: 5000), in: laptop.visibleFrame)
        assertInside(clamped, laptop.visibleFrame)
    }

    // MARK: Expansion and collapse

    func testBottomPillOpensUpwardCentredOnPill() {
        let pill = PillGeometry.defaultPillFrame(on: laptop)
        let expansion = PillGeometry.expansion(from: pill, screens: both)
        assertInside(expansion.panelFrame, laptop.visibleFrame)
        XCTAssertEqual(expansion.panelFrame.midX, pill.midX, accuracy: 0.5)
        XCTAssertEqual(expansion.panelFrame.minY, pill.minY, accuracy: 0.5, "grows up from the pill")
        XCTAssertGreaterThan(expansion.panelFrame.maxY, pill.maxY)
    }

    func testTopRightPillOpensDownwardAndStaysOnScreen() {
        let pill = CGRect(x: 1372, y: 830, width: 60, height: 28)
        let expansion = PillGeometry.expansion(from: pill, screens: [laptop])
        assertInside(expansion.panelFrame, laptop.visibleFrame)
        XCTAssertTrue(expansion.panelFrame.contains(pill.insetBy(dx: 1, dy: 1)), "panel still covers the pill spot")
        XCTAssertEqual(expansion.panelFrame.maxY, 858, accuracy: 0.5, "top edge stays with the pill top")
    }

    func testPillOnExternalDisplayExpandsOnThatDisplay() {
        let pill = CGRect(x: 2300, y: 20, width: 60, height: 28)
        let expansion = PillGeometry.expansion(from: pill, screens: both)
        assertInside(expansion.panelFrame, external.visibleFrame)
        XCTAssertGreaterThanOrEqual(expansion.panelFrame.minX, external.frame.minX)
    }

    func testCollapseReturnsToExactOriginalSpot() {
        let spots = [PillGeometry.defaultPillFrame(on: laptop),
                     CGRect(x: 1372, y: 830, width: 60, height: 28),
                     CGRect(x: 20, y: 100, width: 60, height: 28),
                     CGRect(x: 2300, y: 20, width: 60, height: 28)]
        for pill in spots {
            let expansion = PillGeometry.expansion(from: pill, screens: both)
            let back = PillGeometry.collapsedFrame(panelFrame: expansion.panelFrame, pillOffset: expansion.pillOffset, screens: both)
            XCTAssertEqual(back.origin.x, pill.origin.x, accuracy: 0.5, "\(pill)")
            XCTAssertEqual(back.origin.y, pill.origin.y, accuracy: 0.5, "\(pill)")
        }
    }

    func testDraggedPanelTakesPillWithIt() {
        let pill = PillGeometry.defaultPillFrame(on: laptop)
        let expansion = PillGeometry.expansion(from: pill, screens: [laptop])
        let moved = expansion.panelFrame.offsetBy(dx: 100, dy: 60)
        let back = PillGeometry.collapsedFrame(panelFrame: moved, pillOffset: expansion.pillOffset, screens: [laptop])
        XCTAssertEqual(back.origin.x, pill.origin.x + 100, accuracy: 0.5)
        XCTAssertEqual(back.origin.y, pill.origin.y + 60, accuracy: 0.5)
    }

    func testCollapseAfterDisplayLossKeepsPillOnAConnectedDisplay() {
        let pill = CGRect(x: 2300, y: 20, width: 60, height: 28)
        let expansion = PillGeometry.expansion(from: pill, screens: both)
        let back = PillGeometry.collapsedFrame(panelFrame: expansion.panelFrame, pillOffset: expansion.pillOffset, screens: [laptop])
        assertInside(back, laptop.visibleFrame)
    }

    // MARK: Drag

    func testSmallMovementIsStillAClick() {
        var drag = PillDrag(startMouse: CGPoint(x: 100, y: 100), windowOrigin: CGPoint(x: 80, y: 90))
        XCTAssertNil(drag.update(mouse: CGPoint(x: 102, y: 101)))
        XCTAssertFalse(drag.isDragging)
    }

    func testDragFollowsCursorWithoutDrift() {
        var drag = PillDrag(startMouse: CGPoint(x: 100, y: 100), windowOrigin: CGPoint(x: 80, y: 90))
        XCTAssertEqual(drag.update(mouse: CGPoint(x: 130, y: 100)), CGPoint(x: 110, y: 90))
        XCTAssertTrue(drag.isDragging)
        // Once dragging, even a tiny move reports the origin, and returning to the start returns the start.
        XCTAssertEqual(drag.update(mouse: CGPoint(x: 131, y: 100)), CGPoint(x: 111, y: 90))
        XCTAssertEqual(drag.update(mouse: CGPoint(x: 100, y: 100)), CGPoint(x: 80, y: 90))
    }

    // MARK: Motion

    func testAllDurationsUnder200ms() {
        for duration in [PillMotion.expand, PillMotion.collapse, PillMotion.modeSwitch] {
            XCTAssertLessThan(duration, 0.2)
            XCTAssertGreaterThan(duration, 0)
        }
    }

    func testReduceMotionMakesChangesInstant() {
        XCTAssertEqual(PillMotion.duration(PillMotion.expand, reduceMotion: true), 0)
        XCTAssertEqual(PillMotion.duration(PillMotion.expand, reduceMotion: false), PillMotion.expand)
    }
}
