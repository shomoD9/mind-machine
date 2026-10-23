/* Immutable source revisions exchanged by the replication adapter. VaultFile
 queues these with local commits and retains branches to preserve concurrent text. */
import Foundation

public struct NoteRevision: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let noteID: UUID
    public let capture: Capture?
    public let parents: [UUID]
    public init(id: UUID = UUID(), noteID: UUID, capture: Capture?, parents: [UUID]) {
        self.id = id; self.noteID = noteID; self.capture = capture; self.parents = parents
    }
    public init(capture: Capture, parents: [UUID]) {
        self.init(noteID: capture.id, capture: capture, parents: parents)
    }
}
