/* SwiftUI content of the expanded pill panel: a Capture / Recall tab strip with a disabled placeholder
 slot for a third mode, a close button, and the shared WorkspaceView underneath (embedded without its
 own header, so its behaviour is unchanged). PillViewModel carries the selected tab from PillController
 into this view, and the tab taps back out. Created once by PillController (PillController.swift);
 PillAcceptanceTests uses the tab and close identifiers for the real UI journey. */
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

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.5)
            WorkspaceView(model: model, showsHeader: false)
        }
        // Fixed to the final panel size: the window animates its frame around this content instead of
        // the content re-laying out on every animation frame.
        .frame(width: PillGeometry.panelSize.width, height: PillGeometry.panelSize.height, alignment: .top)
    }

    private var header: some View {
        HStack(spacing: 6) {
            ForEach(PillMode.allCases, id: \.rawValue) { mode in tab(mode) }
            Spacer()
            Button { pill.onClose() } label: {
                Image(systemName: "xmark").font(.system(size: 11, weight: .semibold))
                    .frame(width: 24, height: 24).contentShape(Rectangle())
            }
            .buttonStyle(.plain).foregroundStyle(.secondary)
            .help("Close (Esc)").accessibilityLabel("Close")
            .accessibilityIdentifier("pill-close")
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    @ViewBuilder
    private func tab(_ mode: PillMode) -> some View {
        let selected = pill.mode == mode
        if mode.isAvailable {
            Button { pill.onSelect(mode) } label: {
                HStack(spacing: 6) {
                    Text(mode.title).font(.system(size: 13, weight: selected ? .semibold : .regular))
                    Text(mode == .capture ? "⌘1" : "⌘2").font(.system(size: 10)).foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(Color.primary.opacity(selected ? 0.12 : 0)))
                .contentShape(Capsule())
                .animation(pill.reduceMotion ? nil : .easeOut(duration: PillMotion.modeSwitch), value: selected)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("pill-mode-\(mode.rawValue)")
            .accessibilityAddTraits(selected ? .isSelected : [])
        } else {
            // PLACEHOLDER: third mode, to be specified by the founder. Disabled until then.
            Text(mode.title).font(.system(size: 13)).foregroundStyle(.tertiary)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .overlay(Capsule().strokeBorder(Color.primary.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
                .help("Reserved for a third mode, not available yet")
                .accessibilityLabel("Third mode, not available yet")
                .accessibilityAddTraits(.isStaticText)
        }
    }
}
