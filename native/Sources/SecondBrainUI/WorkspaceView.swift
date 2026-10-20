/* Native Capture/Find/Chat presentation shared by the iPhone companion and Mac
 hotkey panel. The keyboard has its own UIKit editor and keyplane controller. */
import SwiftUI
import SecondBrainCore

public struct WorkspaceView: View {
    @ObservedObject private var model: VaultModel
    @State private var openTasks = false
    @State private var showSettings = false

    public init(model: VaultModel) { self.model = model }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Picker("Workspace", selection: $model.mode) {
                    Text("Capture").tag(0)
                    Text("Find").tag(1)
                    Text("Chat").tag(2)
                }.pickerStyle(.segmented).accessibilityIdentifier("workspace-mode")
                Button { showSettings.toggle() } label: { Image(systemName: "gearshape") }
                    .accessibilityLabel("Settings")
            }
            // Saved is displayed only after the model's coordinated write succeeds.
            if let error = model.error {
                HStack { Text(error); Button("Dismiss") { model.error = nil } }.font(.caption)
            }
            if let notice = model.notice { Text(notice).font(.caption).accessibilityIdentifier("save-status") }
            if showSettings { settings }
            else if let id = model.selectedCapture, let original = model.vault.captures.first(where: { $0.id == id }) {
                originalView(original)
            } else {
                switch model.mode {
                case 0: capture
                case 1: find
                default: chat
                }
            }
            Text("Local vault · sync not connected").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(16)
        .tint(.primary)
        .onChange(of: model.mode) { _, _ in model.selectedCapture = nil; model.reload() }
    }

    // The private draft survives mode changes; Save clears it only after persistence.
    private var capture: some View {
        VStack(alignment: .leading) {
            Text("What’s on your mind?").font(.headline)
            TextEditor(text: $model.draft).accessibilityLabel("Private note").accessibilityIdentifier("capture-editor")
                .font(.body).frame(minHeight: 150)
            HStack {
                Text("No filing needed").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Save") { model.saveCapture() }.keyboardShortcut(.return, modifiers: .command)
                    .disabled(model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("save-capture")
            }
        }
    }

    // Find reads the shared retrieval path and opens originals without changing drafts.
    private var find: some View {
        VStack(alignment: .leading) {
            TextField("Find something you saved", text: $model.query).textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("find-query")
            Toggle("Open tasks", isOn: $openTasks).toggleStyle(.switch)
            Text(model.searchDescription).font(.caption).foregroundStyle(.secondary)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(model.results(openTasks: openTasks)) { original in
                        Button { model.selectedCapture = original.id } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(original.text).lineLimit(3).multilineTextAlignment(.leading)
                                Text(original.createdAt, style: .date).font(.caption).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(10)
                                .background(Color.primary.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius: 8))
                        }.buttonStyle(.plain).accessibilityIdentifier("capture-result")
                    }
                    if model.results(openTasks: openTasks).isEmpty { Text("Nothing found yet").foregroundStyle(.secondary) }
                }
            }
        }
    }

    // Original inspection is independent of editing; returning preserves the query.
    private func originalView(_ original: Capture) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("Back to Find") { model.selectedCapture = nil; model.mode = 1 }
            Text(original.createdAt, style: .date).font(.caption)
            ScrollView { Text(original.text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
        }
    }

    // Inference is configured by the person; the empty state never invents replies.
    private var chat: some View {
        VStack {
            Toggle("Temporary · retains nothing new", isOn: Binding(get: { model.temporary }, set: {
                if $0 { model.temporary = true } else { model.endTemporary() }
            }))
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(model.conversation) { message in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(message.role.rawValue.capitalized).font(.caption).foregroundStyle(.secondary)
                            Text(message.text).textSelection(.enabled)
                            ForEach(message.sourceCaptureIDs, id: \.self) { id in
                                Button("Open source") { model.selectedCapture = id }
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            TextField("Ask your vault", text: $model.chatDraft, axis: .vertical).textFieldStyle(.roundedBorder)
            Button(model.busy ? "Waiting for your model…" : "Send") { Task { await model.sendMessage() } }
                .disabled(model.busy || model.chatDraft.isEmpty)
        }
    }

    // Server and privacy configuration stay visible; no inference runs on editing them.
    private var settings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inference settings").font(.headline)
            Text("Chat needs a running Ollama-compatible server. On iPhone, localhost means the phone itself.").font(.caption)
            TextField("Server URL", text: $model.endpoint).textFieldStyle(.roundedBorder)
            TextField("Model", text: $model.modelName).textFieldStyle(.roundedBorder)
            Toggle("Allow cloud AI processing", isOn: $model.cloudOptIn)
            Text("Sync and cloud AI are separate. Private device sync is not connected in this build.").font(.caption)
            Spacer()
        }
    }
}
