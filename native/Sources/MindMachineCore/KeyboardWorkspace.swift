/* Private keyboard-session state consumed by the native keyboard controller.
 Native editors supply text, rich representation, selection and scroll position;
 host text stays in its owning app and is never copied into these private drafts. */
import Foundation

public struct PrivateDraft: Equatable, Sendable {
    public var text: String
    public var selection: NSRange
    public var richText: Data?
    public var scrollOffset: Double

    public init(text: String = "", selection: NSRange = NSRange(location: 0, length: 0),
                richText: Data? = nil, scrollOffset: Double = 0) {
        self.text = text
        self.selection = selection
        self.richText = richText
        self.scrollOffset = scrollOffset
    }
}

public struct KeyboardWorkspace: Sendable {
    public enum Mode: Int, Hashable, Sendable { case capture, recall, chat }
    public enum Destination: Sendable { case privatePad, app }
    public enum PadSize: Int, CaseIterable, Sendable { case minimised, standard, expanded }
    public private(set) var mode: Mode = .capture
    public private(set) var destination: Destination = .privatePad
    public private(set) var size: PadSize = .standard
    private var drafts: [Mode: PrivateDraft] = [:]

    public init() {}
    public var draft: PrivateDraft { drafts[mode] ?? PrivateDraft() }

    /// A send result targets its original mode and text. It cannot discard newer
    /// typing or switch the field the person is currently editing.
    public mutating func acknowledgeSentDraft(_ sentText: String, in mode: Mode) {
        guard drafts[mode]?.text == sentText else { return }
        drafts[mode] = PrivateDraft()
    }

    // Size and destination are independent of the private editor's contents.
    public mutating func edit(_ draft: PrivateDraft) { drafts[mode] = draft }
    public mutating func selectMode(_ mode: Mode) { self.mode = mode }
    public mutating func resize(_ size: PadSize) { self.size = size }
    public mutating func selectDestination(_ destination: Destination) { self.destination = destination }
}
