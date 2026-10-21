/* Primary iPhone workspace, loaded by iOS as the embedded keyboard extension.
 It routes custom keys to its private editor or the host's textDocumentProxy,
 and uses VaultModel for the same persisted capture/find operations as Mac. */
import UIKit
import Combine
import SecondBrainCore
import SecondBrainUI

@MainActor
final class KeyboardViewController: UIInputViewController, UITextViewDelegate, UIGestureRecognizerDelegate {
    // iOS can retarget its proxy to the host while the local editor stays active.
    // Capture local identity after editing begins; avoid proxy access at startup.
    private var privateDocument: UUID?
    private var hostDocumentProxy: UITextDocumentProxy?

    private let stack = UIStackView()
    private let editor = RoutingTextView()
    private let privateTap = UITapGestureRecognizer()
    private let privateHold = UILongPressGestureRecognizer()
    private var allowsCaretMenu = false
    private let results = UIStackView()
    private let scroll = UIScrollView()
    private let status = UILabel()
    private let destination = UIButton(type: .system)
    private let save = UIButton(type: .system)
    private let modes = UISegmentedControl(items: ["Capture", "Find", "Chat"])
    private let keyplane = UIStackView()
    private let formatting = UIStackView()
    private let sizeButton = UIButton(type: .system)
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
    private var shift = false
    private var numbers = false
    private var height: NSLayoutConstraint?
    private var selected: Capture?
    private var sendingToHost = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Refuse isolated keyboard storage. Full Access and the common signed
        // group must both work before any private capture can be accepted.
        do {
            guard hasFullAccess else { throw DeviceVault.StorageError.sharedContainerUnavailable }
            model = VaultModel(url: try DeviceVault.sharedURL())
        } catch { status.text = error.localizedDescription }
        buildWorkspace()
        if let model {
            model.$vault.sink { [weak self] _ in DispatchQueue.main.async { self?.renderResults() } }.store(in: &subscriptions)
            model.$notice.combineLatest(model.$error).sink { [weak self] notice, error in
                self?.status.text = error ?? notice ?? "Private note · saved locally when you tap Save"
            }.store(in: &subscriptions)
        }
        refreshMode()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Each activation opens Capture while retaining other mode drafts.
        retainDraft()
        model?.activateCapture()
        modes.selectedSegmentIndex = 0
        workspace.selectMode(.capture)
        selected = nil; hostInput = false
        refreshMode()
    }

    override func viewWillDisappear(_ animated: Bool) {
        retainDraft()
        super.viewWillDisappear(animated)
    }

    private func buildWorkspace() {
        view.backgroundColor = .systemBackground
        view.tintColor = .label
        // Request enough extension space for the private pad plus keyplane.
        // The system/host still owns the final available height.
        inputView?.allowsSelfSizing = true
        workspaceHeight = view.heightAnchor.constraint(equalToConstant: 470)
        workspaceHeight?.priority = .defaultHigh
        workspaceHeight?.isActive = true
        stack.axis = .vertical; stack.spacing = 4; stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4)
        ])
        modes.selectedSegmentIndex = 0
        modes.addTarget(self, action: #selector(changeMode), for: .valueChanged)
        modes.accessibilityIdentifier = "keyboard-mode"
        let header = UIStackView(arrangedSubviews: [modes, sizeButton])
        header.spacing = 6
        modes.setContentHuggingPriority(.defaultLow, for: .horizontal)
        sizeButton.setContentHuggingPriority(.required, for: .horizontal)
        sizeButton.addTarget(self, action: #selector(changeSize), for: .touchUpInside)
        sizeButton.accessibilityIdentifier = "pad-size"
        stack.addArrangedSubview(header)
        destination.setTitle("Typing into: Private note", for: .normal)
        destination.addTarget(self, action: #selector(toggleDestination), for: .touchUpInside)
        destination.accessibilityIdentifier = "typing-destination"
        stack.addArrangedSubview(destination)
        // The text view is a real local editor. Suppress a second system keyplane;
        // this extension supplies its own buttons and retains selection locally.
        editor.font = .preferredFont(forTextStyle: .body)
        editor.backgroundColor = .secondarySystemBackground
        editor.layer.cornerRadius = 6
        // Rich formatting stays inside the private note. Search and chat remain
        // plain inputs, and authored checkboxes retain their visible source glyph.
        editor.allowsEditingTextAttributes = true
        formatting.distribution = .fillEqually
        for format in NoteFormat.allCases {
            let control = UIButton(type: .system)
            control.setTitle(format.rawValue, for: .normal)
            control.accessibilityLabel = format == .checkbox ? "Checkbox" : format == .bullet ? "Bullet" : format.rawValue
            control.addAction(UIAction { [weak self] _ in self?.formatNote(format) }, for: .touchUpInside)
            formatting.addArrangedSubview(control)
        }
        stack.addArrangedSubview(formatting)
        // Local first-responder status can survive a host tap. Explicit input
        // routing also covers hardware keys, which otherwise bypass our buttons.
        privateTap.addTarget(self, action: #selector(selectPrivatePad))
        privateTap.cancelsTouchesInView = false
        privateTap.delegate = self
        editor.addGestureRecognizer(privateTap)
        // A hold is deliberate menu intent; a simple destination tap is not.
        // Observe alongside UIKit so selection/loupe gestures remain native.
        privateHold.minimumPressDuration = 0.3
        privateHold.cancelsTouchesInView = false
        privateHold.delegate = self
        privateHold.addTarget(self, action: #selector(holdPrivatePad))
        editor.addGestureRecognizer(privateHold)
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
        let actions = UIStackView(); actions.distribution = .fillEqually
        save.addTarget(self, action: #selector(primaryAction), for: .touchUpInside)
        save.accessibilityIdentifier = "keyboard-save"
        actions.addArrangedSubview(save)
        let globe = button("Next keyboard", action: #selector(nextKeyboard))
        actions.addArrangedSubview(globe)
        stack.addArrangedSubview(actions)
        keyplane.axis = .vertical; keyplane.spacing = 5
        stack.addArrangedSubview(keyplane)
        buildKeys()
        status.numberOfLines = 2; status.font = .preferredFont(forTextStyle: .caption2)
        status.textColor = .secondaryLabel
        stack.addArrangedSubview(status)
    }

    private func button(_ title: String, action: Selector) -> UIButton {
        let control = UIButton(type: .system)
        control.setTitle(title, for: .normal)
        control.tintColor = .label
        control.addTarget(self, action: action, for: .touchUpInside)
        return control
    }

    private func buildKeys() {
        keyplane.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let rows = numbers ? [Array("1234567890"), Array("-/:;()$&@\""), Array(".,?!'#+=*")] :
            [Array("qwertyuiop"), Array("asdfghjkl"), Array("zxcvbnm")]
        for row in rows {
            let line = UIStackView(); line.spacing = 4; line.distribution = .fillEqually
            for character in row {
                let title = shift ? String(character).uppercased() : String(character)
                let key = button(title, action: #selector(typeKey(_:)))
                key.backgroundColor = .secondarySystemBackground; key.layer.cornerRadius = 5
                key.heightAnchor.constraint(equalToConstant: 38).isActive = true
                line.addArrangedSubview(key)
            }
            keyplane.addArrangedSubview(line)
        }
        let bottom = UIStackView(); bottom.spacing = 6; bottom.distribution = .fillEqually
        bottom.addArrangedSubview(button(shift ? "⇧ On" : "⇧", action: #selector(toggleShift)))
        bottom.addArrangedSubview(button(numbers ? "ABC" : "123", action: #selector(toggleNumbers)))
        bottom.addArrangedSubview(button("space", action: #selector(space)))
        bottom.addArrangedSubview(button("⌫", action: #selector(backspace)))
        bottom.addArrangedSubview(button("return", action: #selector(newline)))
        bottom.heightAnchor.constraint(equalToConstant: 40).isActive = true
        keyplane.addArrangedSubview(bottom)
    }

    // Save the outgoing private field before selecting another workspace mode.
    @objc private func changeMode() {
        retainDraft()
        workspace.selectMode(KeyboardWorkspace.Mode(rawValue: modes.selectedSegmentIndex) ?? .capture)
        model?.mode = workspace.mode.rawValue
        selected = nil
        refreshMode()
    }

    // Rebind the visible editor to the selected mode without touching host text.
    private func refreshMode() {
        guard let model else { save.isEnabled = false; return }
        restoringEditor = true
        let draft = workspace.draft
        RichTextEditing.restore(text: draft.text, richText: draft.richText, in: editor)
        RichTextEditing.setSelection(workspace.draft.selection, in: editor)
        editor.setContentOffset(CGPoint(x: 0, y: workspace.draft.scrollOffset), animated: false)
        restoringEditor = false
        editor.isEditable = selected == nil
        editor.accessibilityLabel = model.mode == 0 ? "Private note" : model.mode == 1 ? "Find saved material" : "Private chat message"
        save.setTitle(model.mode == 0 ? "Save note" : model.mode == 1 ? "Search" : "Send to model", for: .normal)
        refreshDestination()
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
        case 1: model.query = editor.text
        default: model.chatDraft = editor.text
        }
    }

    // All saves flow through coordinated persistence; Search has no write side effect.
    @objc private func primaryAction() {
        guard let model else { return }
        retainDraft()
        switch model.mode {
        case 0:
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
        if let selected {
            let back = UIButton(type: .system)
            back.setTitle("Back to results", for: .normal)
            back.addAction(UIAction { [weak self] _ in self?.selected = nil; self?.refreshMode() }, for: .touchUpInside)
            results.addArrangedSubview(back)
            let insert = UIButton(type: .system)
            insert.setTitle("Insert original into app", for: .normal)
            insert.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                self.hostInput = true; self.refreshDestination()
                guard let proxy = self.hostProxyForWriting() else { return }
                self.sendingToHost = true
                proxy.insertText(selected.text)
                self.sendingToHost = false
            }, for: .touchUpInside)
            results.addArrangedSubview(insert)
        } else if model.mode == 1 {
            for original in model.results() {
                let result = UIButton(type: .system)
                result.setTitle(String(original.text.prefix(100)), for: .normal)
                result.titleLabel?.numberOfLines = 2
                result.contentHorizontalAlignment = .leading
                result.tintColor = .label
                result.accessibilityIdentifier = "keyboard-result"
                result.addAction(UIAction { [weak self] _ in
                    self?.selected = original
                    if let self {
                        self.restoringEditor = true
                        RichTextEditing.restore(text: original.text, richText: original.richText, in: self.editor)
                        self.restoringEditor = false
                        self.editor.isEditable = false
                        self.renderResults(); self.applyPadSize()
                    }
                }, for: .touchUpInside)
                results.addArrangedSubview(result)
            }
            if results.arrangedSubviews.isEmpty { let label = UILabel(); label.text = "Nothing found yet"; results.addArrangedSubview(label) }
        } else if model.mode == 2 {
            for message in model.conversation.suffix(8) {
                let label = UILabel(); label.numberOfLines = 0; label.font = .preferredFont(forTextStyle: .caption1)
                label.text = "\(message.role.rawValue.capitalized): \(message.text)"
                results.addArrangedSubview(label)
            }
        }
    }

    // Resize adjusts constraints around the same live editor. It neither replaces
    // a draft nor resigns its responder, so collapsed notes keep receiving keys.
    @objc private func changeSize() {
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
        case .minimised: padHeight = 32; requestedHeight = 350
        case .standard: padHeight = 110; requestedHeight = 470
        case .expanded: padHeight = 240; requestedHeight = 620
        }
        let name = workspace.size == .minimised ? "Min" : workspace.size == .expanded ? "Expanded" : "Default"
        sizeButton.setTitle("Size: \(name)", for: .normal)
        formatting.isHidden = workspace.size == .minimised || model?.mode != 0 || selected != nil
        height?.constant = model?.mode == 0 || selected != nil ? padHeight : 36
        // Original inspection needs only Back/Insert below its document. Giving
        // that action area another full pad would crowd the host at Expanded size.
        resultsHeight?.constant = selected == nil ? padHeight : 64
        scroll.isHidden = model?.mode == 0 || workspace.size == .minimised
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
    @objc private func toggleDestination() {
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
        gestureRecognizer === privateTap || otherGestureRecognizer === privateTap ||
        gestureRecognizer === privateHold || otherGestureRecognizer === privateHold
    }

    // Clear menu intent at touch-down, before UIKit asks for menu contents.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer === privateTap || gestureRecognizer === privateHold { allowsCaretMenu = false }
        return true
    }
    @objc private func holdPrivatePad() {
        guard privateHold.state == .began else { return }
        selectPrivatePad()
        allowsCaretMenu = true
    }

    // A collapsed-caret tap only chooses where to type. A deliberate hold or a
    // selected range can show UIKit's editing actions; App routing never can.
    func textView(_ textView: UITextView, editMenuForTextIn range: NSRange,
                  suggestedActions: [UIMenuElement]) -> UIMenu? {
        guard !hostInput, allowsCaretMenu || range.length > 0 else { return UIMenu(children: []) }
        return nil
    }

    private func refreshDestination() {
        // Hiding geometry and selection UI survives native redraws; tint alone
        // does not define whether an insertion caret exists. Draft/caret stays stored.
        editor.isPrivateDestination = !hostInput
        destination.setTitle(hostInput ? "Typing into: App" : "Typing into: Private \(model?.mode == 1 ? "search" : model?.mode == 2 ? "chat" : "note")", for: .normal)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        privateDocument = textDocumentProxy.documentIdentifier
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
        let document = textDocumentProxy.documentIdentifier
        // Only a proxy transition away from the active private document returns
        // keys to the host. Local activation emits this callback too, so a bare
        // text notification is insufficient. Keep the extension open rather than
        // resigning the local responder, which can restore the system keyboard.
        if !editor.isFirstResponder { hostDocumentProxy = textDocumentProxy }
        if editor.isFirstResponder, let privateDocument, document != privateDocument,
           !sendingToHost, !restoringEditor {
            retainDraft()
            hostDocumentProxy = textDocumentProxy
            hostInput = true
            refreshDestination()
        }
    }

    // Never fall back to the active private proxy for a host write. Refresh from
    // the current host if focus changed; otherwise use the last identified host.
    // A missing/invalid host fails visibly instead of mutating the note or recursing.
    private func hostProxyForWriting() -> UITextDocumentProxy? {
        let current = textDocumentProxy
        if current.documentIdentifier != privateDocument { hostDocumentProxy = current }
        guard let hostDocumentProxy, hostDocumentProxy.documentIdentifier != privateDocument else {
            status.text = "Tap the app's message field before typing into App."
            return nil
        }
        return hostDocumentProxy
    }

    // The selected destination receives this key; host input is never retained as a note.
    private func insert(_ text: String) {
        if hostInput {
            guard let proxy = hostProxyForWriting() else { return }
            sendingToHost = true; proxy.insertText(text); sendingToHost = false
        } else if selected == nil {
            editor.insertText(text); retainDraft()
        }
    }

    @objc private func typeKey(_ sender: UIButton) { insert(sender.currentTitle ?? "") }
    @objc private func space() { insert(" ") }
    @objc private func newline() { insert("\n") }
    @objc private func backspace() {
        if hostInput {
            guard let proxy = hostProxyForWriting() else { return }
            sendingToHost = true; proxy.deleteBackward(); sendingToHost = false
        }
        else if selected == nil { editor.deleteBackward(); retainDraft() }
    }
    @objc private func toggleShift() { shift.toggle(); buildKeys() }
    @objc private func toggleNumbers() { numbers.toggle(); buildKeys() }
    @objc private func nextKeyboard() { retainDraft(); advanceToNextInputMode() }
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
            tintColor = isPrivateDestination ? .label : .clear
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
