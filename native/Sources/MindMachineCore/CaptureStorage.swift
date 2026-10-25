/* Background Capture persistence used by VaultModel's Mac submission/refresh.
 The actor keeps blocking filesystem/SQLite work on its own executor. Tests may
 delay or fail the storage boundary without replacing the handoff logic. */
import Foundation

public actor CaptureStorage {
    private let append: @Sendable (Capture) throws -> Void
    private let load: @Sendable (Int?) throws -> Vault
    private let reconcileDueEvents: @Sendable (Int?, Date) throws -> Vault

    public init(file: VaultFile) {
        append = { try file.append($0) }
        load = { try file.read(captureLimit: $0) }
        reconcileDueEvents = { limit, now in
            let latest = try file.read(captureLimit: limit)
            guard latest.reminders.contains(where: { $0.status == .scheduled && $0.dueAt <= now }) else { return latest }
            return try file.update(captureLimit: limit) { $0.recordDueEvents(now: now) }
        }
    }

    public init(append: @escaping @Sendable (Capture) throws -> Void,
                load: @escaping @Sendable (Int?) throws -> Vault) {
        self.append = append
        self.load = load
        reconcileDueEvents = { limit, _ in try load(limit) }
    }

    public func save(_ capture: Capture) throws { try append(capture) }
    public func read(captureLimit: Int? = nil) throws -> Vault { try load(captureLimit) }

    // Presentation refresh retains the existing due-Chat reconciliation, with
    // its durable write on this executor rather than the editor's actor.
    public func refresh(captureLimit: Int? = nil, now: Date = Date()) throws -> Vault {
        try reconcileDueEvents(captureLimit, now)
    }
}
