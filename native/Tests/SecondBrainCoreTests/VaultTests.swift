/* Behavioral checks at the saved-vault boundary. SwiftPM runs these without
 Apple signing; native shells use the same Vault and VaultFile interfaces. */
import XCTest
import SecondBrainCore

final class VaultTests: XCTestCase {
    // A second entry point must refind the exact original after reopening storage.
    func testSavedCaptureCanBeRefoundAfterReopening() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("vault.json")
        let original = Capture(text: "A shelf for mum’s birthday. Keep the odd wording!\nSecond line.")
        try VaultFile(url: url).update { $0.captures.append(original) }
        let reopened = try VaultFile(url: url).read()
        XCTAssertEqual(reopened.findCaptures("MUM’S shelf").map(\.id), [original.id])
        XCTAssertEqual(reopened.findCaptures("MUM’S shelf").first?.text, original.text)
        XCTAssertTrue(reopened.findCaptures("unrelated trampoline").isEmpty)
        XCTAssertTrue(reopened.reminders.isEmpty)
    }

    private func fixture() -> (Vault, UUID, UUID, UUID) {
        let a = ChecklistItem(text: "Buy wood")
        let b = ChecklistItem(text: "Fit shelf")
        let capture = Capture(text: "Weekend shelf", checklist: [a, b])
        var vault = Vault()
        vault.captures.append(capture)
        return (vault, capture.id, a.id, b.id)
    }

    // Capturing alone carries no scheduling authority; the explicit operation does.
    func testCaptureDoesNotCreateReminder() throws {
        var (vault, capture, _, _) = fixture()
        XCTAssertTrue(vault.reminders.isEmpty)
        _ = try vault.schedule(captureID: capture, dueAt: Date(), timeZoneID: "Asia/Kolkata")
        XCTAssertEqual(vault.reminders.count, 1)
    }

    // One unfinished item keeps the reminder active; full completion cancels it.
    func testWholeListCompletionAndReopening() throws {
        var (vault, capture, a, b) = fixture()
        let reminder = try vault.schedule(captureID: capture, dueAt: Date().addingTimeInterval(300), timeZoneID: "Asia/Kolkata")
        try vault.setItem(captureID: capture, itemID: a, complete: true)
        XCTAssertEqual(vault.reminders[0].status, .scheduled)
        try vault.setItem(captureID: capture, itemID: b, complete: true)
        XCTAssertEqual(vault.reminders[0].status, .cancelled)
        try vault.setItem(captureID: capture, itemID: a, complete: false)
        XCTAssertEqual(vault.reminders[0].id, reminder.id)
        XCTAssertEqual(vault.reminders[0].status, .cancelled)
    }

    // Foreground due-event reconciliation is idempotent and creates no repeat.
    func testDueEventOnceAndOverdueWithoutRepeat() throws {
        var (vault, capture, _, _) = fixture()
        let now = Date()
        _ = try vault.schedule(captureID: capture, dueAt: now.addingTimeInterval(-10), timeZoneID: "Europe/London")
        vault.recordDueEvents(now: now)
        vault.recordDueEvents(now: now.addingTimeInterval(100))
        XCTAssertEqual(vault.messages.count, 1)
        XCTAssertEqual(vault.messages[0].role, .reminder)
        XCTAssertTrue(vault.isOverdue(captureID: capture, now: now))
    }

    // Rescheduling keeps the original zone unless the user explicitly changes it.
    func testRescheduleKeepsZoneAndAllowsNewOccurrence() throws {
        var (vault, capture, _, _) = fixture()
        let now = Date()
        let reminder = try vault.schedule(captureID: capture, dueAt: now, timeZoneID: "Asia/Kolkata")
        vault.recordDueEvents(now: now)
        try vault.reschedule(id: reminder.id, dueAt: now.addingTimeInterval(60))
        XCTAssertEqual(vault.reminders[0].timeZoneID, "Asia/Kolkata")
        XCTAssertEqual(vault.reminders[0].revision, 2)
        vault.recordDueEvents(now: now.addingTimeInterval(61))
        XCTAssertEqual(vault.messages.count, 2)
    }

    // Removing a reminder preserves the original authored capture.
    func testRemoveKeepsCapture() throws {
        var (vault, capture, _, _) = fixture()
        let reminder = try vault.schedule(captureID: capture, dueAt: Date(), timeZoneID: "UTC")
        try vault.removeReminder(id: reminder.id)
        XCTAssertEqual(vault.captures.count, 1)
        XCTAssertEqual(vault.reminders[0].status, .cancelled)
    }

    // Temporary messages cannot enter the retained document through its API.
    func testTemporaryRetentionBoundary() {
        var vault = Vault()
        vault.retain(ChatMessage(role: .user, text: "private temporary question"), temporary: true)
        XCTAssertTrue(vault.messages.isEmpty)
        vault.retain(ChatMessage(role: .user, text: "remember this"), temporary: false)
        XCTAssertEqual(vault.messages.count, 1)
    }

    // Independent process-like writers reread the latest file before each append.
    func testPersistenceDoesNotOverwriteAnotherWriter() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("vault.json")
        let companion = VaultFile(url: url)
        let keyboard = VaultFile(url: url)
        _ = try companion.update { $0.captures.append(Capture(text: "First")) }
        _ = try keyboard.update { $0.captures.append(Capture(text: "Second")) }
        XCTAssertEqual(try companion.read().captures.map(\.text), ["First", "Second"])
    }

    // A decode failure must remain visible instead of being treated as a new vault.
    func testCorruptionDoesNotBecomeEmptyVault() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("vault.json")
        try Data("broken".utf8).write(to: url)
        XCTAssertThrowsError(try VaultFile(url: url).read())
    }
}
