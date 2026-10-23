/* Frame arithmetic for the floating pill: where it rests by default, how a stored position is
 restored across display changes, where the panel opens from the pill, and where the pill returns to
 on collapse. Pure CoreGraphics in AppKit screen coordinates (origin bottom-left, y grows upward).
 Called by PillController (native/Apps/Mac/PillController.swift); exercised by PillGeometryTests.

 Lifted and adapted from Wisp (https://github.com/ycl-2004/Wisp, commit 1e86359, MIT,
 Copyright (c) 2026 YC): ScreenGeometry.clamp and the default bottom-centre placement above the Dock
 (ScreenGeometry.islandFrame / IslandController.defaultAnchor), and the "stored anchor on a vanished
 display falls back to the default" rule (IslandController.anchorPoint). See THIRD_PARTY_NOTICES.md. */
import CoreGraphics
import Foundation

/// One display, reduced to what placement needs. The controller builds these from NSScreen.
public struct PillScreen: Equatable, Sendable {
    public var id: UInt32
    public var frame: CGRect
    public var visibleFrame: CGRect

    public init(id: UInt32, frame: CGRect, visibleFrame: CGRect) {
        self.id = id
        self.frame = frame
        self.visibleFrame = visibleFrame
    }
}

/// Result of opening the panel from the pill.
public struct PillExpansion: Equatable, Sendable {
    /// Final panel frame, already inside the visible area of the pill's display.
    public var panelFrame: CGRect
    /// Where the pill sat inside that panel (pill origin minus panel origin). Collapsing re-applies
    /// it to wherever the panel is by then, so a panel the user dragged takes the pill with it.
    public var pillOffset: CGVector
}

public enum PillGeometry {
    public static let pillSize = CGSize(width: 60, height: 28)
    public static let panelSize = CGSize(width: 540, height: 440)
    /// Gap kept between the pill or panel and the edge of the usable screen area.
    public static let edgeInset: CGFloat = 8
    /// Resting height above the bottom of the usable area (above the Dock).
    public static let defaultBottomGap: CGFloat = 16

    // MARK: Placement

    /// Wisp's clamp, generalised: shrink to fit, then shift inside `visible` leaving `inset`.
    public static func clamp(_ frame: CGRect, in visible: CGRect, inset: CGFloat = edgeInset) -> CGRect {
        var result = frame
        let area = visible.insetBy(dx: inset, dy: inset)
        result.size.width = min(result.width, area.width)
        result.size.height = min(result.height, area.height)
        if result.maxX > area.maxX { result.origin.x = area.maxX - result.width }
        if result.minX < area.minX { result.origin.x = area.minX }
        if result.maxY > area.maxY { result.origin.y = area.maxY - result.height }
        if result.minY < area.minY { result.origin.y = area.minY }
        return result
    }

    /// Bottom centre, just above the Dock.
    public static func defaultPillFrame(on screen: PillScreen) -> CGRect {
        let visible = screen.visibleFrame
        return CGRect(x: (visible.midX - pillSize.width / 2).rounded(),
                      y: (visible.minY + defaultBottomGap).rounded(),
                      width: pillSize.width, height: pillSize.height)
    }

    /// The display whose frame contains `point`, or nil when it lies outside every display.
    public static func screen(containing point: CGPoint, in screens: [PillScreen]) -> PillScreen? {
        screens.first { $0.frame.contains(point) }
    }

    /// The display a frame mostly sits on: containing its centre, else the nearest by centre distance.
    public static func screen(for frame: CGRect, in screens: [PillScreen]) -> PillScreen? {
        let centre = CGPoint(x: frame.midX, y: frame.midY)
        if let hit = screen(containing: centre, in: screens) { return hit }
        return screens.min { distance(centre, $0.frame) < distance(centre, $1.frame) }
    }

    private static func distance(_ point: CGPoint, _ rect: CGRect) -> CGFloat {
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return (dx * dx + dy * dy).squareRoot()
    }

    /// Pill frame to use at launch and after display changes. A stored centre that still lies on a
    /// connected display is kept (clamped into that display's usable area); otherwise, for example
    /// after an external monitor is unplugged, the pill returns to the default on the first screen.
    public static func resolvePillFrame(storedCenter: CGPoint?, screens: [PillScreen]) -> CGRect {
        guard let first = screens.first else { return CGRect(origin: .zero, size: pillSize) }
        guard let centre = storedCenter, let screen = self.screen(containing: centre, in: screens) else {
            return defaultPillFrame(on: first)
        }
        let raw = CGRect(x: centre.x - pillSize.width / 2, y: centre.y - pillSize.height / 2,
                         width: pillSize.width, height: pillSize.height)
        return clamp(raw, in: screen.visibleFrame)
    }

    /// Keeps a pill frame on a connected display's usable area; used while dragging and on screen changes.
    public static func clampPill(_ frame: CGRect, screens: [PillScreen]) -> CGRect {
        guard let screen = self.screen(for: frame, in: screens) else { return frame }
        return clamp(frame, in: screen.visibleFrame)
    }

    // MARK: Expansion and collapse

    /// Opens the panel from the pill: centred on the pill horizontally, growing away from the nearer
    /// vertical edge of the usable area (up from a bottom pill, down from a top pill), then clamped
    /// so it never leaves the display.
    public static func expansion(from pill: CGRect, size: CGSize = panelSize, screens: [PillScreen]) -> PillExpansion {
        let screen = self.screen(for: pill, in: screens)
        let visible = screen?.visibleFrame ?? CGRect(origin: .zero, size: size)
        let growsUp = pill.midY <= visible.midY
        let raw = CGRect(x: pill.midX - size.width / 2,
                         y: growsUp ? pill.minY : pill.maxY - size.height,
                         width: size.width, height: size.height)
        let frame = clamp(raw, in: visible)
        return PillExpansion(panelFrame: frame,
                             pillOffset: CGVector(dx: pill.minX - frame.minX, dy: pill.minY - frame.minY))
    }

    /// Where the pill goes when the panel closes: the same spot inside the panel it opened from.
    public static func collapsedFrame(panelFrame: CGRect, pillOffset: CGVector, screens: [PillScreen]) -> CGRect {
        let raw = CGRect(x: panelFrame.minX + pillOffset.dx, y: panelFrame.minY + pillOffset.dy,
                         width: pillSize.width, height: pillSize.height)
        return clampPill(raw, screens: screens)
    }
}

/// Click-versus-drag discrimination for the collapsed pill. The window origin is derived from the
/// absolute cursor position every event, so there is no accumulated drift. Pointer events arrive
/// as screen coordinates.
///
/// The 4-point activation distance follows Pindrop's FloatingIndicatorInteractivePanel
/// (https://github.com/watzon/pindrop, commit 8044a15, MIT, Copyright (c) 2025 Pindrop Contributors);
/// the cursor-pinned origin follows Wisp's IslandController.dragChanged (MIT, see above).
public struct PillDrag: Equatable, Sendable {
    public static let activationDistance: CGFloat = 4

    private let startMouse: CGPoint
    private let grabOffset: CGVector
    public private(set) var isDragging = false

    public init(startMouse: CGPoint, windowOrigin: CGPoint) {
        self.startMouse = startMouse
        self.grabOffset = CGVector(dx: startMouse.x - windowOrigin.x, dy: startMouse.y - windowOrigin.y)
    }

    /// Feeds a mouse-dragged event. Returns the window origin to apply, or nil while still a click.
    public mutating func update(mouse: CGPoint) -> CGPoint? {
        if !isDragging {
            let moved = ((mouse.x - startMouse.x) * (mouse.x - startMouse.x)
                       + (mouse.y - startMouse.y) * (mouse.y - startMouse.y)).squareRoot()
            guard moved >= Self.activationDistance else { return nil }
            isDragging = true
        }
        return CGPoint(x: mouse.x - grabOffset.dx, y: mouse.y - grabOffset.dy)
    }
}

/// Animation durations, all under 200 ms. Reduce Motion removes the movement and keeps the change instant.
public enum PillMotion {
    public static let expand: TimeInterval = 0.18
    public static let collapse: TimeInterval = 0.14
    public static let modeSwitch: TimeInterval = 0.10

    public static func duration(_ base: TimeInterval, reduceMotion: Bool) -> TimeInterval {
        reduceMotion ? 0 : base
    }
}
