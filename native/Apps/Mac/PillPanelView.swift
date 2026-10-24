/* SwiftUI content of the expanded pill panel: a Capture / Recall tab strip with a disabled "Soon" slot for
 a third mode, a close button, and the shared WorkspaceView underneath (embedded without its own header,
 so its behaviour is unchanged). PillViewModel carries the selected tab from PillController into this
 view, and the tab taps back out. Created once by PillController (PillController.swift) inside
 PillRootView (PillRootView.swift); PillAcceptanceTests uses the tab and close identifiers for the real
 UI journey and PillSelfTest snapshots this view.

 The whole panel is one flat greyscale page with grain: tabs are plain words, the note editor below is
 the page, and the left edge of the first tab lines up with the first letter of the note. */
import SwiftUI
import MindMachinePill
import MindMachineUI

/// Bridge between the AppKit controller and the SwiftUI header. The controller is the source of truth
/// for the mode (it owns the state machine); this object only mirrors it and forwards taps.
@MainActor
final class PillViewModel: ObservableObject {
    @Published var mode: PillMode = .capture
    @Published var reduceMotion = false
    var onSelect: (PillMode) -> Void = { _ in }
    var onClose: () -> Void = {}
}

struct PillPanelView: View {
    @ObservedObject var pill: PillViewModel
    @ObservedObject var model: VaultModel

    /// Page margin shared by the tabs and the workspace, so tab text and note text start on one line.
    static let margin: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            header
            WorkspaceView(model: model, showsHeader: false)
                .padding(.horizontal, Self.margin).padding(.top, 10).padding(.bottom, 14)
        }
        // Fixed to the final panel size: the window animates its frame around this content instead of
        // the content re-laying out on every animation frame.
        .frame(width: PillGeometry.panelSize.width, height: PillGeometry.panelSize.height, alignment: .top)
        .background { Greyscale.paper.color.overlay(GrainOverlay()) }
    }

    // Plain-word tabs: the selected one is full ink and semibold, the others secondary. Shortcuts live in
    // the tooltip, because Cmd-1/Cmd-2 are learnt once and the labels are read every time.
    private var header: some View {
        HStack(spacing: 18) {
            ForEach(PillMode.allCases, id: \.rawValue) { mode in tab(mode) }
            Spacer()
            Button { pill.onClose() } label: {
                Image(systemName: "xmark").font(.system(size: 10, weight: .semibold))
                    .frame(width: 24, height: 24).contentShape(Rectangle())
            }
            .buttonStyle(.plain).foregroundStyle(Greyscale.inkTertiary.color)
            .help("Close (Esc)").accessibilityLabel("Close")
            .accessibilityIdentifier("pill-close")
        }
        .padding(.leading, Self.margin).padding(.trailing, 12).padding(.top, 8)
    }

    @ViewBuilder
    private func tab(_ mode: PillMode) -> some View {
        let selected = pill.mode == mode
        if mode.isAvailable {
            Button { pill.onSelect(mode) } label: {
                // The semibold copy reserves the width, so selecting a tab never shifts its neighbours.
                Text(mode.title).font(.system(size: 13, weight: .semibold)).hidden()
                    .overlay {
                        Text(mode.title).font(.system(size: 13, weight: selected ? .semibold : .regular))
                            .foregroundStyle(selected ? Greyscale.ink.color : Greyscale.inkSecondary.color)
                    }
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                    .animation(pill.reduceMotion ? nil : .easeOut(duration: PillMotion.modeSwitch), value: selected)
            }
            .buttonStyle(.plain)
            .help("\(mode.title) (\(mode == .capture ? "⌘1" : "⌘2"))")
            .accessibilityLabel(mode.title)
            .accessibilityIdentifier("pill-mode-\(mode.rawValue)")
            .accessibilityAddTraits(selected ? .isSelected : [])
        } else {
            // PLACEHOLDER: third mode, to be specified by the founder. Disabled until then; it reads as a
            // fainter word in the same row rather than a dashed box.
            Text(mode.title).font(.system(size: 13)).foregroundStyle(Greyscale.inkTertiary.color)
                .padding(.vertical, 5)
                .help("Reserved for a third mode, not available yet")
                .accessibilityLabel("Third mode, not available yet")
                .accessibilityAddTraits(.isStaticText)
        }
    }
}
