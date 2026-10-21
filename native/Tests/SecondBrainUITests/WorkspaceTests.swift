/* Behavior checks for the public native workspace presentation interface.
 SwiftPM runs these; native entry adapters call the same activation operation. */
import XCTest
import SecondBrainUI
import SecondBrainCore
#if canImport(AppKit)
import AppKit
#endif

final class WorkspaceTests: XCTestCase {
    // Default clock time is a saved preference, interpreted in the displayed
    // reminder zone; a time already passed rolls to the next local day.
    @MainActor
    func testReminderDefaultTimePersistsAndUsesChosenZone() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("vault.json")
        let model = VaultModel(url: url, notificationAccess: .disabled)
        model.setDefaultReminderTime(hour: 14, minute: 30)
        let reopened = VaultModel(url: url, notificationAccess: .disabled)
        let zone = try XCTUnwrap(TimeZone(identifier: "Asia/Kolkata"))
        let morning = Date(timeIntervalSince1970: 7_258_118_400)
        XCTAssertEqual(reopened.suggestedReminderDate(now: morning, zone: zone), morning.addingTimeInterval(9 * 3600))
        XCTAssertEqual(reopened.suggestedReminderDate(now: morning.addingTimeInterval(10 * 3600), zone: zone), morning.addingTimeInterval(33 * 3600))
    }

    // Soft offers belong to the just-saved capture. Finished lists and ordinary
    // notes must not inherit an old action's reminder prompt.
    @MainActor
    func testReminderOfferFollowsOnlyEligibleLatestCapture() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = VaultModel(url: directory.appendingPathComponent("vault.json"), notificationAccess: .disabled)
        model.draft = "Buy a gift"
        model.saveCapture()
        XCTAssertEqual(model.offeredCapture, model.vault.captures.first?.id)
        model.draft = "A thought about the clouds"
        model.saveCapture()
        XCTAssertNil(model.offeredCapture)
        model.draft = "☑ Packed keys"
        model.saveCapture()
        XCTAssertNil(model.offeredCapture)
        XCTAssertEqual(model.vault.captures.count, 3)
        XCTAssertTrue(model.vault.reminders.isEmpty)
    }

    // Completing an offered list elsewhere or here clears the stale prompt;
    // reopening offers a new commitment without automatically scheduling it.
    @MainActor
    func testCompletionRefreshClearsOfferAndReopeningOffersAgain() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("vault.json")
        let model = VaultModel(url: url, notificationAccess: .disabled)
        model.draft = "☐ Pack torch"
        model.saveCapture()
        let capture = try XCTUnwrap(model.vault.captures.first)
        let item = try XCTUnwrap(capture.checklist.first)
        _ = try VaultFile(url: url).update { try $0.setItem(captureID: capture.id, itemID: item.id, complete: true) }
        model.reload()
        XCTAssertNil(model.offeredCapture)
        model.setItem(captureID: capture.id, itemID: item.id, complete: false)
        XCTAssertEqual(model.offeredCapture, capture.id)
        XCTAssertTrue(model.vault.reminders.isEmpty)
        model.setItem(captureID: capture.id, itemID: item.id, complete: true)
        XCTAssertNil(model.offeredCapture)
    }

    #if canImport(AppKit)
    // A selected group of paragraphs becomes a complete authored checklist, then
    // survives the same save/reopen interface as ordinary capture.
    @MainActor
    func testSelectedParagraphsBecomeACompleteChecklist() async throws {
        _ = NSApplication.shared
        let editor = NSTextView()
        editor.string = "One\nTwo\nThree"
        editor.setSelectedRange(NSRange(location: 0, length: 13))
        RichTextEditing.apply(.checkbox, to: editor)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("vault.json")
        let model = VaultModel(url: url, notificationAccess: .disabled)
        model.draft = editor.string
        model.richDraft = try RichTextEditing.encoded(editor.attributedString())
        model.saveCapture()
        let reopened = VaultModel(url: url, notificationAccess: .disabled)
        XCTAssertEqual(reopened.vault.captures.first?.text, "☐ One\n☐ Two\n☐ Three")
        XCTAssertEqual(reopened.vault.captures.first?.checklist.map(\.text), ["One", "Two", "Three"])
    }
    #endif

    // Checkbox controls create authored tasks while retaining the original note.
    @MainActor
    func testVisualCheckboxesBecomeItemsWithoutScheduling() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = VaultModel(url: directory.appendingPathComponent("vault.json"), notificationAccess: .disabled)
        model.draft = "Packing\n☐ Torch\n☑ Keys"
        model.saveCapture()
        XCTAssertEqual(model.vault.captures.first?.text, "Packing\n☐ Torch\n☑ Keys")
        XCTAssertEqual(model.vault.captures.first?.checklist.map(\.text), ["Torch", "Keys"])
        XCTAssertEqual(model.vault.captures.first?.checklist.map(\.complete), [false, true])
        XCTAssertTrue(model.vault.reminders.isEmpty)
    }

    // Rich formatting accompanies the original through actual save and reopen.
    @MainActor
    func testRichCapturePreservesTextAndFormatting() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("vault.json")
        let model = VaultModel(url: url, notificationAccess: .disabled)
        let rich = Data(#"{\rtf1\ansi A \b shelf\b0.}"#.utf8)
        model.draft = "A shelf."
        model.richDraft = rich
        model.saveCapture()
        let reopened = VaultModel(url: url, notificationAccess: .disabled)
        XCTAssertEqual(reopened.vault.captures.first?.text, "A shelf.")
        XCTAssertEqual(reopened.vault.captures.first?.richText, rich)
        XCTAssertEqual(model.draft, "")
        XCTAssertNil(model.richDraft)
    }

    // Reactivation must open Capture without destroying another mode's writing.
    @MainActor
    func testActivationReturnsToCaptureAndKeepsDrafts() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = VaultModel(url: directory.appendingPathComponent("vault.json"), notificationAccess: .disabled)
        model.draft = "A thought in progress"
        model.query = "old shelf"
        model.chatDraft = "Where did I leave it?"
        model.mode = 2
        model.selectedCapture = UUID()
        model.activateCapture()
        XCTAssertEqual(model.mode, 0)
        XCTAssertNil(model.selectedCapture)
        XCTAssertEqual(model.draft, "A thought in progress")
        XCTAssertEqual(model.query, "old shelf")
        XCTAssertEqual(model.chatDraft, "Where did I leave it?")
    }
}
