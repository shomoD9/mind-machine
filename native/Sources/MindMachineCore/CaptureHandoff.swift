/* Portable Capture save acknowledgement state, called by VaultModel on Mac.
 Source stays in the live draft; a submission retains its immutable original. */
import Foundation

public struct CaptureHandoff {
    public struct Submission: Sendable {
        public let capture: Capture
        fileprivate let revision: UInt64
    }
    private var revision: UInt64 = 0
    private var pending: UUID?
    public init() {}
    public mutating func edited() { revision += 1 }
    public mutating func begin(source: String, richText: Data?) -> Submission? {
        guard pending == nil, !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let capture = Self.capture(source: source, richText: richText)
        pending = capture.id
        return Submission(capture: capture, revision: revision)
    }
    public mutating func finish(_ submission: Submission, succeeded: Bool) -> Bool {
        guard pending == submission.capture.id else { return false }
        pending = nil
        return succeeded && submission.revision == revision
    }

    /// Keep the existing visual and Markdown checkbox rules at the portable
    /// capture boundary. Text is never reconstructed from checklist metadata.
    public static func capture(source: String, richText: Data?) -> Capture {
        let items = source.components(separatedBy: .newlines).compactMap { line -> ChecklistItem? in
            if line.hasPrefix("☐ ") { return ChecklistItem(text: String(line.dropFirst(2))) }
            if line.hasPrefix("☑ ") { return ChecklistItem(text: String(line.dropFirst(2)), complete: true) }
            if line.hasPrefix("- [ ] ") { return ChecklistItem(text: String(line.dropFirst(6))) }
            if line.hasPrefix("- [x] ") { return ChecklistItem(text: String(line.dropFirst(6)), complete: true) }
            return nil
        }
        return Capture(text: source, richText: richText, checklist: items)
    }
}
