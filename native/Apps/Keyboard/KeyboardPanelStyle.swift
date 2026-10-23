/* UIKit styling for the keyboard panel above the keys: the Capture/Recall switcher, Size and
 "Typing into" controls, formatting toolbar, note field, Save row, result rows and status
 labels. KeyboardViewController builds every panel control through these helpers. Colours
 come from MindMachineUI's Greyscale palette, so the panel stays strictly grey in light and
 dark appearance; the grain layer is the same dithered tile the companion app uses. */
import UIKit
import MindMachineUI

@MainActor
enum PanelStyle {
    enum Kind { case prominent, quiet, chip, row }

    static let controlFont = UIFont.systemFont(ofSize: 14, weight: .medium)
    static let prominentFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
    static let captionFont = UIFont.systemFont(ofSize: 12, weight: .regular)

    /// A configuration-based button. Titles change through `setTitle(_:on:)`, never setTitle(_:for:),
    /// so the greyscale attributes below always apply.
    static func button(_ title: String, id: String, kind: Kind = .quiet, font: UIFont? = nil,
                       action: @escaping () -> Void) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = kind == .chip ? 8 : 10
        configuration.titleLineBreakMode = .byTruncatingTail
        switch kind {
        case .prominent: configuration.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
        case .quiet: configuration.contentInsets = .init(top: 6, leading: 11, bottom: 6, trailing: 11)
        case .chip: configuration.contentInsets = .init(top: 5, leading: 9, bottom: 5, trailing: 9)
        case .row:
            configuration.contentInsets = .init(top: 9, leading: 12, bottom: 9, trailing: 12)
            configuration.titleAlignment = .leading
        }
        let button = UIButton(configuration: configuration)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        let titleFont = font ?? (kind == .prominent ? prominentFont : controlFont)
        // Pressed and disabled states are drawn here so UIKit's tinted defaults never appear.
        button.configurationUpdateHandler = { button in
            guard var updated = button.configuration else { return }
            let foreground: UIColor = !button.isEnabled ? Greyscale.inkTertiary.uiColor
                : kind == .prominent ? Greyscale.onProminent.uiColor
                : kind == .chip ? Greyscale.inkSecondary.uiColor : Greyscale.ink.uiColor
            updated.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var attributes = incoming
                attributes.font = titleFont
                attributes.foregroundColor = foreground
                return attributes
            }
            updated.baseForegroundColor = foreground
            updated.background.backgroundColor = background(kind, pressed: button.isHighlighted, enabled: button.isEnabled)
            if kind == .row {
                updated.background.strokeColor = Greyscale.hairline.uiColor
                updated.background.strokeWidth = 1
            }
            button.configuration = updated
        }
        if kind == .row { button.contentHorizontalAlignment = .leading }
        button.accessibilityIdentifier = id
        return button
    }

    private static func background(_ kind: Kind, pressed: Bool, enabled: Bool) -> UIColor {
        switch kind {
        case .prominent:
            return enabled ? Greyscale.prominent.uiColor.withAlphaComponent(pressed ? 0.8 : 1) : Greyscale.fill.uiColor
        case .quiet: return (pressed ? Greyscale.fillPressed : Greyscale.fill).uiColor
        case .chip: return pressed ? Greyscale.fill.uiColor : .clear
        case .row: return pressed ? Greyscale.fillPressed.uiColor : Greyscale.paper.uiColor
        }
    }

    static func setTitle(_ title: String, on button: UIButton) {
        guard button.configuration?.title != title else { return }
        button.configuration?.title = title
    }

    /// Result rows carry FTS match emphasis, so they take an attributed title.
    static func setAttributedTitle(_ title: NSAttributedString, on button: UIButton) {
        button.configuration?.attributedTitle = try? AttributedString(title, including: \.uiKit)
    }

    static func label(id: String, font: UIFont = captionFont, tone: Greyscale.Tone = Greyscale.inkSecondary, lines: Int = 2) -> UILabel {
        let label = UILabel()
        label.font = font
        label.textColor = tone.uiColor
        label.numberOfLines = lines
        label.accessibilityIdentifier = id
        return label
    }

    static func styleSegments(_ control: UISegmentedControl) {
        control.backgroundColor = Greyscale.fill.uiColor
        control.selectedSegmentTintColor = Greyscale.paper.uiColor
        control.setTitleTextAttributes([.foregroundColor: Greyscale.inkSecondary.uiColor,
                                        .font: UIFont.systemFont(ofSize: 13, weight: .medium)], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: Greyscale.ink.uiColor,
                                        .font: UIFont.systemFont(ofSize: 13, weight: .semibold)], for: .selected)
        control.setTitleTextAttributes([.foregroundColor: Greyscale.inkTertiary.uiColor], for: .disabled)
    }

    /// The note and query field: a paper card with a hairline edge.
    static func styleEditor(_ editor: UITextView) {
        editor.backgroundColor = Greyscale.paper.uiColor
        editor.layer.cornerRadius = 12
        editor.layer.cornerCurve = .continuous
        editor.layer.borderWidth = 1
        editor.textContainerInset = UIEdgeInsets(top: 9, left: 7, bottom: 9, right: 7)
        refreshBorders(editor)
    }

    /// CGColor borders do not follow appearance changes on their own; the controller calls this on trait changes.
    static func refreshBorders(_ editor: UITextView) {
        editor.layer.borderColor = Greyscale.hairline.uiColor.resolvedColor(with: editor.traitCollection).cgColor
    }
}

/// The non-interactive grain layer behind the whole keyboard (panel and the gaps between keys).
final class GrainView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = GrainTexture.patternColor
        updateOpacity()
    }
    required init?(coder: NSCoder) { nil }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateOpacity()
    }
    private func updateOpacity() {
        alpha = traitCollection.userInterfaceStyle == .dark ? GrainTexture.darkOpacity : GrainTexture.lightOpacity
    }
}
