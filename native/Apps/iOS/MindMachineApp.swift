/* iPhone companion entry point: setup, a test host composer and vault access.
 It also owns process-lifetime foreground notification presentation.
 The embedded Keyboard target is the primary phone Capture/Find/Chat surface. */
import SwiftUI
import MindMachineUI

@main
@MainActor
struct MindMachineApp: App {
    init() { installReminderNotificationPresentation() }
    var body: some Scene { WindowGroup { CompanionView() } }
}

private struct CompanionView: View {
    @State private var hostDraft = ""
    @State private var showVault = false
    private let storage = Result { try DeviceVault.sharedURL() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Your vault, in your keyboard").font(.title2.bold())
                    Text("Enable Mind Machine in Settings → General → Keyboard → Keyboards → Add New Keyboard. Then enable Full Access so the keyboard can share your vault on this device.")
                    Text("Full Access is an iOS permission. This build saves locally; private device sync is not connected.")
                        .font(.caption).foregroundStyle(.secondary)
                    if case .failure(let error) = storage { Text(error.localizedDescription).font(.caption) }
                    Button("Open vault and settings") { showVault = true }
                }.frame(maxWidth: .infinity, alignment: .leading).padding()
            }
            .navigationTitle("Mind Machine")
            .navigationBarTitleDisplayMode(.inline)
            // Only the conversation/setup content scrolls away. This test host
            // pins its composer above the entire keyboard workspace at any height.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("KEYBOARD TEST HOST").font(.caption).foregroundStyle(.secondary)
                    TextField("Message in this app", text: $hostDraft, axis: .vertical)
                        .textFieldStyle(.roundedBorder).accessibilityIdentifier("host-composer")
                }.padding(12).background(.background)
            }
            .sheet(isPresented: $showVault) {
                switch storage {
                case .success(let url): VaultScreen(url: url)
                case .failure(let error): Text(error.localizedDescription).padding()
                }
            }
        }.tint(.primary)
    }
}

private struct VaultScreen: View {
    @StateObject private var model: VaultModel
    init(url: URL) { _model = StateObject(wrappedValue: VaultModel(url: url)) }
    var body: some View { WorkspaceView(model: model) }
}
