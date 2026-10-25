/* Mac capture handoff at the real editor/model/storage boundaries. SwiftPM on
 macOS runs these alongside native command, undo, source and timing checks. */
#if os(macOS)
import XCTest
import AppKit
import SwiftUI
import MindMachineCore
import MindMachineUI

final class MacCaptureHandoffTests: XCTestCase {
    @MainActor
    func testSlowRefreshDoesNotWaitBeforeAcceptingInput() async throws {
        _ = NSApplication.shared
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let started = expectation(description: "read entered")
        let release = DispatchSemaphore(value: 0)
        defer { release.signal() }
        let storage = CaptureStorage(append: { _ in }, load: { _ in
            started.fulfill()
            guard release.wait(timeout: .now() + 5) == .success else { throw URLError(.timedOut) }
            return Vault()
        })
        let model = VaultModel(url: folder.appendingPathComponent("vault.json"), notificationAccess: .disabled,
                               captureStorage: storage)
        model.activateCapture()
        await fulfillment(of: [started], timeout: 2)
        let (_, editor) = MacMarkdownEditor.makeScrollableEditor()
        let coordinator = MacMarkdownEditor()
        coordinator.attach(to: editor)
        coordinator.changed = { model.draft = editor.string }
        editor.insertText("**final** 👩🏽‍💻", replacementRange: NSRange(location: 0, length: 0))
        XCTAssertEqual(model.draft, "**final** 👩🏽‍💻")
        release.signal()
    }

    @MainActor
    func testHostedBindingPublishesFinalKeyBeforeWindowHideAndRecreation() async throws {
        _ = NSApplication.shared
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let model = VaultModel(url: folder.appendingPathComponent("vault.json"), notificationAccess: .disabled)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 540, height: 420),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.orderOut(nil) }
        @MainActor func findEditor(_ view: NSView) -> NSTextView? {
            if let editor = view as? NSTextView, !editor.isFieldEditor { return editor }
            return view.subviews.lazy.compactMap(findEditor).first
        }
        @MainActor func mount() async throws -> NSTextView {
            let host = NSHostingView(rootView: RichNoteEditor(
                text: Binding(get: { model.draft }, set: { model.draft = $0 }),
                richText: Binding(get: { model.richDraft }, set: { model.richDraft = $0 })))
            window.contentView = host
            window.makeKeyAndOrderFront(nil)
            for _ in 0..<100 {
                host.layoutSubtreeIfNeeded()
                if let editor = findEditor(host) {
                    window.makeFirstResponder(editor)
                    return editor
                }
                try await Task.sleep(for: .milliseconds(10))
            }
            return try XCTUnwrap(findEditor(host))
        }
        var expected = ""
        var editor = try await mount()
        // Native input and immediate orderOut share one actor turn. Mounting a
        // new representable also proves the handoff outlives its coordinator.
        for suffix in ["# **thought**", " e\u{301}", " 👩🏽‍💻 final"] {
            editor.setSelectedRange(NSRange(location: (editor.string as NSString).length, length: 0))
            for character in suffix { editor.insertText(String(character), replacementRange: editor.selectedRange()) }
            expected += suffix
            window.orderOut(nil)
            XCTAssertEqual(Data(model.draft.utf8), Data(expected.utf8))
            editor = try await mount()
            XCTAssertEqual(Data(editor.string.utf8), Data(expected.utf8))
            XCTAssertNotNil(editor.textLayoutManager)
        }
    }

    @MainActor
    func testSlowSaveKeepsInputAndFinalCharactersAcrossEditorRecreation() async throws {
        _ = NSApplication.shared
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = VaultFile(url: folder.appendingPathComponent("vault.json"))
        let started = expectation(description: "storage entered")
        let release = DispatchSemaphore(value: 0)
        defer { release.signal() }
        let storage = CaptureStorage(append: { capture in
            started.fulfill()
            guard release.wait(timeout: .now() + 5) == .success else { throw URLError(.timedOut) }
            try file.append(capture)
        }, load: { try file.read(captureLimit: $0) })
        let model = VaultModel(url: file.url, notificationAccess: .disabled, captureStorage: storage)
        let (_, editor) = MacMarkdownEditor.makeScrollableEditor()
        let coordinator = MacMarkdownEditor()
        coordinator.attach(to: editor)
        coordinator.changed = { model.draft = editor.string }
        editor.insertText("# **thought**", replacementRange: NSRange(location: 0, length: 0))
        let save = try XCTUnwrap(model.submitCapture())
        await fulfillment(of: [started], timeout: 2)
        XCTAssertNil(model.notice, "Pending storage cannot report Saved")
        XCTAssertNil(model.submitCapture(), "Repeated Save must not duplicate a pending source")
        var keySamples: [Double] = []
        // No run-loop/debounce gap separates the last character from hiding.
        for character in " e\u{301} 👩🏽‍💻 final" {
            let start = ProcessInfo.processInfo.systemUptime
            editor.insertText(String(character), replacementRange: editor.selectedRange())
            keySamples.append((ProcessInfo.processInfo.systemUptime - start) * 1_000)
        }
        let sorted = keySamples.sorted()
        print("MM_HANDOFF_BENCH storage=held keys=\(sorted.count) p50Ms=\(sorted[(sorted.count - 1) / 2]) p95Ms=\(sorted[Int(ceil(Double(sorted.count) * 0.95)) - 1]) maxMs=\(sorted.last!)")
        let expected = "# **thought** e\u{301} 👩🏽‍💻 final"
        XCTAssertEqual(Data(model.draft.utf8), Data(expected.utf8))
        let (_, reopened) = MacMarkdownEditor.makeScrollableEditor()
        let reopenedCoordinator = MacMarkdownEditor()
        reopenedCoordinator.attach(to: reopened)
        reopenedCoordinator.restore(model.draft, in: reopened)
        model.activateCapture() // Refresh queues behind the held write, without waiting for it.
        reopenedCoordinator.changed = { model.draft = reopened.string }
        reopened.setSelectedRange(NSRange(location: (expected as NSString).length, length: 0))
        reopened.insertText("!", replacementRange: reopened.selectedRange())
        XCTAssertEqual(Data(model.draft.utf8), Data((expected + "!").utf8))
        release.signal()
        await save.value
        XCTAssertEqual(Data(model.draft.utf8), Data((expected + "!").utf8))
        XCTAssertEqual(try VaultFile(url: file.url).read().captures.map(\.text), ["# **thought**"])
        XCTAssertEqual(model.notice, "Saved on this device")
    }

    @MainActor
    func testStorageFailureKeepsDraftAndRetryClearsOnlyAfterDurableSave() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = VaultFile(url: folder.appendingPathComponent("vault.json"))
        let failing = CaptureStorage(append: { _ in throw URLError(.cannotWriteToFile) }, load: { _ in Vault() })
        let model = VaultModel(url: file.url, notificationAccess: .disabled, captureStorage: failing)
        model.draft = "- [ ] **final** e\u{301}"
        await model.submitCapture()?.value
        XCTAssertEqual(model.draft, "- [ ] **final** e\u{301}")
        XCTAssertNotNil(model.error)
        XCTAssertNil(model.notice)
        XCTAssertTrue(model.vault.captures.isEmpty)
        // A real store verifies the successful side of the same UI boundary.
        let retry = VaultModel(url: file.url, notificationAccess: .disabled)
        retry.draft = model.draft
        await retry.submitCapture()?.value
        XCTAssertEqual(retry.draft, "")
        XCTAssertNil(retry.error)
        XCTAssertEqual(try VaultFile(url: file.url).read().captures.map(\.text), ["- [ ] **final** e\u{301}"])
    }

    @MainActor
    func testCopyAdvertisesOnlyMarkdownSourceForSelectedRange() throws {
        _ = NSApplication.shared
        let (_, editor) = MacMarkdownEditor.makeScrollableEditor()
        let coordinator = MacMarkdownEditor()
        coordinator.attach(to: editor)
        coordinator.restore("prefix **e\u{301} 👩🏽‍💻** suffix", in: editor)
        let selected = "**e\u{301} 👩🏽‍💻**"
        editor.setSelectedRange((editor.string as NSString).range(of: selected))
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        XCTAssertEqual(editor.writablePasteboardTypes, [.string])
        XCTAssertTrue(editor.writeSelection(to: board, types: editor.writablePasteboardTypes))
        XCTAssertEqual(Data(try XCTUnwrap(board.string(forType: .string)).utf8), Data(selected.utf8))
        XCTAssertNil(board.data(forType: .rtf))
        XCTAssertNil(board.data(forType: .html))
    }
}
#endif
