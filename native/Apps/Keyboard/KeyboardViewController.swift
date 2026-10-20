/* Primary iPhone workspace, loaded by iOS as the embedded keyboard extension.
 It routes custom keys to its private editor or the host's textDocumentProxy,
 and uses VaultModel for the same persisted capture/find operations as Mac. */
import UIKit
import Combine
import SecondBrainCore
import SecondBrainUI

@MainActor
final class KeyboardViewController: UIInputViewController, UITextViewDelegate {
    private let stack = UIStackView()
    private let editor = UITextView()
    private let results = UIStackView()
    private let scroll = UIScrollView()
    private let status = UILabel()
    private let destination = UIButton(type: .system)
    private let save = UIButton(type: .system)
    private let modes = UISegmentedControl(items: ["Capture", "Find", "Chat"])
    private let keyplane = UIStackView()
    private var model: VaultModel?
    private var subscriptions: Set<AnyCancellable> = []
    private var hostInput = false
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
        let workspaceHeight = view.heightAnchor.constraint(equalToConstant: 500)
        workspaceHeight.priority = .defaultHigh
        workspaceHeight.isActive = true
        stack.axis = .vertical; stack.spacing = 6; stack.translatesAutoresizingMaskIntoConstraints = false
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
        stack.addArrangedSubview(modes)
        destination.setTitle("Typing into: Private note", for: .normal)
        destination.addTarget(self, action: #selector(toggleDestination), for: .touchUpInside)
        destination.accessibilityIdentifier = "typing-destination"
        stack.addArrangedSubview(destination)
        // The text view is a real local editor. Suppress a second system keyplane;
        // this extension supplies its own buttons and retains selection locally.
        editor.font = .preferredFont(forTextStyle: .body)
        editor.backgroundColor = .secondarySystemBackground
        editor.layer.cornerRadius = 6
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
        scroll.heightAnchor.constraint(equalToConstant: 100).isActive = true
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
        model?.mode = modes.selectedSegmentIndex
        selected = nil
        hostInput = false
        refreshMode()
    }

    // Rebind the visible editor to the selected mode without touching host text.
    private func refreshMode() {
        guard let model else { save.isEnabled = false; return }
        editor.text = model.mode == 0 ? model.draft : model.mode == 1 ? model.query : model.chatDraft
        editor.isEditable = selected == nil
        editor.accessibilityLabel = model.mode == 0 ? "Private note" : model.mode == 1 ? "Find saved material" : "Private chat message"
        save.setTitle(model.mode == 0 ? "Save note" : model.mode == 1 ? "Search" : "Send to model", for: .normal)
        refreshDestination()
        renderResults()
    }

    // A displayed original is read-only and must never replace a writing draft.
    private func retainDraft() {
        guard let model, selected == nil else { return }
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
        case 0: model.saveCapture(); editor.text = model.draft
        case 1: model.reload(); renderResults()
        default:
            Task { await model.sendMessage(); editor.text = model.chatDraft; renderResults() }
        }
    }

    // Results retain original IDs. Only the explicit Insert action writes to the host.
    private func renderResults() {
        guard let model else { return }
        results.arrangedSubviews.forEach { $0.removeFromSuperview() }
        scroll.isHidden = model.mode == 0
        if let selected {
            let back = UIButton(type: .system)
            back.setTitle("Back to results", for: .normal)
            back.addAction(UIAction { [weak self] _ in self?.selected = nil; self?.refreshMode() }, for: .touchUpInside)
            results.addArrangedSubview(back)
            let insert = UIButton(type: .system)
            insert.setTitle("Insert original into app", for: .normal)
            insert.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                self.editor.resignFirstResponder()
                self.hostInput = true; self.refreshDestination()
                self.sendingToHost = true
                self.textDocumentProxy.insertText(selected.text)
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
                    self?.editor.text = original.text
                    self?.editor.isEditable = false
                    self?.renderResults()
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

    // Host taps do not reliably emit a selection callback at an unchanged caret.
    // Keep an explicit destination control; actual cross-host tap proof is pending.
    @objc private func toggleDestination() {
        hostInput.toggle()
        if hostInput { editor.resignFirstResponder() }
        refreshDestination()
    }

    private func refreshDestination() {
        destination.setTitle(hostInput ? "Typing into: App" : "Typing into: Private \(model?.mode == 1 ? "search" : model?.mode == 2 ? "chat" : "note")", for: .normal)
    }

    func textViewDidBeginEditing(_ textView: UITextView) { hostInput = false; refreshDestination() }
    func textViewDidChange(_ textView: UITextView) { retainDraft() }
    override func selectionDidChange(_ textInput: UITextInput?) {
        super.selectionDidChange(textInput)
        if !editor.isFirstResponder && !sendingToHost { hostInput = true; refreshDestination() }
    }

    // The selected destination receives this key; host input is never retained as a note.
    private func insert(_ text: String) {
        if hostInput {
            sendingToHost = true; textDocumentProxy.insertText(text); sendingToHost = false
        } else if selected == nil {
            editor.insertText(text); retainDraft()
        }
    }

    @objc private func typeKey(_ sender: UIButton) { insert(sender.currentTitle ?? "") }
    @objc private func space() { insert(" ") }
    @objc private func newline() { insert("\n") }
    @objc private func backspace() {
        if hostInput { sendingToHost = true; textDocumentProxy.deleteBackward(); sendingToHost = false }
        else if selected == nil { editor.deleteBackward(); retainDraft() }
    }
    @objc private func toggleShift() { shift.toggle(); buildKeys() }
    @objc private func toggleNumbers() { numbers.toggle(); buildKeys() }
    @objc private func nextKeyboard() { retainDraft(); advanceToNextInputMode() }
}
