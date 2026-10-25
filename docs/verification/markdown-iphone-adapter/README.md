# iPhone Markdown adapter evidence

Research item 7, local ticket 32. The companion now creates `IPhoneMarkdownTextView(usingTextLayoutManager: true)` through `IPhoneMarkdownEditor.makeEditor()`. Before this change it created a default `UITextView`, restored RTF, compared Swift strings canonically and encoded RTF on each input callback. It now derives disposable attributes and publishes exact source with no rich payload. Source/range/block/command logic is reused unchanged from MindMachineCore; no AppKit import was added to it. Companion Save uses the existing asynchronous Capture handoff; the keyboard keeps its own editor and synchronous Save.

## Local checks

- Swift 6.2.1 Linux: all 53 portable core tests pass, including existing parser, 4,800-edit incremental oracle, UTF-16 command and handoff cases. No shared core logic changed.
- Python watchdog: all 17 tests pass.
- iOS Swift syntax parsing passes on Linux. This cannot type-check UIKit or prove native behavior.
- `git diff --check` passes. No workflow, signing, entitlement, Info.plist, PRODUCT, dependency or existing budget/test assertions changed.

## Simulator execution

The existing `MindMachineKeyboardUITests` scheme now includes `IPhoneMarkdownAcceptanceTests`. It launches the Simulator-only host with `--iphone-markdown-probe`; the production keyboard tests still use their original host mode. The new probe uses the real companion factory/delegate and a real SwiftUI `RichNoteEditor`, native `setMarkedText`/`unmarkText`, undo/redo, clipboard and durable vault reopen. XCTest retains its JSON report and screenshot in `keyboard-ui.xcresult`.

```sh
xcodebuild -project native/MindMachine.xcodeproj -scheme MindMachineKeyboardUITests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -parallel-testing-enabled NO -resultBundlePath keyboard-ui.xcresult test
```

Checks cover exact NFC/NFD replacements, emoji/combining marks, typed Markdown styles and source-only clipboard, split/join invalidation, real UIKit marked input, restore/command deferral, list/task/ordered continuation and empty-item exit, one-step undo/redo, selected task toggling, final-key publication before detach, representable recreation and plain-Markdown durable save/reopen. Native marked-range injection verifies the adapter contract; system IME candidate UI remains a physical check.

The timing probe records 1,000 native `insertText` calls per 1/10/100 KiB multiline note and one 100 KiB huge paragraph, plus a >1 MB Unicode paste. It reports p50/p95/p99/max separately and >100 ms input calls. Style samples cover bounded custom presentation only. Input-call durations include native editing and source publication, ending at return from `insertText`; they do not prove visible pixels, event delivery, keyboard latency or all SwiftUI layout. Debug Simulator samples must be compared with the unchanged 2/4 ms custom-processing, 33/50 ms visible and 100 ms stall budgets without claiming physical Release compliance. Style intervals are available through the `iPhone Markdown` signposter for Instruments.

Hosted results and measured distributions are pending the first PR run.

## Shomo's TestFlight checklist

- [ ] On physical iOS17 hardware, type/paste/copy/save/reopen headings, emphasis, links and tasks with `é` and `👩🏽‍💻`; compare exact Markdown source.
- [ ] Compose Japanese/Chinese through the real IME candidate bar; commit/cancel, move selection and undo/redo without dropped or duplicated text.
- [ ] Continue/exit bullets, ordered lists and checked/unchecked tasks; undo each command once, then redo; try hardware Tab/Shift-Tab and Cmd-Shift-Return.
- [ ] Type final characters then leave/reopen Capture; save while continuing a newer draft and confirm it survives acknowledgement. Check keyboard extension behavior remains unchanged.
- [ ] On the smallest supported iPhone, profile a Release build with Instruments/signposts and high-frame-rate video: 1,000 keys on 1/10/100 KiB notes, huge paragraph and 1 MB paste. Verify custom p95 ≤2/p99 ≤4 ms, visible p95 ≤33/p99 ≤50 ms and no >100 ms typing stalls. Check selection, wrapping, scrolling and VoiceOver.
