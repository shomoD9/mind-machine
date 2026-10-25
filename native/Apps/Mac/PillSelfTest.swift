/* CI self-test for the floating pill. Launched with "--pill-selftest <result.json>" (see MindMachineMac.swift),
 it drives the real window through expand, tab switching, typing, Esc, click-away, hotkey toggling,
 hide/show, dragging with persisted position, Reduce Motion and repeated cycles, records pass/fail checks and
 timings, writes PNG snapshots next to the result file, and exits with status 1 if any check failed.
 The native-ci workflow (mac-build job) runs it on a GitHub macOS runner and uploads the output.
 Frame sampling observes actual window resize notifications so actor scheduling cannot
 skip interpolation frames. The capture baseline records open/input and per-key
 dispatch/draw distributions without changing the editor; --capture-baseline-only
 and --capture-baseline-cold support the Release rerun script. Nothing here runs in normal use. */
// Capture baseline also records the source styler's measured paragraph work.
import AppKit
import MindMachinePill
import MindMachineUI
import os.signpost

@MainActor
enum PillSelfTest {
    static let suiteName = "dev.mindmachine.pill-selftest"

    static func run(controller: PillController, hotkeyStatus: OSStatus, outputPath: String, processEntry: Double) {
        Task { @MainActor in
            let runner = Runner(controller: controller, hotkeyStatus: hotkeyStatus, outputPath: outputPath,
                                processEntry: processEntry)
            await runner.execute()
        }
    }

    /// Resumes a continuation at most once, whichever of "settled" or "timed out" comes first.
    private final class Once {
        var done = false
    }

    @MainActor
    private final class Runner {
        let controller: PillController
        let hotkeyStatus: OSStatus
        let outputPath: String
        let processEntry: Double
        let timingLog = OSLog(subsystem: "dev.mindmachine.capture-baseline", category: .pointsOfInterest)
        var report: [String: Any] = [:]
        var checks: [String: Bool] = [:]

        init(controller: PillController, hotkeyStatus: OSStatus, outputPath: String, processEntry: Double) {
            self.controller = controller
            self.hotkeyStatus = hotkeyStatus
            self.outputPath = outputPath
            self.processEntry = processEntry
        }

        private var panel: PillPanel { controller.panel }

        // Repeated baseline checks must retain an early failure even if later
        // opens succeed; a dictionary assignment alone would lose that evidence.
        func check(_ name: String, _ ok: Bool) {
            checks[name] = (checks[name] ?? true) && ok
            print("[selftest] \(ok ? "PASS" : "FAIL") \(name)")
        }

        func sleep(_ seconds: Double) async { try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000)) }

        /// Runs `action` and returns the seconds until the resulting animation settled, or nil on timeout.
        func settle(_ action: () -> Void) async -> Double? {
            await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) in
                let once = Once()
                controller.onSettled = { _, seconds in
                    if !once.done { once.done = true; continuation.resume(returning: seconds) }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if !once.done { once.done = true; continuation.resume(returning: nil) }
                }
                action()
            }
        }

        /// Register before starting the transition and observe each actual AppKit
        /// resize synchronously. A sleeping actor task can miss frames while the
        /// main run loop animates; notifications record the window changes directly.
        func sampleFrames(_ action: () -> Void) async -> (duration: Double?, widths: [CGFloat]) {
            var widths = [panel.frame.width]
            let observer = NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification,
                                                                  object: panel, queue: .main) { [self] _ in
                MainActor.assumeIsolated { widths.append(panel.frame.width) }
            }
            defer { NotificationCenter.default.removeObserver(observer) }
            let duration = await settle(action)
            widths.append(panel.frame.width)
            return (duration, widths)
        }

        /// Seconds until `condition` holds, polling every 4 ms, or nil after one second.
        func wait(until condition: () -> Bool) async -> Double? {
            let start = CACurrentMediaTime()
            while CACurrentMediaTime() - start < 1 {
                if condition() { return CACurrentMediaTime() - start }
                await sleep(0.004)
            }
            return nil
        }

        func keyEvent(code: UInt16, characters: String, flags: NSEvent.ModifierFlags = []) -> NSEvent {
            NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0,
                             windowNumber: panel.windowNumber, context: nil, characters: characters,
                             charactersIgnoringModifiers: characters, isARepeat: false, keyCode: code)!
        }

        func mouseEvent(_ type: NSEvent.EventType) -> NSEvent {
            NSEvent.mouseEvent(with: type, location: .zero, modifierFlags: [], timestamp: 0,
                               windowNumber: panel.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)!
        }

        func ms(_ seconds: Double?) -> Double { seconds.map { ($0 * 100_000).rounded() / 100 } ?? -1 }

        func execute() async {
            let model = controller.model
            // Standalone probes share the production window and throwaway model.
            // Cold mode has no settling sleep before opening the capture surface.
            let coldOnly = CommandLine.arguments.contains("--capture-baseline-cold")
            if coldOnly || CommandLine.arguments.contains("--capture-baseline-only") {
                report["captureBaseline"] = await captureBaseline(coldOnly: coldOnly)
                finish()
            }
            await sleep(0.6)

            // 1. Window recipe: what makes it appear everywhere without stealing focus.
            report["screens"] = NSScreen.screens.count
            // A CI VM may have Reduce Motion on, which would make every timing below an instant jump.
            report["systemReduceMotion"] = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            controller.reduceMotionOverride = false
            report["activationPolicy"] = NSApp.activationPolicy().rawValue
            report["hotkeyRegistrationStatus"] = Int(hotkeyStatus)
            report["hotkeyRegistered"] = hotkeyStatus == noErr
            check("hotkey registered", hotkeyStatus == noErr)
            check("app is accessory (no Dock icon)", NSApp.activationPolicy() == .accessory)
            check("pill visible at launch", panel.isVisible)
            check("pill is not key (cannot steal focus)", !panel.isKeyWindow && !panel.canBecomeKey)
            check("level above floating windows", panel.level.rawValue >= NSWindow.Level.statusBar.rawValue)
            check("joins all Spaces", panel.collectionBehavior.contains(.canJoinAllSpaces))
            check("full-screen auxiliary", panel.collectionBehavior.contains(.fullScreenAuxiliary))
            check("non-activating", panel.styleMask.contains(.nonactivatingPanel))
            check("pill-sized window", panel.frame.size == PillGeometry.pillSize)
            let screens = PillController.currentScreens()
            if let screen = PillGeometry.screen(for: panel.frame, in: screens) {
                check("pill inside usable screen area", screen.visibleFrame.contains(panel.frame))
            }
            snapshot("pill-collapsed.png")
            screenshot("screen-collapsed.png")

            // 2. Expand once and inspect everything.
            let firstExpand = await settle { controller.send(.clickPill) }
            check("click expands to Capture", controller.state.phase == .expanded(.capture))
            check("panel is key after expanding", panel.isKeyWindow)
            check("panel fits its display", {
                guard let screen = PillGeometry.screen(for: panel.frame, in: screens) else { return false }
                return screen.visibleFrame.contains(panel.frame)
            }())
            let captureFocus = await wait { [self] in
                PillFocus.editor(for: .capture, in: controller.root.content).map(controller.holdsFocus) ?? false
            }
            check("note editor has focus after expanding", captureFocus != nil)
            report["captureFocusMs"] = ms(captureFocus)
            if let editor = panel.firstResponder as? NSTextView {
                editor.insertText("selftest note", replacementRange: NSRange(location: NSNotFound, length: 0))
            }
            check("typing reaches the shared draft", model.draft.contains("selftest note"))
            await sleep(0.25)
            snapshot("pill-expanded-capture.png")
            screenshot("screen-expanded.png")

            // 3. Cmd-2 and Cmd-1 switch tabs; the query field takes focus; the third slot refuses.
            _ = panel.performKeyEquivalent(with: keyEvent(code: 19, characters: "2", flags: .command))
            check("Cmd-2 switches to Recall", controller.state.phase == .expanded(.recall))
            check("vault mode follows", model.mode == 1)
            let recallFocus = await wait { [self] in
                PillFocus.editor(for: .recall, in: controller.root.content).map(controller.holdsFocus) ?? false
            }
            check("query field has focus after Cmd-2", recallFocus != nil)
            report["recallFocusMs"] = ms(recallFocus)
            if let editor = panel.firstResponder as? NSTextView {
                editor.insertText("hello", replacementRange: NSRange(location: NSNotFound, length: 0))
            }
            check("typing reaches the Recall query", model.query == "hello")
            controller.send(.select(.reserved))
            check("reserved third slot is not selectable", controller.state.phase == .expanded(.recall))
            await sleep(0.15)
            snapshot("pill-expanded-recall.png")
            _ = panel.performKeyEquivalent(with: keyEvent(code: 18, characters: "1", flags: .command))
            check("Cmd-1 switches back to Capture", controller.state.phase == .expanded(.capture) && model.mode == 0)
            check("capture draft survived the tab switch", model.draft.contains("selftest note"))

            // 4. Esc collapses.
            let escape = await settle { panel.sendEvent(keyEvent(code: 53, characters: "\u{1B}")) }
            check("Esc collapses to the pill", controller.state.phase == .collapsed && panel.frame.size == PillGeometry.pillSize)
            check("pill returned to its original spot", controller.pillFrame == panel.frame)
            check("draft kept after collapse", model.draft.contains("selftest note"))
            check("panel gave up key status", !panel.isKeyWindow)
            model.draft = ""; model.query = ""

            // 5. Hotkey toggles, click-away collapses, visibility toggles.
            controller.send(.hotkey)
            check("hotkey expands", controller.state.phase.isExpanded)
            controller.send(.hotkey)
            check("hotkey collapses", controller.state.phase == .collapsed)
            controller.send(.hotkey)
            _ = await settle { controller.send(.clickAway) }
            check("click away collapses", controller.state.phase == .collapsed)
            await sleep(0.3)
            controller.send(.toggleVisibility)
            check("Hide pill hides the window", !panel.isVisible)
            controller.send(.hotkey)
            check("hotkey still opens while the pill is hidden", panel.isVisible && controller.state.phase.isExpanded)
            _ = await settle { controller.send(.escape) }
            await sleep(0.05)
            check("closing returns to hidden", !panel.isVisible)
            controller.send(.toggleVisibility)
            check("Show pill shows the window", panel.isVisible)
            await sleep(0.3)

            // 6. Drag, click discrimination and persistence.
            let start = panel.frame
            var pointer = CGPoint(x: start.midX, y: start.midY)
            let handle = controller.root.handle
            handle.mouseLocation = { pointer }
            handle.mouseDown(with: mouseEvent(.leftMouseDown))
            pointer = CGPoint(x: pointer.x - 2, y: pointer.y + 1)
            handle.mouseDragged(with: mouseEvent(.leftMouseDragged))
            check("tiny movement is still a click", panel.frame.origin == start.origin)
            pointer = CGPoint(x: start.midX - 100, y: start.midY + 60)
            handle.mouseDragged(with: mouseEvent(.leftMouseDragged))
            handle.mouseUp(with: mouseEvent(.leftMouseUp))
            check("dragging moves the pill", panel.frame.origin != start.origin)
            check("drag did not expand", controller.state.phase == .collapsed)
            let saved = PillPreferences(defaults: UserDefaults(suiteName: PillSelfTest.suiteName) ?? .standard).center
            check("position persisted", saved != nil && abs(saved!.x - panel.frame.midX) < 0.5 && abs(saved!.y - panel.frame.midY) < 0.5)
            check("moved pill stays inside the screen", PillGeometry.screen(for: panel.frame, in: screens).map { $0.visibleFrame.contains(panel.frame) } ?? false)
            let restored = PillGeometry.resolvePillFrame(storedCenter: saved, screens: screens)
            check("a relaunch would restore the same spot", abs(restored.origin.x - panel.frame.origin.x) < 1 && abs(restored.origin.y - panel.frame.origin.y) < 1)
            // A real click on the moved pill opens the panel from there.
            handle.mouseLocation = { CGPoint(x: self.panel.frame.midX, y: self.panel.frame.midY) }
            handle.mouseDown(with: mouseEvent(.leftMouseDown))
            handle.mouseUp(with: mouseEvent(.leftMouseUp))
            check("click on the moved pill expands", controller.state.phase.isExpanded)
            let moved = controller.pillFrame
            _ = await settle { controller.send(.escape) }
            check("collapse returns to the dragged spot", controller.pillFrame.origin == moved.origin)
            handle.mouseLocation = { NSEvent.mouseLocation }

            // 6b. The window must pass through intermediate sizes, otherwise nothing is actually animating.
            let expansionFrames = await sampleFrames { controller.send(.clickPill) }
            let sampledExpand = expansionFrames.duration
            let between = PillGeometry.pillSize.width + 20 ..< PillGeometry.panelSize.width - 20
            let intermediate = Set(expansionFrames.widths.filter { between.contains($0) }).count
            report["expandWidths"] = expansionFrames.widths.map(Double.init)
            report["expandIntermediateWidths"] = intermediate
            report["expandSampledMs"] = ms(sampledExpand)
            check("expand passes through intermediate frames", intermediate >= 3)
            check("expand animation lasts about its configured duration", (sampledExpand ?? 0) >= PillMotion.expand * 0.8)
            let collapseFrames = await sampleFrames { controller.send(.escape) }
            let sampledCollapse = collapseFrames.duration
            let collapseIntermediate = Set(collapseFrames.widths.filter { between.contains($0) }).count
            report["collapseWidths"] = collapseFrames.widths.map(Double.init)
            report["collapseIntermediateWidths"] = collapseIntermediate
            report["collapseSampledMs"] = ms(sampledCollapse)
            check("collapse passes through intermediate frames", collapseIntermediate >= 3)
            check("collapse animation lasts about its configured duration", (sampledCollapse ?? 0) >= PillMotion.collapse * 0.8)
            await sleep(0.1)

            // 7. Timing: 20 expand/collapse cycles.
            var expands: [Double] = [], collapses: [Double] = []
            for _ in 0..<20 {
                if let t = await settle({ controller.send(.clickPill) }) { expands.append(t) }
                await sleep(0.05)
                if let t = await settle({ controller.send(.escape) }) { collapses.append(t) }
                await sleep(0.05)
            }
            report["expandMs"] = stats(expands)
            report["collapseMs"] = stats(collapses)
            report["firstExpandMs"] = ms(firstExpand)
            report["escapeCollapseMs"] = ms(escape)
            check("all 20 cycles completed", expands.count == 20 && collapses.count == 20)
            check("expand median settles in under 250 ms (180 ms animation plus callback latency)", median(expands) < 0.25)
            check("collapse median settles in under 250 ms (140 ms animation plus callback latency)", median(collapses) < 0.25)

            // 8. Reduce Motion makes both transitions instant.
            controller.reduceMotionOverride = true
            let instantOpen = await settle { controller.send(.clickPill) }
            let landedOpen = controller.state.phase.isExpanded && panel.frame.size.width >= PillGeometry.panelSize.width - 20
            let instantClose = await settle { controller.send(.escape) }
            report["reduceMotionExpandMs"] = ms(instantOpen)
            report["reduceMotionCollapseMs"] = ms(instantClose)
            check("Reduce Motion expands instantly", (instantOpen ?? 9) < 0.05 && landedOpen)
            check("Reduce Motion collapses instantly", (instantClose ?? 9) < 0.05 && panel.frame.size == PillGeometry.pillSize)
            controller.reduceMotionOverride = nil

            // 9. Idle cost with the pill showing.
            await sleep(0.5)
            let cpuStart = cpuSeconds(), wallStart = CACurrentMediaTime()
            await sleep(4)
            let idleCPU = (cpuSeconds() - cpuStart) / (CACurrentMediaTime() - wallStart) * 100
            report["idleCPUPercent"] = (idleCPU * 100).rounded() / 100
            report["residentMB"] = (residentMB() * 10).rounded() / 10
            check("idle CPU under 2 percent", idleCPU < 2)

            // Run after the idle check so typing/layout/spelling work cannot
            // contaminate that pre-existing smoke-test observation.
            report["captureBaseline"] = await captureBaseline(coldOnly: false)
            finish()
        }

        /// Nearest-rank percentiles retain tails, including every >100 ms stall.
        /// Samples stay in the JSON so comparisons can be recomputed externally.
        func distribution(_ samples: [Double], p95: Double? = nil, p99: Double? = nil) -> [String: Any] {
            let sorted = samples.sorted()
            guard !sorted.isEmpty else { return ["count": 0, "samplesMs": samples] }
            func percentile(_ fraction: Double) -> Double {
                sorted[max(0, Int(ceil(Double(sorted.count) * fraction)) - 1)]
            }
            var result: [String: Any] = ["count": sorted.count, "samplesMs": samples,
                "p50Ms": percentile(0.50), "p95Ms": percentile(0.95), "p99Ms": percentile(0.99),
                "maxMs": sorted.last!, "stallsOver100Ms": samples.filter { $0 > 100 }.count]
            if let p95 { result["p95BudgetMs"] = p95; result["withinP95Budget"] = percentile(0.95) <= p95 }
            if let p99 { result["p99BudgetMs"] = p99; result["withinP99Budget"] = percentile(0.99) <= p99 }
            return result
        }

        /// Wait for the first text line to be inside the animating window, with
        /// some presented opacity and the actual editor already first responder.
        /// Merely seeing a target alpha or a focusable view would measure too early.
        func readyEditor() -> NSTextView? {
            guard panel.isVisible, panel.isKeyWindow,
                  let editor = PillFocus.editor(for: .capture, in: controller.root.content) as? NSTextView,
                  controller.holdsFocus(editor), editor.isEditable,
                  !editor.isHiddenOrHasHiddenAncestor else { return nil }
            let content = controller.root.content
            let opacity = content.layer?.presentation()?.opacity ?? Float(content.alphaValue)
            let origin = editor.textContainerOrigin
            let firstLine = editor.convert(NSPoint(x: origin.x + 2, y: origin.y + 2), to: controller.root)
            guard opacity > 0, controller.root.bounds.contains(firstLine) else { return nil }
            return editor
        }

        /// Every open is timed from before the normal hotkey handler to a first
        /// key accepted by both the native view and its existing model binding.
        /// Never click the editor or repair focus on this observation path.
        func baselineOpen() async -> (milliseconds: Double, readyUptime: Double, textKit2: Bool)? {
            var settled = false
            controller.onSettled = { transition, _ in if transition.expanding { settled = true } }
            let signpost = OSSignpostID(log: timingLog)
            os_signpost(.begin, log: timingLog, name: "Capture open to input", signpostID: signpost)
            let start = ProcessInfo.processInfo.systemUptime
            controller.send(.hotkey)
            var editor: NSTextView?
            while ProcessInfo.processInfo.systemUptime - start < 2 {
                editor = readyEditor()
                if editor != nil { break }
                await sleep(0.001)
            }
            guard let editor else {
                os_signpost(.end, log: timingLog, name: "Capture open to input", signpostID: signpost)
                check("baseline open becomes visible and focused within 2 seconds", false)
                controller.onSettled = nil
                return nil
            }
            let expected = editor.string + "x"
            // Read only the modern manager: reading layoutManager can itself
            // irreversibly switch a modern view to the legacy layout engine.
            let modernBefore = editor.textLayoutManager != nil
            panel.sendEvent(keyEvent(code: 7, characters: "x"))
            editor.displayIfNeeded()
            let readyUptime = ProcessInfo.processInfo.systemUptime
            let elapsed = (readyUptime - start) * 1_000
            let modernAfter = editor.textLayoutManager != nil
            os_signpost(.end, log: timingLog, name: "Capture open to input", signpostID: signpost)
            let accepted = editor.string == expected && controller.model.draft == expected
            if !accepted { check("baseline immediate post-open key reaches view and model", false) }
            // Finish the current animation outside the measured interval before
            // another transition, avoiding superseded completion callbacks.
            let completed = await wait { settled }
            check("baseline open animation completes", completed != nil)
            controller.onSettled = nil
            return accepted ? (elapsed, readyUptime, modernBefore && modernAfter) : nil
        }

        func baselineClose() async {
            let completed = await settle { controller.send(.escape) }
            check("baseline close animation completes", completed != nil)
            controller.onSettled = nil
        }

        /// Fixtures go through the same binding restoration as reopened drafts;
        /// only setup places the caret. The timed keys use the window event path.
        func seedBaseline(_ text: String, editor: NSTextView) async -> Bool {
            controller.model.richDraft = nil
            controller.model.draft = text
            guard await wait(until: { editor.string == text }) != nil else {
                check("baseline fixture reaches the existing editor", false)
                return false
            }
            editor.setSelectedRange(NSRange(location: (text as NSString).length, length: 0))
            editor.scrollRangeToVisible(editor.selectedRange())
            editor.displayIfNeeded()
            return true
        }

        /// The CI baseline intentionally observes proposed budget misses rather
        /// than changing the editor or failing CI for an uncalibrated VM budget.
        /// Missing input, samples, focus or TextKit 2 remain correctness failures.
        func captureBaseline(coldOnly: Bool) async -> [String: Any] {
            let previousMotion = controller.reduceMotionOverride
            controller.reduceMotionOverride = false
            defer { controller.reduceMotionOverride = previousMotion }
            var baseline: [String: Any] = [
                "schemaVersion": 1,
                "os": ProcessInfo.processInfo.operatingSystemVersionString,
                "processorCount": ProcessInfo.processInfo.processorCount,
                "physicalMemoryBytes": ProcessInfo.processInfo.physicalMemory,
                "systemReduceMotion": NSWorkspace.shared.accessibilityDisplayShouldReduceMotion,
                "measurementReduceMotion": false,
                "openBoundary": "Before controller hotkey handler to visible first-line area, focus, first synthetic key in view/model, and displayIfNeeded completion; animation may still be running.",
                "typingBoundary": "Before window.sendEvent to return (dispatch), then displayIfNeeded completion (draw proxy). Excludes OS input queue and compositor/display scanout.",
                "visibleLatency": "Unmeasured. Draw completion is only a proxy; use signposts plus Instruments/video on physical hardware.",
                "customProcessing": ["status": "unmeasured: dispatch includes AppKit and app work", "p95BudgetMs": 2, "p99BudgetMs": 4],
                "budgetsAreProposed": true
            ]
            #if DEBUG
            baseline["configuration"] = "Debug"
            #else
            baseline["configuration"] = "Release"
            #endif
            // The existing sandbox smoke test has a 120-second process limit.
            // Keep its workload small; the standalone Release mode retains the
            // research's full 100-open/1,000-key counts without that CI deadline.
            let fullSample = CommandLine.arguments.contains("--capture-baseline-only")
            let keyCount = fullSample ? 1_000 : 100
            baseline["sampleProfile"] = coldOnly ? "single-cold-open" : fullSample ? "research-counts" : "ci-sample"
            var opens: [Double] = []
            var modern = true
            let count = coldOnly ? 1 : fullSample ? 100 : 20
            for _ in 0..<count {
                controller.model.draft = ""
                controller.model.richDraft = nil
                // Drain setup before starting the clock. Cold mode deliberately
                // includes all construction since main entry, including this turn.
                await sleep(0.001)
                if let opened = await baselineOpen() {
                    opens.append(opened.milliseconds)
                    modern = modern && opened.textKit2
                    if coldOnly {
                        baseline["readyUptimeSeconds"] = opened.readyUptime
                        baseline["processEntryUptimeSeconds"] = processEntry
                        baseline["processEntryToInputMs"] = (opened.readyUptime - processEntry) * 1_000
                    }
                }
                if !coldOnly {
                    await baselineClose()
                }
            }
            // This interval always starts at the handler. Only the manual
            // launcher's process-start interval is compared with the 500 ms gate.
            baseline["open"] = distribution(opens, p95: 100)
            check("baseline all expected opens accept immediate input", opens.count == count)
            if !coldOnly {
                // Open once for typing; its key is setup, outside the key distributions.
                if let opened = await baselineOpen(), let editor = panel.firstResponder as? NSTextView {
                    modern = modern && opened.textKit2
                    var documents: [String: Any] = [:]
                    for (name, bytes, paragraph) in [("1KiB", 1_024, false), ("10KiB", 10_240, false),
                                                      ("100KiB", 102_400, false), ("100KiB-one-paragraph", 102_400, true)] {
                        print("[baseline] Starting \(keyCount) keys in \(name)")
                        fflush(stdout)
                        let unit = paragraph ? "baseline text " : "baseline text\n"
                        let source = String(String(repeating: unit, count: bytes / unit.count + 1).prefix(bytes))
                        guard await seedBaseline(source, editor: editor) else { continue }
                        var dispatch: [Double] = [], draw: [Double] = [], styling: [Double] = []
                        for _ in 0..<keyCount {
                            let event = keyEvent(code: 7, characters: "x")
                            let signpost = OSSignpostID(log: timingLog)
                            os_signpost(.begin, log: timingLog, name: "Capture key to draw", signpostID: signpost)
                            let start = ProcessInfo.processInfo.systemUptime
                            panel.sendEvent(event)
                            dispatch.append((ProcessInfo.processInfo.systemUptime - start) * 1_000)
                            if let styler = editor.delegate as? MacMarkdownEditor {
                                styling.append(styler.lastStyleMilliseconds)
                            }
                            editor.displayIfNeeded()
                            draw.append((ProcessInfo.processInfo.systemUptime - start) * 1_000)
                            os_signpost(.end, log: timingLog, name: "Capture key to draw", signpostID: signpost)
                            modern = modern && editor.textLayoutManager != nil
                            // Give SwiftUI and AppKit a run-loop turn between keys;
                            // pacing is outside the measured interval.
                            await sleep(0.001)
                        }
                        let expected = source + String(repeating: "x", count: keyCount)
                        check("baseline \(name) retains every key in view and model", editor.string == expected && controller.model.draft == expected)
                        documents[name] = ["initialUTF8Bytes": bytes, "dispatch": distribution(dispatch),
                                           "dispatchToDrawProxy": distribution(draw, p95: 33, p99: 50),
                                           "paragraphStyling": distribution(styling, p95: 2, p99: 4)]
                        print("[baseline] Completed \(name)")
                        fflush(stdout)
                    }
                    baseline["typing"] = documents
                    check("baseline all four typing fixtures measured", documents.count == 4)
                    // No global pasteboard mutation: insertText exercises a single
                    // large text insertion, explicitly labelled as a paste proxy.
                    if await seedBaseline("", editor: editor) {
                        let pasted = String(repeating: "baseline paste\n", count: 74_899)
                        let source = String(pasted.prefix(1_048_576))
                        let start = ProcessInfo.processInfo.systemUptime
                        editor.insertText(source, replacementRange: NSRange(location: NSNotFound, length: 0))
                        editor.displayIfNeeded()
                        baseline["oneMiBInsertToDrawProxyMs"] = (ProcessInfo.processInfo.systemUptime - start) * 1_000
                        check("baseline 1MiB insertion retains exact source", editor.string == source && controller.model.draft == source && source.utf8.count == 1_048_576)
                        modern = modern && editor.textLayoutManager != nil
                    }
                    await baselineClose()
                    controller.model.draft = ""
                    controller.model.richDraft = nil
                } else {
                    check("baseline typing editor is focused", false)
                }
            }
            baseline["textKit2Throughout"] = modern && opens.count == count
            check("baseline TextKit 2 remains active before and after input", modern && opens.count == count)
            return baseline
        }

        /// Write the measured artifact before exiting; failed observations retain their samples.
        func finish() -> Never {
            report["checks"] = checks
            let failed = checks.filter { !$0.value }.map(\.key).sorted()
            report["failed"] = failed
            do {
                let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
                try data.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
                print(String(decoding: data, as: UTF8.self))
            } catch {
                print("[selftest] FAIL could not write measurement report")
                fflush(stdout)
                exit(1)
            }
            print("[selftest] \(checks.count - failed.count)/\(checks.count) checks passed")
            fflush(stdout)
            exit(failed.isEmpty ? 0 : 1)
        }

        /// Middle sample, or a large number when there are none so a missing measurement fails its check.
        func median(_ values: [Double]) -> Double { values.isEmpty ? 9 : values.sorted()[values.count / 2] }

        func stats(_ values: [Double]) -> [String: Double] {
            guard !values.isEmpty else { return [:] }
            let sorted = values.sorted()
            return ["min": ms(sorted.first), "p50": ms(sorted[sorted.count / 2]), "max": ms(sorted.last), "samples": Double(sorted.count)]
        }

        func cpuSeconds() -> Double {
            var usage = rusage()
            getrusage(RUSAGE_SELF, &usage)
            return Double(usage.ru_utime.tv_sec) + Double(usage.ru_utime.tv_usec) / 1e6
                + Double(usage.ru_stime.tv_sec) + Double(usage.ru_stime.tv_usec) / 1e6
        }

        func residentMB() -> Double {
            var info = mach_task_basic_info()
            var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
            let result = withUnsafeMutablePointer(to: &info) { pointer in
                pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                    task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
                }
            }
            return result == KERN_SUCCESS ? Double(info.resident_size) / 1_048_576 : -1
        }

        /// Whole-screen capture through the system tool; best effort, because a runner may deny screen recording.
        func screenshot(_ name: String) {
            let directory = URL(fileURLWithPath: outputPath).deletingLastPathComponent()
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-x", directory.appendingPathComponent(name).path]
            try? process.run()
            process.waitUntilExit()
        }

        /// Renders the window's own view tree to a PNG beside the result file (no Screen Recording permission needed).
        func snapshot(_ name: String) {
            let view = controller.root
            guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
            view.cacheDisplay(in: view.bounds, to: rep)
            let directory = URL(fileURLWithPath: outputPath).deletingLastPathComponent()
            try? rep.representation(using: .png, properties: [:])?.write(to: directory.appendingPathComponent(name))
        }
    }
}
