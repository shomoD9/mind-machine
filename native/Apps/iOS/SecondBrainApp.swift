/* iPhone companion entry point: setup, a test host composer and vault access.
 The embedded Keyboard target is the primary phone Capture/Find/Chat surface. */
import SwiftUI
import SecondBrainUI

@main
struct SecondBrainApp: App {
    var body: some Scene { WindowGroup { CompanionView() } }
}

private struct CompanionView: View {
    @State private var hostDraft = ""
    @State private var showVault = false
    private let storage = Result { try DeviceVault.sharedURL() }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Your vault, in your keyboard").font(.title2.bold())
                Text("Enable Second brain in Settings → General → Keyboard → Keyboards → Add New Keyboard. Then enable Full Access so the keyboard can share your vault on this device.")
                Text("Full Access is an iOS permission. This build saves locally; private device sync is not connected.")
                    .font(.caption).foregroundStyle(.secondary)
                if case .failure(let error) = storage { Text(error.localizedDescription).font(.caption) }
                Button("Open vault and settings") { showVault = true }
                Spacer()
                Text("KEYBOARD TEST HOST").font(.caption).foregroundStyle(.secondary)
                Text("Tap below, switch keyboards with the globe, then capture or find a note. This message stays in this app.").font(.callout)
                // The safe-area follows the entire keyboard extension, including
                // its expanded pad. The host composer belongs to this app.
                TextField("Message in this app", text: $hostDraft, axis: .vertical)
                    .textFieldStyle(.roundedBorder).accessibilityIdentifier("host-composer")
            }.padding().navigationTitle("Second brain")
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
