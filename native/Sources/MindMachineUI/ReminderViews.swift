/* Checklist/reminder controls used by WorkspaceView on Mac and the companion.
 The keyboard renders the same VaultModel operations with UIKit controls. These
 views never change the original capture text when completion or dates change.
 Colours and button styles come from Greyscale.swift. ReminderOfferView sits above the Capture page
 in WorkspaceView after an actionable save. */
import SwiftUI
import MindMachineCore

// Both native renderers show the stored zone, rather than the device's travel zone.
public func reminderDateLabel(_ reminder: Reminder) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium; formatter.timeStyle = .short
    formatter.timeZone = TimeZone(identifier: reminder.timeZoneID)
    return "\(formatter.string(from: reminder.dueAt)) · \(reminder.timeZoneID)"
}

public struct ReminderEditor: View {
    @ObservedObject private var model: VaultModel
    private let captureID: UUID
    private let reminderID: UUID?
    private let zone: TimeZone
    private let close: () -> Void
    @State private var date: Date
    @State private var saving = false

    public init(model: VaultModel, captureID: UUID, reminder: Reminder? = nil, close: @escaping () -> Void) {
        self.model = model; self.captureID = captureID; self.reminderID = reminder?.id; self.close = close
        let zone = reminder.flatMap { TimeZone(identifier: $0.timeZoneID) } ?? .current
        self.zone = zone
        _date = State(initialValue: reminder?.dueAt ?? model.suggestedReminderDate(zone: zone))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(reminderID == nil ? "Choose a reminder" : "Edit reminder").font(.headline).accessibilityIdentifier("reminder-editor-title")
            Text("One date for the whole capture or checklist").font(.caption).foregroundStyle(Greyscale.inkSecondary.color)
            DatePicker("Date and time", selection: $date, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                .environment(\.timeZone, zone).accessibilityIdentifier("reminder-date-picker")
            Text("Time zone: \(zone.identifier)").font(.caption).foregroundStyle(Greyscale.inkSecondary.color)
                .accessibilityIdentifier("reminder-time-zone")
            HStack {
                Button("Cancel", action: close).disabled(saving)
                    .buttonStyle(GreyscaleButtonStyle()).accessibilityIdentifier("cancel-reminder")
                Spacer()
                Button(saving ? "Saving…" : reminderID == nil ? "Set reminder" : "Save changes") {
                    saving = true
                    Task { @MainActor in
                        let saved: Bool
                        if let reminderID { saved = await model.editReminder(id: reminderID, date: date) }
                        else { saved = await model.schedule(captureID: captureID, date: date, zone: zone.identifier) }
                        saving = false
                        if saved { close() }
                    }
                }.buttonStyle(GreyscaleButtonStyle(.prominent))
                    .disabled(saving || date <= Date()).accessibilityIdentifier("confirm-reminder")
            }
        }.foregroundStyle(Greyscale.ink.color).greyscaleCard(padding: 12)
    }
}

public struct ReminderOfferView: View {
    @ObservedObject private var model: VaultModel
    @State private var choosing = false
    public init(model: VaultModel) { self.model = model }
    public var body: some View {
        if let id = model.offeredCapture {
            VStack(alignment: .leading, spacing: 6) {
                if choosing {
                    ReminderEditor(model: model, captureID: id) { choosing = false; model.offeredCapture = nil }
                        .id(id)
                } else {
                    // A one-line offer above the page: its two answers are quiet text links, so Save stays
                    // the only prominent control in Capture.
                    HStack(spacing: 12) {
                        Text("Saved. Add a reminder?").foregroundStyle(Greyscale.inkSecondary.color)
                            .accessibilityIdentifier("reminder-offer")
                        Button("Choose date") { choosing = true }.buttonStyle(.plain).fontWeight(.semibold)
                            .accessibilityIdentifier("reminder-offer-choose")
                        Button("Not now") { model.offeredCapture = nil }.buttonStyle(.plain)
                            .foregroundStyle(Greyscale.inkSecondary.color).accessibilityIdentifier("reminder-offer-dismiss")
                    }.font(.caption)
                }
            }.onChange(of: model.offeredCapture) { _, _ in choosing = false }
        }
    }
}

public struct CaptureTasksView: View {
    @ObservedObject private var model: VaultModel
    private let captureID: UUID
    @State private var editing = false
    public init(model: VaultModel, captureID: UUID) { self.model = model; self.captureID = captureID }
    public var body: some View {
        if let capture = model.vault.captures.first(where: { $0.id == captureID }) {
            VStack(alignment: .leading, spacing: 8) {
                // Items are live state linked to immutable original wording.
                ForEach(capture.checklist) { item in
                    Button {
                        model.setItem(captureID: capture.id, itemID: item.id, complete: !item.complete)
                    } label: {
                        HStack(alignment: .top) {
                            Image(systemName: item.complete ? "checkmark.square" : "square")
                            Text(item.text).strikethrough(item.complete)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }.buttonStyle(.plain).accessibilityIdentifier("checklist-item")
                }
                if model.vault.isOverdue(captureID: capture.id, now: Date()) {
                    Text("Overdue").font(.caption.bold()).accessibilityIdentifier("reminder-overdue")
                }
                let reminder = model.vault.reminders.first { $0.captureID == capture.id && $0.status != .cancelled }
                if editing {
                    ReminderEditor(model: model, captureID: capture.id, reminder: reminder) { editing = false }
                } else if let reminder {
                    Text(reminderDateLabel(reminder)).font(.caption).accessibilityIdentifier("reminder-date")
                    HStack {
                        Button("Edit reminder") { editing = true }.disabled(capture.allItemsComplete)
                            .buttonStyle(GreyscaleButtonStyle()).accessibilityIdentifier("edit-reminder")
                        Button("Remove reminder") { model.removeReminder(id: reminder.id) }
                            .buttonStyle(GreyscaleButtonStyle()).accessibilityIdentifier("remove-reminder")
                    }
                } else if !capture.allItemsComplete {
                    if model.offeredCapture == capture.id { Text("Set a new reminder?").font(.caption).accessibilityIdentifier("reminder-renew") }
                    Button("Set reminder") { editing = true }
                        .buttonStyle(GreyscaleButtonStyle()).accessibilityIdentifier("set-reminder")
                } else { Text("Complete · no pending reminder").font(.caption).accessibilityIdentifier("reminder-complete") }
                Text(model.deviceNotificationStatus).font(.caption2).foregroundStyle(Greyscale.inkSecondary.color)
                    .accessibilityIdentifier("reminder-notification-status")
            }
        }
    }
}
