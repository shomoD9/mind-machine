/* iPhone companion entry point: setup, a test host composer and vault access.
 It also owns process-lifetime foreground notification presentation and installs the
 greyscale UIKit appearance (GreyscaleAppearance in MindMachineUI) for system controls.
 The embedded Keyboard target is the primary phone Capture/Recall/Chat surface. */
import SwiftUI
import MindMachineUI

@main
@MainActor
struct MindMachineApp: App {
    init() {
        installReminderNotificationPresentation()
        GreyscaleAppearance.install()
    }
    var body: some Scene { WindowGroup { CompanionView() } }
}

private struct CompanionView: View {
    @State private var hostDraft = ""
    @State private var showVault = false
    @State private var keyboardMemory = "Open the keyboard to measure its process footprint and OS memory headroom."
    @FocusState private var composerFocused: Bool
    private let storage = Result { try DeviceVault.sharedURL() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Setup: what to enable and why, with the one action that opens Settings.
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your vault, in your keyboard").font(.title2.weight(.semibold))
                            .foregroundStyle(Greyscale.ink.color).accessibilityIdentifier("companion-title")
                        Text("Enable Mind Machine in Settings → General → Keyboard → Keyboards → Add New Keyboard. Then enable Full Access so the keyboard can share your vault on this device.")
                            .foregroundStyle(Greyscale.ink.color).accessibilityIdentifier("companion-setup-steps")
                        Text("Full Access lets the keyboard use the shared App Group and connect to your private iCloud database. Host typing is never captured as a note. Secure fields and apps that block custom keyboards use Apple’s keyboard.")
                            .font(.caption).foregroundStyle(Greyscale.inkSecondary.color).accessibilityIdentifier("companion-full-access-note")
                        if case .failure(let error) = storage {
                            Text(error.localizedDescription).font(.caption).foregroundStyle(Greyscale.ink.color)
                                .accessibilityIdentifier("companion-storage-error")
                        }
                        Button("Open iOS Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }.buttonStyle(GreyscaleButtonStyle(.prominent)).accessibilityIdentifier("open-ios-settings")
                    }.greyscaleCard()
                    PrivateSyncSetupView().greyscaleCard()
                    // Keyboard health: the extension writes its measured footprint into the shared container.
                    VStack(alignment: .leading, spacing: 10) {
                        Text(keyboardMemory).font(.caption).foregroundStyle(Greyscale.inkSecondary.color)
                            .accessibilityIdentifier("keyboard-memory-report")
                        HStack(spacing: 8) {
                            Button("Refresh keyboard memory report") {
                                if case .success(let url) = storage,
                                   let text = try? String(contentsOf: url.deletingLastPathComponent().appendingPathComponent("keyboard-memory.txt")) { keyboardMemory = text }
                            }.buttonStyle(GreyscaleButtonStyle()).accessibilityIdentifier("refresh-keyboard-memory")
                        }
                        Button("Open vault and settings") { showVault = true }
                            .buttonStyle(GreyscaleButtonStyle()).accessibilityIdentifier("open-vault")
                    }.greyscaleCard()
                }.frame(maxWidth: .infinity, alignment: .leading).padding()
            }
            .greyscaleCanvas()
            .navigationTitle("Mind Machine")
            .navigationBarTitleDisplayMode(.inline)
            // Only the conversation/setup content scrolls away. This test host
            // pins its composer above the entire keyboard workspace at any height.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    GreyscaleSectionLabel("KEYBOARD TEST HOST").accessibilityIdentifier("host-composer-label")
                    TextField("Message in this app", text: $hostDraft, axis: .vertical)
                        .textFieldStyle(GreyscaleFieldStyle()).accessibilityIdentifier("host-composer")
                        .focused($composerFocused)
                }
                .padding(12)
                .background { Greyscale.canvas.color.overlay(GrainOverlay()).ignoresSafeArea() }
                .overlay(alignment: .top) { Rectangle().fill(Greyscale.hairline.color).frame(height: 1) }
            }
            .sheet(isPresented: $showVault) {
                switch storage {
                case .success(let url): VaultScreen(url: url)
                case .failure(let error): Text(error.localizedDescription).padding()
                        .foregroundStyle(Greyscale.ink.color).accessibilityIdentifier("vault-storage-error")
                }
            }
        }
        .tint(Greyscale.ink.color)
        .task { await applyScreenshotArguments() }
    }

    // Debug builds only: native-ci's simulator screenshot step (Scripts/simulator_screenshots.sh)
    // launches with these arguments to reach the vault sheet or raise the keyboard without taps.
    private func applyScreenshotArguments() async {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        try? await Task.sleep(for: .milliseconds(600))
        if arguments.contains("-open-vault") { showVault = true }
        if arguments.contains("-focus-host-composer") { composerFocused = true }
        #endif
    }
}

private struct VaultScreen: View {
    @StateObject private var model: VaultModel
    init(url: URL) { _model = StateObject(wrappedValue: VaultModel(url: url)) }
    var body: some View { WorkspaceView(model: model).greyscaleCanvas() }
}
