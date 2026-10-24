/* Native Capture/Recall/Chat presentation shared by the iPhone companion and Mac
 hotkey panel. The keyboard has its own UIKit editor and keyplane controller.
 Colours, buttons and fields come from Greyscale.swift; the caller paints the background.
 The Mac floating pill (native/Apps/Mac/PillPanelView.swift) embeds it with showsHeader: false and
 draws its own Capture/Recall tabs; every other caller keeps the default header. */
import SwiftUI
import MindMachineCore

public struct WorkspaceView: View {
    @ObservedObject private var model: VaultModel
    @State private var openTasks = false
    @State private var showSettings = false
    @State private var showSyncSetup = false
    private let showsHeader: Bool

    /// `showsHeader: false` hides the mode picker and settings button for hosts that supply their own switcher.
    public init(model: VaultModel, showsHeader: Bool = true) {
        self.model = model
        self.showsHeader = showsHeader
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showsHeader { HStack {
                Picker("Workspace", selection: $model.mode) {
                    Text("Capture").tag(0)
                    Text("Recall").tag(1)
                    Text("Chat").tag(2)
                }.pickerStyle(.segmented).accessibilityIdentifier("workspace-mode")
                Button { showSettings.toggle() } label: {
                    Image(systemName: "gearshape").frame(width: 32, height: 32)
                        .background(showSettings ? Greyscale.fillPressed.color : Greyscale.fill.color, in: Circle())
                }
                .buttonStyle(.plain).foregroundStyle(Greyscale.ink.color)
                .accessibilityLabel("Settings").accessibilityIdentifier("workspace-settings")
            } }
            // Saved is displayed only after the model's coordinated write succeeds.
            if let error = model.error {
                HStack {
                    Text(error).accessibilityIdentifier("workspace-error")
                    Button("Dismiss") { model.error = nil }.accessibilityIdentifier("dismiss-error")
                }.font(.caption).foregroundStyle(Greyscale.ink.color)
            }
            if let notice = model.notice {
                Text(notice).font(.caption).foregroundStyle(Greyscale.inkSecondary.color).accessibilityIdentifier("save-status")
            }
            if model.mode == 0 && model.selectedCapture == nil { ReminderOfferView(model: model) }
            if showSettings { ScrollView { settings } }
            else if let id = model.selectedCapture, let original = model.vault.captures.first(where: { $0.id == id }) {
                originalView(original)
            } else {
                switch model.mode {
                case 0: capture
                case 1: recall
                default: chat
                }
            }
            HStack {
                Text(model.syncStatus).font(.caption2).foregroundStyle(Greyscale.inkSecondary.color)
                    .accessibilityIdentifier("sync-status")
                Spacer()
                Button("Sync setup") { showSyncSetup = true }.font(.caption)
                    .accessibilityIdentifier("sync-setup")
            }
        }
        .sheet(isPresented: $showSyncSetup) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    PrivateSyncSetupView()
                    Text(model.syncStatus).font(.caption).foregroundStyle(Greyscale.inkSecondary.color)
                        .accessibilityIdentifier("sync-setup-status")
                    HStack {
                        Button("Sync now") { Task { await model.syncNow() } }
                            .buttonStyle(GreyscaleButtonStyle()).accessibilityIdentifier("sync-now")
                        Spacer()
                        Button("Done") { showSyncSetup = false }
                            .buttonStyle(GreyscaleButtonStyle(.prominent)).accessibilityIdentifier("sync-setup-done")
                    }
                }.padding(20)
            }.frame(minWidth: 280, minHeight: 350).greyscaleCanvas().tint(Greyscale.ink.color)
        }
        .padding(16)
        .foregroundStyle(Greyscale.ink.color)
        .tint(Greyscale.ink.color)
        .onChange(of: model.mode) { _, _ in model.selectedCapture = nil; model.reload() }
    }

    // The private draft survives mode changes; Save clears it only after persistence.
    private var capture: some View {
        VStack(alignment: .leading) {
            Text("What’s on your mind?").font(.headline).accessibilityIdentifier("capture-heading")
            RichNoteEditor(text: $model.draft, richText: $model.richDraft)
                .font(.body).frame(minHeight: 150)
            HStack {
                Text("No filing needed").font(.caption).foregroundStyle(Greyscale.inkSecondary.color)
                    .accessibilityIdentifier("capture-hint")
                Spacer()
                Button("Save") { model.saveCapture() }.keyboardShortcut(.return, modifiers: .command)
                    .buttonStyle(GreyscaleButtonStyle(.prominent))
                    .disabled(model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("save-capture")
            }
        }
    }

    // Recall reads the shared retrieval path and opens originals without changing drafts.
    private var recall: some View {
        VStack(alignment: .leading) {
            TextField("Recall something you saved", text: $model.query).textFieldStyle(GreyscaleFieldStyle())
                .accessibilityIdentifier("recall-query")
            Toggle("Open tasks", isOn: $openTasks).toggleStyle(.switch).tint(Greyscale.prominent.color)
                .accessibilityIdentifier("open-tasks-toggle")
            Text(model.searchDescription).font(.caption).foregroundStyle(Greyscale.inkSecondary.color)
                .accessibilityIdentifier("search-description")
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    // One SQLite search per render serves both the list and the empty-state line;
                    // the body re-runs on every timer reload and sync-status change.
                    let hits = model.searchHits(openTasks: openTasks)
                    ForEach(hits, id: \.capture.id) { hit in
                        let original = hit.capture
                        Button { model.selectedCapture = original.id } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(SearchPreview.attributed(hit.highlightedText)).lineLimit(3).multilineTextAlignment(.leading)
                                Text(original.createdAt, style: .date).font(.caption).foregroundStyle(Greyscale.inkSecondary.color)
                                if model.vault.isOverdue(captureID: original.id, now: Date()) { Text("Overdue").font(.caption.bold()) }
                            }.foregroundStyle(Greyscale.ink.color).greyscaleCard(padding: 12)
                        }.buttonStyle(.plain).accessibilityIdentifier("capture-result")
                    }
                    if hits.isEmpty {
                        Text("Nothing found yet").foregroundStyle(Greyscale.inkSecondary.color).accessibilityIdentifier("recall-empty")
                    }
                }
            }
        }
    }

    // Original inspection is independent of editing; returning preserves the query.
    private func originalView(_ original: Capture) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("Back to Recall") { model.selectedCapture = nil; model.mode = 1 }
                .buttonStyle(GreyscaleButtonStyle()).accessibilityIdentifier("back-to-recall")
            // The entire reader scrolls, so long checklists cannot strand their
            // last items or reminder controls outside the phone/panel viewport.
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(original.createdAt, style: .date).font(.caption).foregroundStyle(Greyscale.inkSecondary.color)
                        .accessibilityIdentifier("original-date")
                    CaptureTasksView(model: model, captureID: original.id).id(original.id)
                    if let rich = original.richText,
                       let content = try? NSAttributedString(data: rich, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil),
                       content.string == original.text {
                        Text(AttributedString(content)).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("original-text")
                    } else {
                        Text(original.text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("original-text")
                    }
                }
            }
        }
    }

    // Inference is configured by the person; the empty state never invents replies.
    private var chat: some View {
        VStack {
            Toggle("Temporary · retains nothing new", isOn: Binding(get: { model.temporary }, set: {
                if $0 { model.temporary = true } else { model.endTemporary() }
            })).tint(Greyscale.prominent.color).accessibilityIdentifier("chat-temporary")
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(model.conversation) { message in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(message.role.rawValue.capitalized).font(.caption).foregroundStyle(Greyscale.inkSecondary.color)
                            Text(message.text).textSelection(.enabled)
                            if message.role == .reminder { Text("Reminder event · use Open source to edit or remove its schedule").font(.caption) }
                            ForEach(message.sourceCaptureIDs, id: \.self) { id in
                                Button("Open source") { model.selectedCapture = id }.accessibilityIdentifier("chat-open-source")
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).accessibilityIdentifier("chat-message")
                    }
                }
            }
            TextField("Ask your vault", text: $model.chatDraft, axis: .vertical).textFieldStyle(GreyscaleFieldStyle())
                .accessibilityIdentifier("chat-draft")
            Button(model.busy ? "Waiting for your model…" : "Send") { Task { await model.sendMessage() } }
                .buttonStyle(GreyscaleButtonStyle(.prominent))
                .disabled(model.busy || model.chatDraft.isEmpty).accessibilityIdentifier("chat-send")
        }
    }

    // Server and privacy configuration stay visible; no inference runs on editing them.
    private var settings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminder settings").font(.headline).accessibilityIdentifier("reminder-settings-heading")
            DatePicker("Default reminder time", selection: Binding(get: {
                let clock = model.defaultReminderTime
                return Calendar.current.date(bySettingHour: clock.hour, minute: clock.minute, second: 0, of: Date()) ?? Date()
            }, set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                model.setDefaultReminderTime(hour: parts.hour ?? 9, minute: parts.minute ?? 0)
            }), displayedComponents: .hourAndMinute).accessibilityIdentifier("default-reminder-time")
            Text(model.deviceNotificationStatus).font(.caption).foregroundStyle(Greyscale.inkSecondary.color)
                .accessibilityIdentifier("notification-status")
            Button("Enable device notifications") { Task { await model.enableNotifications() } }
                .buttonStyle(GreyscaleButtonStyle()).accessibilityIdentifier("enable-notifications")
            Text("Inference settings").font(.headline).accessibilityIdentifier("inference-settings-heading")
            Text("Chat needs a running Ollama-compatible server. On iPhone, localhost means the phone itself.").font(.caption)
                .foregroundStyle(Greyscale.inkSecondary.color)
            TextField("Server URL", text: $model.endpoint).textFieldStyle(GreyscaleFieldStyle()).accessibilityIdentifier("inference-endpoint")
            TextField("Model", text: $model.modelName).textFieldStyle(GreyscaleFieldStyle()).accessibilityIdentifier("inference-model")
            Toggle("Allow cloud AI processing", isOn: $model.cloudOptIn).tint(Greyscale.prominent.color)
                .accessibilityIdentifier("cloud-opt-in")
            Text("Sync and cloud AI are separate. Your sync key never authorizes cloud inference.").font(.caption)
                .foregroundStyle(Greyscale.inkSecondary.color)
            Spacer()
        }
    }
}
