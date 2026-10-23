/* Device notification adapter called by VaultModel after saved reminder changes.
 It reads a bounded reminder-source snapshot of the shared vault, reconciles revision-specific system requests,
 and reports scheduling separately from the durable commitment and Chat event. */
import Foundation
import UserNotifications
import MindMachineCore

@MainActor
final class DeviceReminders {
    private let file: VaultFile
    private let allowsPermissionPrompt: Bool
    private let prefix = "secondbrain.reminder." // identifier prefix kept so pending requests from earlier builds are still recognised

    init(file: VaultFile, allowsPermissionPrompt: Bool) {
        self.file = file
        self.allowsPermissionPrompt = allowsPermissionPrompt
    }

    // Permission is requested only through the companion/Mac's deliberate control.
    // Keyboard saves never try to present an authorization dialog over a host app.
    func enable() async throws -> String {
        guard allowsPermissionPrompt else { return "Open Mind Machine to enable device notifications." }
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
        }
        return try await reconcile()
    }

    // Revision IDs prevent an older asynchronous add from overwriting an edited
    // schedule. Fresh reads before/after each add also remove cancelled work.
    func reconcile() async throws -> String {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let pending = await center.pendingNotificationRequests()
        let current = try snapshot()
        let desired = current.reminders.filter { isPending($0, in: current) }
        // Due Chat reconciliation must not cancel a notification that the OS is
        // just about to display. Keep its accepted revision until system delivery.
        let acceptedIDs = Set(current.reminders.filter { stillAccepted($0, in: current) }.map(identifier))
        let legacyIDs = Set(current.reminders.map { $0.id.uuidString })
        let stale = pending.filter {
            ($0.identifier.hasPrefix(prefix) || legacyIDs.contains($0.identifier)) && !acceptedIDs.contains($0.identifier)
        }.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: stale)
        var authorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        #if os(iOS)
        authorized = authorized || settings.authorizationStatus == .ephemeral
        #endif
        guard authorized else {
            return settings.authorizationStatus == .denied
                ? "Device notifications are disabled. Saved reminders still appear in Chat when the vault opens."
                : "Enable device notifications in the companion or Mac settings. Saved reminders remain in the vault."
        }
        let existing = Set(pending.map(\.identifier))
        for reminder in desired where !existing.contains(identifier(reminder)) {
            let latest = try snapshot()
            guard stillAccepted(reminder, in: latest), reminder.dueAt > Date() else { continue }
            let content = UNMutableNotificationContent()
            content.title = "A reminder from your vault"
            content.body = "Open Mind Machine for the details."
            content.sound = .default
            content.userInfo = ["reminderID": reminder.id.uuidString, "captureID": reminder.captureID.uuidString]
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, reminder.dueAt.timeIntervalSinceNow), repeats: false)
            let id = identifier(reminder)
            try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            // An edit or completion may have happened while the OS accepted it.
            // Remove only this old revision, never the newer request's identifier.
            if !stillAccepted(reminder, in: try snapshot()) {
                center.removePendingNotificationRequests(withIdentifiers: [id])
            }
        }
        let registered = Set(await center.pendingNotificationRequests().map(\.identifier))
        let latest = try snapshot()
        let expected = latest.reminders.filter { isPending($0, in: latest) }.map(identifier)
        let missing = expected.filter { !registered.contains($0) }.count
        if missing > 0 { return "\(missing) saved reminder(s) have no pending device notification. Reopen the vault to retry." }
        return "\(expected.count) pending device notification(s). Delivery still depends on system notification settings."
    }

    // Keyboard notification reconciliation reads only sources referenced by
    // reminders, keeping a large Capture/Find corpus out of this deferred path.
    private func snapshot() throws -> Vault {
        var vault = try file.read(captureLimit: 1)
        vault.captures = try Set(vault.reminders.map(\.captureID)).compactMap { try file.capture(id: $0) }
        return vault
    }

    private func identifier(_ reminder: Reminder) -> String { "\(prefix)\(reminder.id.uuidString).r\(reminder.revision)" }
    private func isPending(_ reminder: Reminder, in vault: Vault) -> Bool {
        reminder.status == .scheduled && reminder.dueAt > Date() &&
        vault.captures.contains { $0.id == reminder.captureID && !$0.allItemsComplete }
    }
    private func stillAccepted(_ reminder: Reminder, in vault: Vault) -> Bool {
        vault.reminders.contains {
            $0.id == reminder.id && $0.revision == reminder.revision && $0.status != .cancelled &&
            vault.captures.contains { $0.id == reminder.captureID && !$0.allItemsComplete }
        }
    }
}

// The center holds its delegate weakly, so app entry points install a retained
// process-lifetime presenter. Keyboard extensions only reconcile saved requests.
@MainActor
@available(iOSApplicationExtension, unavailable)
public func installReminderNotificationPresentation() {
    UNUserNotificationCenter.current().delegate = ReminderNotificationPresentation.shared
}

@MainActor
private final class ReminderNotificationPresentation: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ReminderNotificationPresentation()
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                           willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
