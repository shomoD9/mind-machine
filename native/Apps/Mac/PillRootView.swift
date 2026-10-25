/* The view tree inside the pill window: a flat greyscale rounded surface, the pill glyph, the SwiftUI
 panel content and the click/drag handle. The surface is one opaque paper grey (Greyscale.paper) drawn by
 PillSurfaceView rather than a translucent behind-window blur: the panel reads as a page, matches the
 companion's greyscale surfaces and costs no live blur while it animates. Built once by PillController
 (PillController.swift), which animates the window frame while fading the glyph and content; the content is laid out once at its
 final size and pinned to the top-left, so the window reveals it instead of re-laying it out per frame.
 The 14 pt corner radius makes the 28 pt pill a capsule and keeps the panel's corners soft.
 PillAcceptanceTests opens the existing accessible handle through its stable identifier. */
import AppKit
import SwiftUI
import MindMachinePill
import MindMachineUI

final class PillRootView: NSView {
    static let cornerRadius: CGFloat = 14

    let glyph = NSImageView()
    let handle = PillHandleView()
    let content: NSHostingView<PillPanelView>

    init(viewModel: PillViewModel, model: VaultModel) {
        content = NSHostingView(rootView: PillPanelView(pill: viewModel, model: model))
        super.init(frame: NSRect(origin: .zero, size: PillGeometry.pillSize))
        wantsLayer = true
        layer?.cornerRadius = Self.cornerRadius
        layer?.cornerCurve = .continuous
        layer?.masksToBounds = true
        // Hairline edge so the pill stays visible over both light and dark content.
        layer?.borderWidth = 0.5
        layer?.borderColor = NSColor.separatorColor.cgColor

        let surface = PillSurfaceView(frame: bounds)
        surface.autoresizingMask = [.width, .height]
        addSubview(surface)

        // The SwiftUI view must not drive the window's size: the controller owns every frame change.
        content.sizingOptions = []
        let panelSize = PillGeometry.panelSize
        content.frame = NSRect(x: 0, y: bounds.height - panelSize.height, width: panelSize.width, height: panelSize.height)
        content.autoresizingMask = [.maxXMargin, .minYMargin]   // pinned to the top-left corner
        content.alphaValue = 0
        content.isHidden = true
        addSubview(content)

        let symbol = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: nil)
            ?? NSImage(systemSymbolName: "circle.grid.2x2.fill", accessibilityDescription: nil)
        glyph.image = symbol?.withSymbolConfiguration(.init(pointSize: 14, weight: .medium))
        glyph.contentTintColor = Greyscale.ink.nsColor
        glyph.frame = NSRect(x: (bounds.width - 20) / 2, y: (bounds.height - 20) / 2, width: 20, height: 20)
        glyph.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        addSubview(glyph)

        handle.frame = bounds
        handle.autoresizingMask = [.width, .height]
        handle.toolTip = "Mind Machine: click or press ⌃⌥Space"
        handle.setAccessibilityIdentifier("pill-open")
        addSubview(handle)
    }

    required init?(coder: NSCoder) { fatalError("PillRootView is created in code only") }

    /// Applies the end state of an expand or collapse. Called inside an animation group (animated)
    /// or directly (instant, for Reduce Motion).
    func setExpandedAppearance(_ expanded: Bool, animated: Bool) {
        let content = animated ? self.content.animator() : self.content
        let glyph = animated ? self.glyph.animator() : self.glyph
        content.alphaValue = expanded ? 1 : 0
        glyph.alphaValue = expanded ? 0 : 1
    }

    // CGColor does not follow light/dark changes by itself.
    override func viewDidChangeEffectiveAppearance() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.borderColor = NSColor.separatorColor.cgColor
        }
    }
}

/// The pill and panel background. It draws in `draw(_:)` so the colour resolves against the current
/// appearance on every redraw and so PillSelfTest's cacheDisplay snapshots include it.
final class PillSurfaceView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        // A flat fill looks the same stretched, so window resizes during the animation reuse the drawn
        // contents instead of redrawing every frame; appearance changes still redraw below.
        layerContentsRedrawPolicy = .onSetNeedsDisplay
    }

    required init?(coder: NSCoder) { fatalError("PillSurfaceView is created in code only") }

    override func draw(_ dirtyRect: NSRect) {
        Greyscale.paper.nsColor.setFill()
        dirtyRect.fill()
    }

    override func viewDidChangeEffectiveAppearance() { needsDisplay = true }
}
