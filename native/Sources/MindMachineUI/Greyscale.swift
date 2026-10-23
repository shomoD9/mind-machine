/* The greyscale palette and dithered grain shared by every Mind Machine surface.
 WorkspaceView, PrivateSyncSetupView, ReminderViews and RichNoteEditor read the SwiftUI
 colours and styles; the iPhone companion (Apps/iOS/MindMachineApp.swift) paints its
 canvas with GrainOverlay; the keyboard panel (Apps/Keyboard/KeyboardPanelStyle.swift)
 reads the UIKit colours and grain pattern. Every tone is a pure grey (equal red, green
 and blue) that adapts to light and dark appearance, so no surface carries a colour accent. */
import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

public enum Greyscale {
    /// One grey level per appearance, 0 black to 1 white, with an optional alpha for overlays.
    public struct Tone: Sendable {
        public let light: CGFloat
        public let dark: CGFloat
        public let lightAlpha: CGFloat
        public let darkAlpha: CGFloat
        init(_ light: CGFloat, _ dark: CGFloat, alpha: CGFloat = 1, darkAlpha: CGFloat? = nil) {
            self.light = light; self.dark = dark; lightAlpha = alpha; self.darkAlpha = darkAlpha ?? alpha
        }
    }

    // Text tones: primary ink, quieter supporting copy and the faintest hints.
    public static let ink = Tone(0.09, 0.93)
    public static let inkSecondary = Tone(0.38, 0.64)
    public static let inkTertiary = Tone(0.56, 0.46)
    // Surfaces: the screen canvas, raised cards/fields and the keyboard backdrop behind the keys.
    // The backdrop matches, in pure grey, the iOS 26 system strip drawn below a custom keyboard
    // (measured 223,223,227 light and 26,26,27 dark in the CI simulator), so keys and strip read as one surface.
    public static let canvas = Tone(0.955, 0.075)
    public static let paper = Tone(0.995, 0.135)
    public static let backdrop = Tone(0.875, 0.102)
    // Control fills, hairlines and the one prominent fill used by the primary action on each screen.
    public static let fill = Tone(0, 1, alpha: 0.06, darkAlpha: 0.09)
    public static let fillPressed = Tone(0, 1, alpha: 0.12, darkAlpha: 0.16)
    public static let hairline = Tone(0, 1, alpha: 0.11, darkAlpha: 0.14)
    public static let prominent = Tone(0.13, 0.9)
    public static let onProminent = Tone(0.98, 0.08)
}

// MARK: - Platform colours

#if os(iOS)
public extension Greyscale.Tone {
    /// A dynamic UIKit colour; the keyboard panel uses these directly.
    var uiColor: UIColor {
        let tone = self
        return UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: tone.dark, alpha: tone.darkAlpha)
                : UIColor(white: tone.light, alpha: tone.lightAlpha)
        }
    }
    var color: Color { Color(uiColor: uiColor) }
}
#else
public extension Greyscale.Tone {
    var nsColor: NSColor {
        let tone = self
        return NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(white: tone.dark, alpha: tone.darkAlpha)
                : NSColor(white: tone.light, alpha: tone.lightAlpha)
        }
    }
    var color: Color { Color(nsColor: nsColor) }
}
#endif

// MARK: - Dithered grain

/// A small tile of black and white pixels, thresholded from hashed noise mixed with a
/// 4×4 ordered-dither (Bayer) matrix. Drawn at a few percent opacity over a flat grey it
/// reads as paper grain; half the pixels lighten and half darken, so the mean tone is unchanged.
/// The tile is 128×128 RGBA (64 KiB) and is generated once per process.
public enum GrainTexture {
    public static let pixelSize = 128
    /// Points per tile pixel denominator: 2 draws each grain pixel at half a point.
    public static let scale: CGFloat = 2

    public static let image: CGImage? = {
        let size = pixelSize
        var pixels = [UInt8](repeating: 0, count: size * size * 4)
        let bayer: [Double] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5].map { ($0 + 0.5) / 16 }
        for y in 0..<size {
            for x in 0..<size {
                // A fixed integer hash keeps the texture identical across launches and devices.
                var h = UInt32(truncatingIfNeeded: x &* 374_761_393 &+ y &* 668_265_263)
                h = (h ^ (h >> 13)) &* 1_274_126_177
                h ^= h >> 16
                let noise = Double(h & 0xFFFF) / 65_535
                let value = noise * 0.7 + bayer[(y % 4) * 4 + x % 4] * 0.3
                let grey: UInt8 = value > 0.5 ? 255 : 0
                let offset = (y * size + x) * 4
                pixels[offset] = grey; pixels[offset + 1] = grey; pixels[offset + 2] = grey; pixels[offset + 3] = 255
            }
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(width: size, height: size, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: size * 4,
                       space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }()

    /// Grain opacity per appearance; dark surfaces need slightly more to stay visible.
    public static let lightOpacity: CGFloat = 0.035
    public static let darkOpacity: CGFloat = 0.05

    #if os(iOS)
    /// A tiling pattern colour for UIKit backgrounds (the keyboard panel's grain layer).
    public static let patternColor: UIColor? = image.map {
        UIColor(patternImage: UIImage(cgImage: $0, scale: scale, orientation: .up))
    }
    #endif
}

/// A non-interactive tiled grain layer. Callers place it over a flat Greyscale surface.
public struct GrainOverlay: View {
    @Environment(\.colorScheme) private var colorScheme
    public init() {}
    public var body: some View {
        if let image = GrainTexture.image {
            Image(decorative: image, scale: GrainTexture.scale)
                .resizable(resizingMode: .tile)
                .opacity(colorScheme == .dark ? GrainTexture.darkOpacity : GrainTexture.lightOpacity)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - SwiftUI styles

public extension View {
    /// The companion's screen background: a flat canvas grey with grain, edge to edge.
    func greyscaleCanvas() -> some View {
        background { Greyscale.canvas.color.overlay(GrainOverlay()).ignoresSafeArea() }
    }

    /// A raised card: paper surface, hairline edge and a soft radius.
    func greyscaleCard(padding: CGFloat = 14) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Greyscale.paper.color, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Greyscale.hairline.color, lineWidth: 1))
    }
}

/// Button appearance used across the shared views. `prominent` is reserved for the one
/// primary action on a screen (Save, Send, Pair); `quiet` is a filled secondary control.
public struct GreyscaleButtonStyle: ButtonStyle {
    public enum Kind { case prominent, quiet }
    private let kind: Kind
    @Environment(\.isEnabled) private var isEnabled
    public init(_ kind: Kind = .quiet) { self.kind = kind }
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(kind == .prominent ? .semibold : .medium))
            .foregroundStyle(kind == .prominent ? Greyscale.onProminent.color : Greyscale.ink.color)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(background(pressed: configuration.isPressed), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    private func background(pressed: Bool) -> Color {
        switch kind {
        case .prominent: return Greyscale.prominent.color.opacity(pressed ? 0.8 : 1)
        case .quiet: return (pressed ? Greyscale.fillPressed : Greyscale.fill).color
        }
    }
}

/// Text fields as flat paper wells with a hairline edge; replaces the system rounded border.
public struct GreyscaleFieldStyle: TextFieldStyle {
    public init() {}
    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .foregroundStyle(Greyscale.ink.color)
            .padding(.horizontal, 12).padding(.vertical, 9)
            .background(Greyscale.paper.color, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Greyscale.hairline.color, lineWidth: 1))
    }
}

/// Small uppercase section label with open tracking, used above grouped controls.
public struct GreyscaleSectionLabel: View {
    private let text: String
    public init(_ text: String) { self.text = text }
    public var body: some View {
        Text(text).font(.caption2.weight(.semibold)).tracking(0.8).foregroundStyle(Greyscale.inkSecondary.color)
    }
}

#if os(iOS)
/// Process-wide UIKit appearance for system controls SwiftUI draws through UIKit
/// (segmented pickers, switches, navigation titles). The iPhone companion calls this once
/// at launch; the keyboard styles its own controls in KeyboardPanelStyle instead.
@MainActor
public enum GreyscaleAppearance {
    public static func install() {
        let segments = UISegmentedControl.appearance()
        segments.backgroundColor = Greyscale.fill.uiColor
        segments.selectedSegmentTintColor = Greyscale.paper.uiColor
        segments.setTitleTextAttributes([.foregroundColor: Greyscale.inkSecondary.uiColor,
                                         .font: UIFont.systemFont(ofSize: 13, weight: .medium)], for: .normal)
        segments.setTitleTextAttributes([.foregroundColor: Greyscale.ink.uiColor,
                                         .font: UIFont.systemFont(ofSize: 13, weight: .semibold)], for: .selected)
        UISwitch.appearance().onTintColor = Greyscale.prominent.uiColor
        let navigation = UINavigationBarAppearance()
        navigation.configureWithTransparentBackground()
        navigation.titleTextAttributes = [.foregroundColor: Greyscale.ink.uiColor,
                                          .font: UIFont.systemFont(ofSize: 15, weight: .semibold)]
        UINavigationBar.appearance().standardAppearance = navigation
        UINavigationBar.appearance().scrollEdgeAppearance = navigation
    }
}
#endif
