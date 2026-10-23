/* Persistence for the pill: its resting position (as the pill's centre in global screen coordinates)
 and the Show/Hide choice. Backed by UserDefaults so the position survives relaunch; the suite is
 injectable so tests never touch the real defaults.
 Called by PillController (native/Apps/Mac/PillController.swift); exercised by PillPreferencesTests.
 The "persist a dragged anchor, fall back when its display is gone" idea follows Wisp's AppSettings.islandAnchor
 (MIT, see PillGeometry.swift); storage format and keys are ours. */
import CoreGraphics
import Foundation

public struct PillPreferences {
    private let defaults: UserDefaults
    private enum Key {
        static let x = "pill.center.x"
        static let y = "pill.center.y"
        static let shown = "pill.shown"
    }

    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    /// nil until the user has dragged the pill; callers then use the default placement.
    public var center: CGPoint? {
        get {
            guard defaults.object(forKey: Key.x) != nil, defaults.object(forKey: Key.y) != nil else { return nil }
            let point = CGPoint(x: defaults.double(forKey: Key.x), y: defaults.double(forKey: Key.y))
            // A corrupt value must not move the pill off every display.
            return point.x.isFinite && point.y.isFinite ? point : nil
        }
        nonmutating set {
            if let newValue {
                defaults.set(Double(newValue.x), forKey: Key.x)
                defaults.set(Double(newValue.y), forKey: Key.y)
            } else {
                defaults.removeObject(forKey: Key.x)
                defaults.removeObject(forKey: Key.y)
            }
        }
    }

    /// The pill is shown unless the user hid it from the menu bar item.
    public var pillShown: Bool {
        get { defaults.object(forKey: Key.shown) == nil ? true : defaults.bool(forKey: Key.shown) }
        nonmutating set { defaults.set(newValue, forKey: Key.shown) }
    }

    public func resetPosition() { center = nil }
}
