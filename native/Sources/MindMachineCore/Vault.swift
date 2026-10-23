/* Domain records and explicit reminder transitions shared by all native surfaces.
 VaultFile persists this document; VaultModel and native controllers call its public operations. */
import Foundation

/// A deliberately authored checkbox; ordinary bullet text stays ordinary text.
public struct ChecklistItem: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var text: String
    public var complete: Bool

    public init(id: UUID = UUID(), text: String, complete: Bool = false) {
        self.id = id
        self.text = text
        self.complete = complete
    }
}

/// Original text remains available independently from replaceable search metadata.
public struct Capture: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let createdAt: Date
    public var text: String
    public var richText: Data?
    public var checklist: [ChecklistItem]

    public init(id: UUID = UUID(), text: String, richText: Data? = nil,
                checklist: [ChecklistItem] = [], createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.richText = richText
        self.checklist = checklist
        self.createdAt = createdAt
    }

    public var allItemsComplete: Bool {
        !checklist.isEmpty && checklist.allSatisfy(\.complete)
    }
}

/// A reminder stores an absolute instant plus its chosen display zone. Travel
/// therefore does not reinterpret the wall time against the current device zone.
public struct Reminder: Codable, Equatable, Identifiable, Sendable {
    public enum Status: String, Codable, Sendable { case scheduled, delivered, cancelled }
    public let id: UUID
    public let captureID: UUID
    public var dueAt: Date
    public var timeZoneID: String
    public var status: Status
    public var revision: Int

    public init(id: UUID = UUID(), captureID: UUID, dueAt: Date,
                timeZoneID: String, status: Status = .scheduled) {
        self.id = id
        self.captureID = captureID
        self.dueAt = dueAt
        self.timeZoneID = timeZoneID
        self.status = status
        self.revision = 1
    }
}

/// Conversation roles distinguish remembered user statements, assistant output
/// and app-authored reminder events; callers can inspect their capture sources.
public struct ChatMessage: Codable, Equatable, Identifiable, Sendable {
    public enum Role: String, Codable, Sendable { case user, assistant, reminder }
    public let id: UUID
    public let role: Role
    public let text: String
    public let createdAt: Date
    public let sourceCaptureIDs: [UUID]
    public let reminderID: UUID?

    public init(id: UUID = UUID(), role: Role, text: String,
                createdAt: Date = Date(), sourceCaptureIDs: [UUID] = [],
                reminderID: UUID? = nil) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
        self.sourceCaptureIDs = sourceCaptureIDs
        self.reminderID = reminderID
    }
}

/// A preferred wall-clock time; the UI applies it in the reminder's shown zone.
/// Optional storage on Vault keeps older documents compatible without migration.
public struct ReminderClockTime: Codable, Equatable, Sendable {
    public var hour: Int
    public var minute: Int
    public init(hour: Int = 9, minute: Int = 0) { self.hour = hour; self.minute = minute }
}

/// The local document contains retained material only. Temporary chat stays in
/// the presentation session and is never appended through this retention gate.
public struct Vault: Codable, Equatable, Sendable {
    public var captures: [Capture] = []
    public var reminders: [Reminder] = []
    public var messages: [ChatMessage] = []
    public var preferredReminderTime: ReminderClockTime?
    public var schemaVersion: Int = 1

    public init() {}

    /// Find returns complete originals with deterministic ordering. Empty search
    /// shows recency; words match independently so incomplete recall still works.
    /// Platform adapters may supply local semantic scores; ranking stays shared.
    public func findCaptures(_ query: String, openTasks: Bool = false, semanticScores: [UUID: Double] = [:]) -> [Capture] {
        let words = query.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        return captures.filter { !openTasks || (!$0.checklist.isEmpty && !$0.allItemsComplete) }
            .compactMap { capture -> (Capture, Double)? in
                let matches = words.filter(capture.text.lowercased().contains).count
                let lexical = words.isEmpty ? 0 : Double(matches) / Double(words.count)
                let semantic = semanticScores[capture.id] ?? 0
                guard words.isEmpty || lexical > 0 || semantic > 0.45 else { return nil }
                return (capture, lexical * 2 + semantic)
            }.sorted {
                if $0.1 != $1.1 { return $0.1 > $1.1 }
                if $0.0.createdAt != $1.0.createdAt { return $0.0.createdAt > $1.0.createdAt }
                return $0.0.id.uuidString < $1.0.id.uuidString
            }.map(\.0)
    }

    public mutating func retain(_ message: ChatMessage, temporary: Bool) {
        if !temporary { messages.append(message) }
    }

    /// Creating a reminder is a separate accepted action after capture. The UI
    /// must display the selected date, default time, zone and scheduling outcome.
    @discardableResult
    public mutating func schedule(captureID: UUID, dueAt: Date, timeZoneID: String) throws -> Reminder {
        guard let capture = captures.first(where: { $0.id == captureID }) else { throw VaultError.captureMissing }
        guard !capture.allItemsComplete else { throw VaultError.checklistComplete }
        guard TimeZone(identifier: timeZoneID) != nil else { throw VaultError.invalidTimeZone }
        // Each capture has one current commitment. A second accepted date edits
        // it; cancelled history is retained and a later acceptance creates a new one.
        if let existing = reminders.firstIndex(where: { $0.captureID == captureID && $0.status != .cancelled }) {
            let id = reminders[existing].id
            try reschedule(id: id, dueAt: dueAt, timeZoneID: timeZoneID)
            return reminders[existing]
        }
        let reminder = Reminder(captureID: captureID, dueAt: dueAt, timeZoneID: timeZoneID)
        reminders.append(reminder)
        return reminder
    }

    /// Rescheduling is an edit; it requires an exact target, keeps the original
    /// chosen zone unless explicitly replaced, and does not create a Snooze mode.
    public mutating func reschedule(id: UUID, dueAt: Date, timeZoneID: String? = nil) throws {
        guard let i = reminders.firstIndex(where: { $0.id == id }) else { throw VaultError.reminderMissing }
        guard captures.first(where: { $0.id == reminders[i].captureID })?.allItemsComplete != true else {
            throw VaultError.checklistComplete
        }
        if let timeZoneID {
            guard TimeZone(identifier: timeZoneID) != nil else { throw VaultError.invalidTimeZone }
            reminders[i].timeZoneID = timeZoneID
        }
        reminders[i].dueAt = dueAt
        reminders[i].status = .scheduled
        reminders[i].revision += 1
    }

    /// Removing an alert leaves its capture intact. Cancelled state gives the
    /// platform scheduler an explicit cancellation to reconcile.
    public mutating func removeReminder(id: UUID) throws {
        guard let i = reminders.firstIndex(where: { $0.id == id }) else { throw VaultError.reminderMissing }
        reminders[i].status = .cancelled
        reminders[i].revision += 1
    }

    /// Completing the whole list cancels pending alerts. Reopening changes only
    /// the checkbox: the UI offers a new reminder instead of restoring an old one.
    public mutating func setItem(captureID: UUID, itemID: UUID, complete: Bool) throws {
        guard let c = captures.firstIndex(where: { $0.id == captureID }),
              let item = captures[c].checklist.firstIndex(where: { $0.id == itemID })
        else { throw VaultError.captureMissing }
        captures[c].checklist[item].complete = complete
        if captures[c].allItemsComplete {
            for r in reminders.indices where reminders[r].captureID == captureID && reminders[r].status == .scheduled {
                reminders[r].status = .cancelled
                reminders[r].revision += 1
            }
        }
    }

    /// A single due event enters ordinary Chat. No repeating schedule is created
    /// here; an explicit reschedule increases the revision for a later occurrence.
    public mutating func recordDueEvents(now: Date) {
        for i in reminders.indices where reminders[i].status == .scheduled && reminders[i].dueAt <= now {
            reminders[i].status = .delivered
            let reminder = reminders[i]
            let title = captures.first(where: { $0.id == reminder.captureID })?.text ?? "Reminder"
            messages.append(ChatMessage(role: .reminder, text: title, createdAt: now,
                                        sourceCaptureIDs: [reminder.captureID], reminderID: reminder.id))
        }
    }

    /// Overdue status follows unfinished work and time, not whether the person
    /// read a notification. Completed lists are excluded from Open tasks.
    public func isOverdue(captureID: UUID, now: Date) -> Bool {
        guard let capture = captures.first(where: { $0.id == captureID }), !capture.allItemsComplete else { return false }
        return reminders.contains { $0.captureID == captureID && $0.status != .cancelled && $0.dueAt < now }
    }
}

public enum VaultError: Error { case captureMissing, reminderMissing, invalidTimeZone, checklistComplete }

// Native surfaces show domain failures without leaking implementation details.
extension VaultError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .captureMissing: return "The original capture is no longer available."
        case .reminderMissing: return "The reminder is no longer available."
        case .invalidTimeZone: return "Choose a valid reminder time zone."
        case .checklistComplete: return "Reopen the checklist before setting a new reminder."
        }
    }
}
