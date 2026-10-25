/* Native Capture/Recall/Chat presentation shared by the iPhone companion (Apps/iOS/MindMachineApp.swift)
 and the Mac floating pill (Apps/Mac/PillPanelView.swift). The keyboard has its own UIKit editor and
 keyplane controller. Colours, buttons and fields come from Greyscale.swift; the caller paints the
 background and supplies the outer margins. The pill embeds it with showsHeader: false and draws its own
 Capture/Recall tabs; the companion keeps the default header.

 Layout: the Capture editor is the page itself, with its prompt inside it. One footer row runs along the
 bottom of every mode: a small sync glyph on the left (SyncIndicator.swift decides how much it says and
 it opens the sync setup sheet), the latest acknowledgement, and in Capture the one prominent action,
 Save, with its shortcut. Recall shows matches as RecallCards two wide on the Mac (RecallCards.swift, with
 the grid rules in RecallGrid.swift) and as rows on the iPhone. The Mac grid searches and redraws one
 run-loop turn after the query field, from a result page kept in state, so neither the search nor the
 grid's layout delays the typed letter. PillAcceptanceTests and PillSelfTest drive these controls by
 identifier. */
import SwiftUI
import MindMachineCore

public struct WorkspaceView: View {
    @ObservedObject private var model: VaultModel
    @State private var openTasks = false
    /// The Recall card the keyboard has selected, kept by note so a reload that reorders results keeps it.
    @State private var recallSelection: UUID?
    /// The query the Mac Recall grid is showing. It follows `model.query` one run-loop turn later, so a
    /// keystroke's frame draws only the typed letter and the grid redraws in the next frame.
    @State private var shownQuery = ""
    /// The Mac Recall result page for `shownQuery`, kept between renders. The body re-runs on every
    /// keystroke; reading this page instead of searching keeps SQLite and JSON decoding out of that frame.
    @State private var recallPage = RecallCardGrid.Page()
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
            if model.mode == 0 && model.selectedCapture == nil { ReminderOfferView(model: model) }
            if showSettings { ScrollView { settings } }
            else if let original = selectedOriginal {
                originalView(original)
            } else {
                switch model.mode {
                case 0: capture
                case 1: recall
                default: chat
                }
            }
            footer
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
        .foregroundStyle(Greyscale.ink.color)
        .tint(Greyscale.ink.color)
        .onChange(of: model.mode) { _, _ in model.selectedCapture = nil; model.reload() }
    }

    // The private draft survives mode changes; Save clears it only after persistence.
    // The editor fills the space between the tabs and the footer; the prompt is its placeholder.
    private var capture: some View {
        RichNoteEditor(text: $model.draft, richText: $model.richDraft, prompt: "What’s on your mind?")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The saved capture open in the reader, if any; the body and the footer both decide from this.
    private var selectedOriginal: Capture? {
        model.selectedCapture.flatMap { id in model.vault.captures.first { $0.id == id } }
    }

    /// True while the Capture page (not the reader or settings) is showing, which is when Save belongs in the footer.
    private var capturing: Bool { !showSettings && selectedOriginal == nil && model.mode == 0 }

    // The bottom row of every mode. Left: sync, quiet unless it needs the person. Right: the latest
    // acknowledgement, then Save in Capture. "Saved on this device" refers to the previous note, so it
    // steps aside once the next one is being written; it returns with the next save.
    private var footer: some View {
        HStack(spacing: 12) {
            syncIndicator
            Spacer(minLength: 8)
            if let notice = model.notice, !(capturing && !model.draft.isEmpty) {
                Text(notice).font(.caption).foregroundStyle(Greyscale.inkSecondary.color).lineLimit(1)
                    .accessibilityIdentifier("save-status")
            }
            if capturing { saveButton }
        }
    }

    // The one prominent action. On the Mac the label carries its shortcut, so the hint is learnt by looking.
    private var saveButton: some View {
        Button { model.saveCapture() } label: {
            HStack(spacing: 6) {
                Text("Save")
                #if os(macOS)
                Text("⌘↩").font(.caption.weight(.medium)).opacity(0.6)
                #endif
            }
        }
        .keyboardShortcut(.return, modifiers: .command)
        .buttonStyle(GreyscaleButtonStyle(.prominent))
        .disabled(model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .help("Save (⌘↩)")
        .accessibilityLabel("Save")
        .accessibilityIdentifier("save-capture")
    }

    // Sync detail on demand: a glyph, with words only when sync is off or needs attention.
    // Clicking it opens the same setup sheet the former "Sync setup" button did.
    private var syncIndicator: some View {
        let indicator = SyncIndicator(status: model.syncStatus)
        return Button { showSyncSetup = true } label: {
            HStack(spacing: 5) {
                Image(systemName: indicator.symbol).font(.caption)
                if let label = indicator.label {
                    Text(label).font(.caption).lineLimit(1).truncationMode(.tail)
                        .accessibilityIdentifier("sync-status")
                }
            }
            .foregroundStyle(indicator.level == .attention ? Greyscale.inkSecondary.color : Greyscale.inkTertiary.color)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("\(indicator.detail). Click for sync details.")
        .accessibilityLabel("Sync")
        .accessibilityValue(indicator.detail)
        .accessibilityIdentifier("sync-setup")
    }

    // Recall reads the shared retrieval path and opens originals without changing drafts.
    // It mirrors the Capture page: the query is typed on the page in the writing font above one hairline,
    // and the filter and search note share one small line. On the Mac, matches are cards two wide
    // (RecallCards.swift) that the arrow keys move through from the query; the iPhone keeps
    // hairline-separated rows, which suit its narrow width.
    private var recall: some View {
        // One result page serves the results, the empty-state line and the keyboard. The body re-runs on
        // every keystroke, timer reload and sync-status change. On the Mac the page is searched only when
        // the shown query, the filter or the vault changes (refreshRecallPage), so the arrow keys and Return
        // act on the cards that are on screen. The iPhone searches once per render.
        #if os(macOS)
        let hits = recallPage.hits
        #else
        let hits = model.searchHits(openTasks: openTasks)
        #endif
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(Greyscale.inkTertiary.color)
                    .accessibilityHidden(true)
                #if os(macOS)
                RecallQueryField(text: $model.query, placeholder: "Recall something you saved",
                                 onMove: { moveSelection($0, in: hits) }, onSubmit: { openSelection(in: hits) })
                    .frame(maxWidth: .infinity)
                #else
                TextField("Recall something you saved", text: $model.query).textFieldStyle(.plain)
                    .font(RichTextEditing.writingFont)
                    .accessibilityIdentifier("recall-query")
                #endif
            }
            .padding(.bottom, 8)
            .overlay(alignment: .bottom) { Rectangle().fill(Greyscale.hairline.color).frame(height: 1) }
            HStack(spacing: 8) {
                Text(model.searchDescription).font(.caption2).foregroundStyle(Greyscale.inkTertiary.color)
                    .lineLimit(1).accessibilityIdentifier("search-description")
                Spacer(minLength: 8)
                Toggle("Open tasks", isOn: $openTasks).toggleStyle(.switch).controlSize(.mini)
                    .font(.caption).foregroundStyle(Greyscale.inkSecondary.color).tint(Greyscale.prominent.color)
                    .fixedSize().accessibilityIdentifier("open-tasks-toggle")
            }
            ScrollViewReader { proxy in
                ScrollView {
                    if hits.isEmpty {
                        Text("Nothing found yet").foregroundStyle(Greyscale.inkSecondary.color).padding(.top, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("recall-empty")
                    } else {
                        #if os(macOS)
                        // Compared before its body runs: a keystroke changes neither the page nor the
                        // selection, so the grid and its cards are not rebuilt in the typed letter's frame.
                        RecallCardGrid(page: recallPage, selection: recallSelection) { id in
                            recallSelection = id
                            model.selectedCapture = id
                        }
                        .equatable()
                        #else
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(hits, id: \.capture.id) { hit in
                                let original = hit.capture
                                Button { model.selectedCapture = original.id } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(SearchPreview.attributed(hit.highlightedText)).lineLimit(3).multilineTextAlignment(.leading)
                                            .foregroundStyle(Greyscale.ink.color)
                                        HStack(spacing: 6) {
                                            Text(original.createdAt, style: .date).foregroundStyle(Greyscale.inkTertiary.color)
                                            if model.vault.isOverdue(captureID: original.id, now: Date()) {
                                                Text("Overdue").bold().foregroundStyle(Greyscale.ink.color)
                                            }
                                        }.font(.caption)
                                    }
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .overlay(alignment: .bottom) { Rectangle().fill(Greyscale.hairline.color).frame(height: 1) }
                                    .contentShape(Rectangle())
                                }.buttonStyle(.plain).accessibilityIdentifier("capture-result")
                            }
                        }
                        #endif
                    }
                }
                // Keep the keyboard selection in view; nil anchor scrolls only as far as needed.
                .onChange(of: recallSelection) { _, id in
                    if let id { proxy.scrollTo(id) }
                }
            }
        }
        // A new query or filter is a new result set, so the selection starts again from the query.
        // The grid takes the new query after this frame has drawn the typed letter. The block reads the
        // query when it runs, so several keys typed within one turn produce one grid update.
        .onChange(of: model.query) { _, _ in
            clearSelection()
            #if os(macOS)
            DispatchQueue.main.async {
                if shownQuery != model.query { shownQuery = model.query; refreshRecallPage() }
            }
            #endif
        }
        #if os(macOS)
        // The query can change while Recall is off screen (another mode, or the pill collapsed).
        .onAppear { shownQuery = model.query; refreshRecallPage() }
        // Saves, timer reloads and sync replace the vault, which can change matches and Overdue marks.
        // Array equality returns early when the captures are the same storage, as they are while typing.
        .onChange(of: model.vault) { _, _ in refreshRecallPage() }
        #endif
        .onChange(of: openTasks) { _, _ in
            clearSelection()
            #if os(macOS)
            refreshRecallPage()
            #endif
        }
    }

    #if os(macOS)
    /// Searches the shown query once and keeps the page, with each card's Overdue mark worked out here
    /// so drawing a card reads no vault state.
    private func refreshRecallPage() {
        let hits = model.searchHits(openTasks: openTasks, query: shownQuery)
        let now = Date()
        let overdue = Set(hits.map(\.capture.id).filter { model.vault.isOverdue(captureID: $0, now: now) })
        recallPage = RecallCardGrid.Page(hits: hits, overdue: overdue)
    }
    #endif

    /// Clearing only when set avoids a second render on every keystroke.
    private func clearSelection() { if recallSelection != nil { recallSelection = nil } }

    /// Applies one arrow key to the card selection. Returns false when the key belongs to the query's caret.
    private func moveSelection(_ direction: RecallGrid.Direction, in hits: [SearchHit]) -> Bool {
        let current = recallSelection.flatMap { id in hits.firstIndex { $0.capture.id == id } }
        switch RecallGrid.move(from: current, direction, count: hits.count) {
        case .select(let index): recallSelection = hits[index].capture.id; return true
        case .field: recallSelection = nil; return true
        case .ignored: return false
        }
    }

    /// Return opens the selected card, or the first match when nothing is selected, as Spotlight does.
    private func openSelection(in hits: [SearchHit]) {
        let selected = recallSelection.flatMap { id in hits.first { $0.capture.id == id } }
        guard let hit = selected ?? hits.first else { return }
        recallSelection = hit.capture.id
        model.selectedCapture = hit.capture.id
    }

    // Original inspection is independent of editing; returning preserves the query.
    private func originalView(_ original: Capture) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // A quiet back link, as in Notes and Mail, rather than a filled button competing with the text.
            Button { model.selectedCapture = nil; model.mode = 1 } label: {
                Label("Back to Recall", systemImage: "chevron.left").font(.subheadline)
            }
            .buttonStyle(.plain).foregroundStyle(Greyscale.inkSecondary.color).accessibilityIdentifier("back-to-recall")
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
                        Text(original.text).font(RichTextEditing.writingFont).textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
