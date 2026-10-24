/* Primary iPhone workspace, loaded by iOS as the embedded keyboard extension (Info.plist
 NSExtensionPrincipalClass). The panel above the keys holds the private editor, Recall results
 and reminder controls; the keys are KeyboardKit's Apple-style KeyboardView. Every key reaches
 the typing destination through RoutedTextProxy: the private editor, or the host's
 textDocumentProxy. VaultModel supplies the same persisted capture/recall operations as Mac.
 Panel styling comes from KeyboardPanelStyle.swift; key sounds from InputClickFeedback.swift;
 the hosted keys from KeyplaneView.swift. */
import UIKit
import SwiftUI
import Combine
import KeyboardKit
import MindMachineCore
import MindMachineUI

@MainActor
final class KeyboardViewController: KeyboardInputViewController, UITextViewDelegate, UIGestureRecognizerDelegate, TextRouteOwner {
    #if KEYBOARD_UI_TEST_HOST
    // Only the separate UI-test app compiles these OS-boundary adapters. All workspace,
    // keyplane, routing validation and persistence operations below remain production code.
    var uiTestVaultURL: URL!
    var uiTestHostProxy: UITextDocumentProxy!
    private let uiTestPrivateProxy = RoutedTextProxy()
    override var originalTextDocumentProxy: UITextDocumentProxy {
        editor.isFirstResponder ? uiTestPrivateProxy : uiTestHostProxy
    }
    #endif
    // iOS can retarget its proxy to the host while the local editor stays active.
    // Capture local identity after editing begins; avoid proxy access at startup.
    private var privateDocument: UUID?
    private var hostDocumentProxy: UITextDocumentProxy?

    private let root = UIStackView()
    private let stack = UIStackView()
    private let grain = GrainView()
    private let editor = RoutingTextView()
    private let privateTap = UITapGestureRecognizer()
    private let results = UIStackView()
    private let scroll = UIScrollView()
    private let status = PanelStyle.label(id: "keyboard-status")
    private let notificationStatus = PanelStyle.label(id: "keyboard-notification-status")
    private var openTasks = false
    // The accepted editing target and zone are frozen while choosing a date.
    private struct ReminderSession {
        let captureID: UUID
        let reminderID: UUID?
        let zone: TimeZone
        var date: Date
    }
    private var reminderSession: ReminderSession?
    private var savingReminder = false
    private lazy var destination = PanelStyle.button("Typing into: Private note", id: "typing-destination", kind: .chip,
                                                     font: .systemFont(ofSize: 13, weight: .medium)) { [weak self] in self?.toggleDestination() }
    private lazy var save = PanelStyle.button("Save note", id: "keyboard-save", kind: .prominent) { [weak self] in self?.primaryAction() }
    private let modes = UISegmentedControl(items: ["Capture", "Recall"])
    private let toolRow = UIStackView()
    private let formatting = UIStackView()
    private lazy var sizeButton = PanelStyle.button("Size: Default", id: "pad-size", kind: .quiet,
                                                    font: .systemFont(ofSize: 13, weight: .medium)) { [weak self] in self?.changeSize() }
    // KeyboardKit's keys, hosted once below the panel. Keys write only through `router`.
    private var keys: UIHostingController<AnyView>?
    private let router = RoutedTextProxy()
    private var keysRouteToHost: Bool?
    private var workspace = KeyboardWorkspace()
    private var workspaceHeight: NSLayoutConstraint?
    private var resultsHeight: NSLayoutConstraint?
    private var restoringEditor = false
    private var model: VaultModel?
    private var subscriptions: Set<AnyCancellable> = []
    private var hostInput: Bool {
        get { workspace.destination == .app }
        set { workspace.selectDestination(newValue ? .app : .privatePad) }
    }
    private var height: NSLayoutConstraint?
    private var selected: Capture?
    private var sendingToHost = false
    private var pendingSearch: DispatchWorkItem?
    private var previousQuery = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        configureKeyboardKit()
        // Refuse isolated keyboard storage. Full Access and the common signed
        // group must both work before any private capture can be accepted.
        #if KEYBOARD_UI_TEST_HOST
        hostDocumentProxy = uiTestHostProxy
        model = VaultModel(url: uiTestVaultURL, notificationAccess: .disabled)
        #else
        do {
            guard hasFullAccess else { throw DeviceVault.StorageError.sharedContainerUnavailable }
            model = VaultModel(url: try DeviceVault.sharedURL(), notificationAccess: .keyboard)
        } catch { status.text = error.localizedDescription }
        #endif
        buildWorkspace()
        if let model {
            model.$vault.sink { [weak self] _ in DispatchQueue.main.async { self?.renderResults() } }.store(in: &subscriptions)
            model.$deviceNotificationStatus.sink { [weak self] in self?.notificationStatus.text = $0 }.store(in: &subscriptions)
            model.$notice.combineLatest(model.$error).sink { [weak self] notice, error in
                self?.status.text = error ?? notice ?? "Private note · saved locally when you tap Save"
            }.store(in: &subscriptions)
        }
        refreshMode()
        recordMemory()
    }

    // Store the actual extension footprint/headroom in the shared container for
    // companion setup. Sampling never loads the corpus or a semantic model.
    private func recordMemory() {
        #if !KEYBOARD_UI_TEST_HOST
        guard let memory = ProcessMemory.sample(), let url = try? DeviceVault.sharedURL() else { return }
        let headroom = memory.availableMiB.map { String(format: "%.1f", $0) } ?? "unavailable"
        let report = "Keyboard footprint: \(String(format: "%.1f", memory.footprintMiB)) MiB · OS headroom: \(headroom) MiB · \(Date().formatted())"
        try? Data(report.utf8).write(to: url.deletingLastPathComponent().appendingPathComponent("keyboard-memory.txt"), options: .atomic)
        #endif
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        pendingSearch?.cancel()
        results.arrangedSubviews.forEach { $0.removeFromSuperview() }
        recordMemory()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Each activation opens Capture while retaining other mode drafts.
        retainDraft()
        model?.activateCapture()
        modes.selectedSegmentIndex = 0
        workspace.selectMode(.capture)
        selected = nil; reminderSession = nil; hostInput = false
        refreshMode()
    }

    // viewDidLoad samples before KeyboardKit renders; this sample includes the visible keys.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.recordMemory() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        retainDraft()
        pendingSearch?.cancel()
        super.viewWillDisappear(animated)
    }

    // KeyboardKit reads and writes the active document through `textInputProxy`; pointing it at
    // the router makes every key, word-delete, double-space period and space-bar drag follow
    // the typing destination. Sound follows the system Keyboard Clicks setting.
    private func configureKeyboardKit() {
        router.owner = self
        state.keyboardContext.textInputProxy = router
        let feedback = InputClickFeedbackService()
        services.feedbackService = feedback
        (services.actionHandler as? KeyboardAction.StandardActionHandler)?.feedbackService = feedback
        // KeyboardKit's initial setup runs asynchronously after viewDidLoad and copies the host
        // field's keyboard type. Capture starts in the private note, so restore its layout after it.
        DispatchQueue.main.async { [weak self] in self?.syncKeysWithRoute(force: true) }
    }

    // KeyboardKit calls this on every appearance. The panel owns the view hierarchy, so the
    // keys are hosted once inside it instead of replacing the whole extension view.
    override func viewWillSetupKeyboardView() {
        guard keys == nil else { return }
        // KeyplaneView observes the keyboard context so case and layer changes rebuild the layout.
        let keyboard = KeyplaneView(state: state, services: services, context: state.keyboardContext)
            .keyboardState(state)
        let host = UIHostingController(rootView: AnyView(keyboard))
        host.sizingOptions = .intrinsicContentSize
        host.safeAreaRegions = []
        host.view.backgroundColor = .clear
        host.view.accessibilityIdentifier = "keyboard-keys"
        host.view.setContentHuggingPriority(.required, for: .vertical)
        host.view.setContentCompressionResistancePriority(.required, for: .vertical)
        addChild(host)
        root.addArrangedSubview(host.view)
        host.didMove(toParent: self)
        keys = host
        applyPadSize()
    }

    private func buildWorkspace() {
        // A flat neutral backdrop with grain sits behind the panel and between the keys.
        view.backgroundColor = Greyscale.backdrop.uiColor
        view.tintColor = Greyscale.ink.uiColor
        grain.frame = view.bounds
        grain.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(grain)
        // Request enough extension space for the private pad plus keyplane.
        // The system/host still owns the final available height.
        inputView?.allowsSelfSizing = true
        workspaceHeight = view.heightAnchor.constraint(equalToConstant: 520)
        workspaceHeight?.priority = .defaultHigh
        workspaceHeight?.isActive = true
        // The root stack holds the padded panel, then the full-width keys (added by viewWillSetupKeyboardView).
        root.axis = .vertical; root.spacing = 0; root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            root.topAnchor.constraint(equalTo: view.topAnchor),
            root.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        stack.axis = .vertical; stack.spacing = 7
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = .init(top: 8, leading: 8, bottom: 4, trailing: 8)
        root.addArrangedSubview(stack)
        modes.selectedSegmentIndex = 0
        modes.addTarget(self, action: #selector(changeMode), for: .valueChanged)
        modes.accessibilityIdentifier = "keyboard-mode"
        PanelStyle.styleSegments(modes)
        let header = UIStackView(arrangedSubviews: [modes, sizeButton])
        header.spacing = 8; header.alignment = .center
        modes.setContentHuggingPriority(.defaultLow, for: .horizontal)
        modes.heightAnchor.constraint(equalToConstant: 32).isActive = true
        sizeButton.setContentHuggingPriority(.required, for: .horizontal)
        sizeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        stack.addArrangedSubview(header)
        // Destination on the left, formatting on the right: one quiet row above the note.
        destination.setContentHuggingPriority(.defaultLow, for: .horizontal)
        destination.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        toolRow.spacing = 6; toolRow.alignment = .center
        toolRow.addArrangedSubview(destination)
        // The text view is a real local editor. Suppress a second system keyplane;
        // this extension supplies its own keys and retains selection locally.
        editor.font = .preferredFont(forTextStyle: .body)
        PanelStyle.styleEditor(editor)
        // Rich formatting stays inside the private note. Search and chat remain
        // plain inputs, and authored checkboxes retain their visible source glyph.
        editor.allowsEditingTextAttributes = true
        // Captured fragments and queries remain as authored. Native spelling
        // replacements also open word popovers on a single tap, before edit-menu
        // customization; disable them here while retaining selection/copy/paste.
        editor.spellCheckingType = .no
        editor.autocorrectionType = .no
        formatting.spacing = 2
        formatting.setContentHuggingPriority(.required, for: .horizontal)
        for format in NoteFormat.allCases {
            // Titles stay as authored ("Bold", "Italic", "•", "☐"); the font previews the effect.
            let font: UIFont = format == .bold ? .systemFont(ofSize: 14, weight: .bold)
                : format == .italic ? .italicSystemFont(ofSize: 14) : .systemFont(ofSize: 16, weight: .regular)
            let control = PanelStyle.button(format.rawValue, id: "keyboard-format-\(format == .checkbox ? "checkbox" : format == .bullet ? "bullet" : format.rawValue.lowercased())",
                                            kind: .chip, font: font) { [weak self] in self?.formatNote(format) }
            control.accessibilityLabel = format == .checkbox ? "Checkbox" : format == .bullet ? "Bullet" : format.rawValue
            formatting.addArrangedSubview(control)
        }
        toolRow.addArrangedSubview(formatting)
        stack.addArrangedSubview(toolRow)
        // Local first-responder status can survive a host tap. Explicit input
        // routing also covers hardware keys, which otherwise bypass the keyplane.
        privateTap.addTarget(self, action: #selector(selectPrivatePad))
        privateTap.cancelsTouchesInView = false
        privateTap.delegate = self
        editor.addGestureRecognizer(privateTap)
        editor.routeHostInsert = { [weak self] text in
            guard let self, self.hostInput else { return false }
            self.insert(text); return true
        }
        editor.routeHostDelete = { [weak self] in
            guard let self, self.hostInput else { return false }
            self.backspace(); return true
        }
        editor.delegate = self
        editor.inputView = UIView(frame: .zero)
        editor.accessibilityLabel = "Private note"
        editor.accessibilityIdentifier = "keyboard-editor"
        stack.addArrangedSubview(editor)
        height = editor.heightAnchor.constraint(equalToConstant: 110)
        height?.isActive = true
        scroll.addSubview(results)
        scroll.accessibilityIdentifier = "keyboard-results"
        results.axis = .vertical; results.spacing = 6; results.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            results.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            results.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            results.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            results.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            results.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])
        resultsHeight = scroll.heightAnchor.constraint(equalToConstant: 110)
        resultsHeight?.isActive = true
        stack.addArrangedSubview(scroll)
        // Status on the left, the primary action on the right. The system globe key
        // (or KeyboardKit's own globe on Home-button iPhones) switches keyboards.
        let actions = UIStackView(arrangedSubviews: [status, save])
        actions.spacing = 10; actions.alignment = .center
        status.setContentHuggingPriority(.defaultLow, for: .horizontal)
        status.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        save.setContentHuggingPriority(.required, for: .horizontal)
        save.setContentCompressionResistancePriority(.required, for: .horizontal)
        stack.addArrangedSubview(actions)
        notificationStatus.isHidden = true
        stack.addArrangedSubview(notificationStatus)
        // Any height the host grants beyond the requested size, or takes away, lands here
        // rather than stretching or squeezing the note, results or keys.
        let slack = UIView()
        slack.setContentHuggingPriority(UILayoutPriority(1), for: .vertical)
        slack.setContentCompressionResistancePriority(UILayoutPriority(1), for: .vertical)
        stack.addArrangedSubview(slack)
    }

    // Save the outgoing private field before selecting another workspace mode.
    @objc private func changeMode() {
        retainDraft()
        workspace.selectMode(KeyboardWorkspace.Mode(rawValue: modes.selectedSegmentIndex) ?? .capture)
        model?.mode = workspace.mode.rawValue
        selected = nil; reminderSession = nil
        refreshMode()
    }

    // Rebind the visible editor to the selected mode without touching host text.
    private func refreshMode() {
        guard let model else { save.isEnabled = false; return }
        restoringEditor = true
        let draft = workspace.draft
        if let original = selected.flatMap({ source in model.vault.captures.first { $0.id == source.id } }) {
            RichTextEditing.restore(text: original.text, richText: original.richText, in: editor)
        } else {
            RichTextEditing.restore(text: draft.text, richText: draft.richText, in: editor)
            RichTextEditing.setSelection(draft.selection, in: editor)
            editor.setContentOffset(CGPoint(x: 0, y: draft.scrollOffset), animated: false)
        }
        restoringEditor = false
        editor.isEditable = selected == nil
        editor.accessibilityLabel = model.mode == 0 ? "Private note" : model.mode == 1 ? "Recall saved material" : "Private chat message"
        updatePrimaryTitle()
        refreshDestination()
        // A new mode or a cleared note starts a sentence; let autocapitalisation decide shift.
        setKeyboardCase(state.keyboardContext.preferredKeyboardCase)
        renderResults()
        applyPadSize()
    }

    // A displayed original is read-only and must never replace a writing draft.
    private func retainDraft() {
        guard let model, selected == nil, !restoringEditor else { return }
        let rich = model.mode == 0 ? try? RichTextEditing.encoded(editor.attributedText) : nil
        workspace.edit(PrivateDraft(text: editor.text, selection: editor.selectedRange,
                                    richText: rich, scrollOffset: editor.contentOffset.y))
        if model.mode == 0 { model.richDraft = rich }
        switch model.mode {
        case 0: model.draft = editor.text
        case 1:
            model.query = editor.text
            if previousQuery != model.query {
                previousQuery = model.query
                pendingSearch?.cancel()
                let work = DispatchWorkItem { [weak self] in
                    guard self?.model?.mode == 1 else { return }
                    self?.renderResults()
                }
                pendingSearch = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.025, execute: work)
            }
        default: model.chatDraft = editor.text
        }
        updatePrimaryTitle()
    }

    // A saved action offers scheduling without blocking the next capture. As
    // soon as writing resumes, the same primary control saves the new draft.
    private func updatePrimaryTitle() {
        guard let model else { return }
        let offer = workspace.draft.text.isEmpty && model.offeredCapture != nil
        PanelStyle.setTitle(model.mode == 0 ? (offer ? "Add reminder?" : "Save note") : model.mode == 1 ? "Recall live" : "Send to model", on: save)
    }

    // All saves flow through coordinated persistence; Search has no write side effect.
    private func primaryAction() {
        guard let model else { return }
        retainDraft()
        switch model.mode {
        case 0:
            if workspace.draft.text.isEmpty, let id = model.offeredCapture {
                beginReminder(captureID: id); return
            }
            model.saveCapture()
            if model.draft.isEmpty { workspace.edit(PrivateDraft()) }
            refreshMode()
        case 1: model.reload(); renderResults()
        default:
            let outgoingText = workspace.draft.text
            Task {
                await model.sendMessage()
                // An answer may finish after the user switches modes or writes a
                // new draft. Acknowledge only the unchanged outgoing field.
                if model.chatDraft.isEmpty { workspace.acknowledgeSentDraft(outgoingText, in: .chat) }
                if workspace.mode == .chat { refreshMode() }
                renderResults()
            }
        }
    }

    // Results retain original IDs. Only the explicit Insert action writes to the host.
    private func renderResults() {
        guard let model else { return }
        results.arrangedSubviews.forEach { $0.removeFromSuperview() }
        scroll.isHidden = model.mode == 0 || workspace.size == .minimised
        if let session = reminderSession {
            renderReminderEditor(session)
            return
        }
        if let selected = selected.flatMap({ model.original($0.id) }) {
            let back = PanelStyle.button("Back to results", id: "keyboard-back-to-results") { [weak self] in
                self?.selected = nil; self?.refreshMode()
            }
            let insert = PanelStyle.button("Insert original into app", id: "keyboard-insert-original", kind: .prominent) { [weak self] in
                guard let self else { return }
                self.hostInput = true; self.refreshDestination()
                guard let proxy = self.hostProxyForWriting() else { return }
                self.sendingToHost = true
                proxy.insertText(selected.text)
                self.status.text = "Inserted original into app"
                UISelectionFeedbackGenerator().selectionChanged()
                self.sendingToHost = false
            }
            // Back and Insert share one row; the remaining controls stack beneath.
            let originalActions = UIStackView(arrangedSubviews: [back, UIView(), insert])
            originalActions.spacing = 8; originalActions.alignment = .center
            results.addArrangedSubview(originalActions)
            // Completion mutates linked checklist state, never the original text.
            for item in selected.checklist {
                addResultButton("\(item.complete ? "☑" : "☐") \(item.text)", id: "keyboard-checklist-item") { [weak self] in
                    self?.model?.setItem(captureID: selected.id, itemID: item.id, complete: !item.complete)
                }
            }
            if model.vault.isOverdue(captureID: selected.id, now: Date()) { addResultLabel("Overdue", id: "keyboard-overdue") }
            if let reminder = model.vault.reminders.first(where: { $0.captureID == selected.id && $0.status != .cancelled }) {
                addResultLabel(reminderDateLabel(reminder), id: "keyboard-reminder-date")
                if !selected.allItemsComplete {
                    addResultButton("Edit reminder", id: "keyboard-edit-reminder", kind: .quiet) { [weak self] in self?.beginReminder(captureID: selected.id, reminder: reminder) }
                }
                addResultButton("Remove reminder", id: "keyboard-remove-reminder", kind: .quiet) { [weak self] in self?.model?.removeReminder(id: reminder.id) }
            } else if !selected.allItemsComplete {
                addResultButton("Set reminder", id: "keyboard-set-reminder", kind: .quiet) { [weak self] in self?.beginReminder(captureID: selected.id) }
            } else { addResultLabel("Complete · no pending reminder", id: "keyboard-reminder-complete") }
        } else if model.mode == 1 {
            addResultButton(openTasks ? "Open tasks ✓ · Show all" : "Show Open tasks", id: "keyboard-open-tasks", kind: .quiet) { [weak self] in
                guard let self else { return }; self.openTasks.toggle(); self.renderResults()
            }
            let hits = model.searchHits(openTasks: openTasks)
            for hit in hits {
                let original = hit.capture
                let result = PanelStyle.button("", id: "keyboard-result", kind: .row) { [weak self] in
                    self?.selected = original
                    if let self {
                        self.restoringEditor = true
                        RichTextEditing.restore(text: original.text, richText: original.richText, in: self.editor)
                        self.restoringEditor = false
                        self.editor.isEditable = false
                        self.renderResults(); self.applyPadSize()
                    }
                }
                PanelStyle.setAttributedTitle(highlighted(hit.highlightedText), on: result)
                results.addArrangedSubview(result)
            }
            recordMemory()
            if hits.isEmpty { addResultLabel(model.query.isEmpty ? "Capture your first note to recall it here" : "No matches · try another remembered word", id: "keyboard-results-empty") }
        } else if model.mode == 2 {
            for message in model.conversation.suffix(8) {
                let label = PanelStyle.label(id: "keyboard-chat-message", font: .preferredFont(forTextStyle: .caption1), tone: Greyscale.ink, lines: 0)
                label.text = "\(message.role.rawValue.capitalized): \(message.text)"
                results.addArrangedSubview(label)
                if message.role == .reminder, let id = message.sourceCaptureIDs.first {
                    addResultButton("Open reminder source", id: "keyboard-open-reminder-source", kind: .quiet) { [weak self] in self?.openOriginal(id) }
                }
            }
        }
    }

    // FTS highlights are plain delimiters rather than HTML. The exact original
    // remains the Insert payload; bold styling affects only this result preview.
    private func highlighted(_ text: String) -> NSAttributedString {
        let output = NSMutableAttributedString(string: "")
        var matching = false
        for part in text.components(separatedBy: "⟦") {
            let pieces = part.components(separatedBy: "⟧")
            for (i,piece) in pieces.enumerated() {
                let font = matching && i == 0 ? UIFont.systemFont(ofSize: 15, weight: .semibold) : UIFont.systemFont(ofSize: 15)
                let tone = matching && i == 0 ? Greyscale.ink : Greyscale.inkSecondary
                output.append(NSAttributedString(string: String(piece.prefix(180)), attributes: [.font: font, .foregroundColor: tone.uiColor]))
                matching = false
            }
            matching = true
        }
        return output
    }

    // Reminder controls use the same model as Mac. Wheels stay inside the
    // extension; they temporarily replace keys instead of opening a host overlay.
    private func addResultLabel(_ text: String, id: String) {
        let label = PanelStyle.label(id: id, font: .preferredFont(forTextStyle: .caption1), lines: 0)
        label.text = text
        results.addArrangedSubview(label)
    }
    @discardableResult
    private func addResultButton(_ title: String, id: String, kind: PanelStyle.Kind = .row, action: @escaping () -> Void) -> UIButton {
        let control = PanelStyle.button(title, id: id, kind: kind, action: action)
        control.titleLabel?.numberOfLines = 0
        // Quiet controls keep their natural width; rows span the panel.
        if kind == .row { results.addArrangedSubview(control) }
        else {
            let line = UIStackView(arrangedSubviews: [control, UIView()])
            results.addArrangedSubview(line)
        }
        return control
    }
    private func openOriginal(_ id: UUID) {
        guard let capture = model?.original(id) else { return }
        retainDraft(); selected = capture
        restoringEditor = true
        RichTextEditing.restore(text: capture.text, richText: capture.richText, in: editor)
        restoringEditor = false; editor.isEditable = false
        renderResults(); applyPadSize()
    }
    private func beginReminder(captureID: UUID, reminder: Reminder? = nil) {
        guard let model else { return }; retainDraft()
        let zone = reminder.flatMap { TimeZone(identifier: $0.timeZoneID) } ?? .current
        reminderSession = ReminderSession(captureID: captureID, reminderID: reminder?.id, zone: zone,
                                          date: reminder?.dueAt ?? model.suggestedReminderDate(zone: zone))
        renderResults(); applyPadSize()
    }
    private func renderReminderEditor(_ session: ReminderSession) {
        addResultLabel(session.reminderID == nil ? "Choose a reminder" : "Edit reminder", id: "keyboard-reminder-title")
        addResultLabel("Whole capture/checklist · \(session.zone.identifier)", id: "keyboard-reminder-zone")
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime; picker.preferredDatePickerStyle = .wheels
        picker.timeZone = session.zone; picker.minimumDate = Date(); picker.date = max(session.date, Date())
        picker.heightAnchor.constraint(equalToConstant: 216).isActive = true
        picker.addAction(UIAction { [weak self, weak picker] _ in
            guard let picker else { return }; self?.reminderSession?.date = picker.date
        }, for: .valueChanged)
        picker.isEnabled = !savingReminder
        picker.tintColor = Greyscale.ink.uiColor
        picker.accessibilityIdentifier = "keyboard-reminder-picker"
        results.addArrangedSubview(picker)
        addResultButton(savingReminder ? "Saving…" : "Confirm date and reminder", id: "keyboard-confirm-reminder", kind: .prominent) { [weak self] in self?.confirmReminder() }.isEnabled = !savingReminder
        addResultButton("Cancel · keep original", id: "keyboard-cancel-reminder", kind: .quiet) { [weak self] in
            guard let self, !self.savingReminder else { return }
            self.reminderSession = nil; self.refreshMode()
        }.isEnabled = !savingReminder
    }
    private func confirmReminder() {
        guard let model, let session = reminderSession, !savingReminder else { return }
        guard session.date > Date() else { status.text = "Choose a future date and time."; return }
        savingReminder = true
        renderResults(); applyPadSize()
        Task {
            let saved: Bool
            if let id = session.reminderID { saved = await model.editReminder(id: id, date: session.date) }
            else { saved = await model.schedule(captureID: session.captureID, date: session.date, zone: session.zone.identifier) }
            savingReminder = false
            if saved { reminderSession = nil }
            refreshMode()
        }
    }

    // Resize adjusts constraints around the same live editor. It neither replaces
    // a draft nor resigns its responder, so collapsed notes keep receiving keys.
    private func changeSize() {
        retainDraft()
        let next = (workspace.size.rawValue + 1) % KeyboardWorkspace.PadSize.allCases.count
        workspace.resize(KeyboardWorkspace.PadSize(rawValue: next) ?? .standard)
        applyPadSize()
    }

    private func applyPadSize() {
        restoringEditor = true
        let padHeight: CGFloat
        let requestedHeight: CGFloat
        switch workspace.size {
        // Requested heights include KeyboardKit's four rows (about 216-224 pt in portrait).
        case .minimised: padHeight = 32; requestedHeight = 400
        case .standard: padHeight = 110; requestedHeight = 520
        case .expanded: padHeight = 240; requestedHeight = 670
        }
        let name = workspace.size == .minimised ? "Min" : workspace.size == .expanded ? "Expanded" : "Default"
        PanelStyle.setTitle("Size: \(name)", on: sizeButton)
        let choosingDate = reminderSession != nil
        modes.isEnabled = !savingReminder; sizeButton.isEnabled = !savingReminder
        editor.isHidden = choosingDate; keys?.view.isHidden = choosingDate
        save.isHidden = choosingDate; destination.isHidden = choosingDate
        notificationStatus.isHidden = !(choosingDate || selected != nil)
        formatting.isHidden = choosingDate || workspace.size == .minimised || model?.mode != 0 || selected != nil
        toolRow.isHidden = destination.isHidden && formatting.isHidden
        height?.constant = selected != nil ? max(32, padHeight / 2) : model?.mode == 0 ? padHeight : 36
        resultsHeight?.constant = choosingDate ? requestedHeight - 150 : selected != nil ? max(64, padHeight / 2) : padHeight
        scroll.isHidden = !choosingDate && selected == nil && (model?.mode == 0 || workspace.size == .minimised)
        workspaceHeight?.constant = requestedHeight
        view.layoutIfNeeded()
        restoringEditor = false
    }

    private func formatNote(_ format: NoteFormat) {
        guard model?.mode == 0, selected == nil, !hostInput else { return }
        RichTextEditing.apply(format, to: editor)
        retainDraft()
    }

    // Host taps do not reliably emit a selection callback at an unchanged caret.
    // Keep an explicit destination control; actual cross-host tap proof is pending.
    private func toggleDestination() {
        hostInput.toggle()
        if !hostInput, selected == nil { editor.becomeFirstResponder() }
        refreshDestination()
    }

    // Selection gestures can consume UITextView touches without delivering
    // touchesBegan. A simultaneous tap observes intent without blocking selection.
    @objc private func selectPrivatePad() {
        guard selected == nil else { return }
        hostInput = false; refreshDestination()
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer === privateTap || otherGestureRecognizer === privateTap
    }

    private func refreshDestination() {
        // Hiding geometry and selection UI survives native redraws; tint alone
        // does not define whether an insertion caret exists. Draft/caret stays stored.
        editor.isPrivateDestination = !hostInput
        PanelStyle.setTitle(hostInput ? "Typing into: App" : "Typing into: Private \(model?.mode == 1 ? "search" : model?.mode == 2 ? "chat" : "note")", on: destination)
        syncKeysWithRoute()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        privateDocument = originalTextDocumentProxy.documentIdentifier
        hostInput = false; refreshDestination()
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        // A real host tap may end the local responder even at an unchanged host
        // caret. Layout/mode changes themselves must never select host input.
        guard !restoringEditor else { return }
        retainDraft(); hostInput = true; refreshDestination()
    }
    func textViewDidChangeSelection(_ textView: UITextView) { retainDraft() }
    func scrollViewDidScroll(_ scrollView: UIScrollView) { retainDraft() }
    func textViewDidChange(_ textView: UITextView) { retainDraft() }
    override func selectionDidChange(_ textInput: UITextInput?) {
        super.selectionDidChange(textInput)
        if !editor.isFirstResponder && !sendingToHost && !restoringEditor { hostInput = true; refreshDestination() }
    }

    // Host text notifications are observed without reading or retaining content.
    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        let document = originalTextDocumentProxy.documentIdentifier
        // Only a proxy transition away from the active private document returns
        // keys to the host. Local activation emits this callback too, so a bare
        // text notification is insufficient. Keep the extension open rather than
        // resigning the local responder, which can restore the system keyboard.
        if !editor.isFirstResponder { hostDocumentProxy = originalTextDocumentProxy }
        if editor.isFirstResponder, let privateDocument, document != privateDocument,
           !sendingToHost, !restoringEditor {
            retainDraft()
            hostDocumentProxy = originalTextDocumentProxy
            hostInput = true
            refreshDestination()
        }
    }

    // Never fall back to the active private proxy for a host write. Refresh from
    // the current host if focus changed; otherwise use the last identified host.
    // A missing/invalid host fails visibly instead of mutating the note or recursing.
    private func hostProxyForWriting() -> UITextDocumentProxy? {
        let current = originalTextDocumentProxy
        if current.documentIdentifier != privateDocument { hostDocumentProxy = current }
        guard let hostDocumentProxy, hostDocumentProxy.documentIdentifier != privateDocument else {
            status.text = "Tap the app's message field before typing into App."
            return nil
        }
        return hostDocumentProxy
    }

    // The selected destination receives this input; host input is never retained as a note.
    // Hardware keys arrive here from RoutingTextView; on-screen keys reach the router directly.
    private func insert(_ text: String) { router.insertText(text) }
    private func backspace() { router.deleteBackward() }

    // KeyboardKit reads `textDocumentProxy` for its own context; the controller's routing
    // decisions use the system proxy (`originalTextDocumentProxy`) exactly as before.

    // MARK: TextRouteOwner — called by RoutedTextProxy for every key

    var privateEditorForTyping: UITextView? { !hostInput && selected == nil ? editor : nil }
    var routesToHost: Bool { hostInput }
    // Reading never shows the tap-the-field message; only a write does.
    var hostProxyForReading: UITextDocumentProxy? {
        let current = originalTextDocumentProxy
        return current.documentIdentifier != privateDocument ? current : hostDocumentProxy
    }
    func writeToHost(_ write: (UITextDocumentProxy) -> Void) {
        guard let proxy = hostProxyForWriting() else { return }
        sendingToHost = true; write(proxy); sendingToHost = false
    }
    func privateEditorDidChange() { retainDraft() }

    // The private note always uses the letter layout; the host's field chooses its own
    // (email, URL, number pad) as Apple's keyboard would. Case follows autocapitalisation.
    private func syncKeysWithRoute(force: Bool = false) {
        guard force || keysRouteToHost != hostInput else { return }
        keysRouteToHost = hostInput
        let context = state.keyboardContext
        let hostType = hostInput ? hostProxyForReading?.keyboardType?.keyboardType : nil
        context.keyboardType = hostType ?? .alphabetic
        setKeyboardCase(context.preferredKeyboardCase)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        PanelStyle.refreshBorders(editor)
    }
}

// The keyboard controller uses this editor to route basic hardware insertion
// and deletion to the host when the local responder remains active there.
@MainActor
private final class RoutingTextView: UITextView {
    // Both the insertion caret and range adornments belong to the active route.
    // This changes presentation only, leaving selectedTextRange and text intact.
    var isPrivateDestination = true {
        didSet {
            // Repeated label refreshes must not reactivate or rebuild selection UI.
            guard oldValue != isPrivateDestination else { return }
            tintColor = isPrivateDestination ? Greyscale.ink.uiColor : .clear
            for interaction in interactions {
                if let selection = interaction as? UITextSelectionDisplayInteraction {
                    selection.isActivated = isPrivateDestination
                    selection.setNeedsSelectionUpdate()
                }
                if !isPrivateDestination, let menu = interaction as? UIEditMenuInteraction { menu.dismissMenu() }
            }
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    override func caretRect(for position: UITextPosition) -> CGRect {
        isPrivateDestination ? super.caretRect(for: position) : .zero
    }
    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        isPrivateDestination ? super.selectionRects(for: range) : []
    }
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        isPrivateDestination && super.canPerformAction(action, withSender: sender)
    }

    var routeHostInsert: ((String) -> Bool)?
    var routeHostDelete: (() -> Bool)?

    override func insertText(_ text: String) {
        if routeHostInsert?(text) == true { return }
        super.insertText(text)
    }
    override func deleteBackward() {
        if routeHostDelete?() == true { return }
        super.deleteBackward()
    }
}
