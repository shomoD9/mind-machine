# Markdown editor ticket 6: bounded preview comparison

Keep muted markers. Collapsing inactive Markdown markers is accepted only after every gate passes; the small candidate below changes wrapping when its paragraph opens. Both first-round hosted lanes measured the trailing word at y=90 pt muted, y=18 pt collapsed, and y=90 pt revealed: 72 pt of reflow. No production editor code or package dependency changes in this comparison.

Source: `/workspace/research/markdown-editor.md` (25 October 2026), ticket 6 and Speed gates and measurement. Local tracker: [31](../../.scratch/native-mvp/issues/31-markdown-preview-comparison.md). Baseline: main `12f53bd`. Context invalidation and capture handoff are separate open branches at comparison start; this rejection experiment does not claim their acceptance.

## Candidate and licence

Reference pinned to [NoteKit `8b2c446413d98b5180d52ab35f1a919398e48a7f`](https://github.com/tfcace/NoteKit/tree/8b2c446413d98b5180d52ab35f1a919398e48a7f). Its [MIT licence](https://github.com/tfcace/NoteKit/blob/8b2c446413d98b5180d52ab35f1a919398e48a7f/LICENSE) names Copyright (c) 2026 Assaf Schwartz and requires retaining the notice when redistributing copies/substantial portions. The pinned [manifest](https://github.com/tfcace/NoteKit/blob/8b2c446413d98b5180d52ab35f1a919398e48a7f/Package.swift) has no external package dependencies. No NoteKit source is vendored or linked here.

The pinned [styler](https://github.com/tfcace/NoteKit/blob/8b2c446413d98b5180d52ab35f1a919398e48a7f/Sources/NoteKit/NoteStyling.swift) collapses inline/heading/link syntax outside the caret paragraph; painted lists keep their layout. Its [native adapter](https://github.com/tfcace/NoteKit/blob/8b2c446413d98b5180d52ab35f1a919398e48a7f/Sources/NoteKit/NoteTextView.swift) and [click tests](https://github.com/tfcace/NoteKit/blob/8b2c446413d98b5180d52ab35f1a919398e48a7f/Tests/NoteKitTests/HiddenMarkerTests.swift) handle a click sequence before reveal. That is relevant integration work even though the package itself has no dependencies.

`MarkdownPreviewComparisonTests` independently implements the simplest equivalent: existing `MarkdownParagraph` marker spans receive clear foreground and a 0.1 pt font outside the caret paragraph; reveal restores their original font/secondary colour. Only the previous/current bounded paragraphs repaint, preserving the 8,192 UTF-16 cap and plain huge-paragraph fallback. A test delegate forwards actual edits to the production coordinator and leaves its storage delegate attached. Attributes stay outside native undo and marked text postpones repaint. This intentionally omits delayed click handling, painted list replacements and custom accessibility. It evaluates this small candidate, without making a quality/performance claim about the complete NoteKit or Engine editors. Expanding into a replacement editor after a rejection would exceed this ticket's scope.

## Native comparison

The experiment runs through `MacMarkdownEditor.makeScrollableEditor()` and the real `MacMarkdownEditor` coordinator in the existing Mac SwiftPM jobs. TextKit 2 segment geometry, actual text storage, native selection, copy, undo/redo and marked input are exercised. No legacy `layoutManager` property is accessed.

The wrapping fixture contains a link with a long destination between `outside` and `last` paragraphs. Its final `tail` word has a different vertical position when the link's markers/destination collapse. Entering the paragraph reveals them and moves `tail` back. This is a demonstrated reason to retain muted markers under the required wrapping gate. The test asserts the rejection behavior, so a green check means the experiment reproduced the problem.

| Acceptance gate | Evidence and decision boundary |
| --- | --- |
| Caret clicks | Segment geometry measured; physical single/double/triple-click and drag behavior unproven. No click-gate pass claimed. Immediate reveal lacks the pinned reference's click-sequence deferral. |
| Wrapping | Both first-round hosted lanes: muted → collapsed → revealed `tail` y=90 →18 →90 pt. Reject the simple candidate's 72 pt reflow without click-sequence handling. |
| VoiceOver | Unmeasured. AppKit text source/attributes and green UI tests cannot establish spoken navigation, selection, punctuation or editing behavior. |
| Selection/source | Candidate test checks exact UTF-8 including emoji/decomposed accents, preserved native range and plain-source clipboard. Hosted result pending. Drag/word selection remains unproven. |
| Undo | Candidate test inserts, undoes once with no remaining undo action, and redoes; presentation does not register undo. Hosted result pending. |
| Composition | Real marked-input repaint deferral and committed Japanese source are checked. Hosted result pending; no physical IME latency claim. |
| Every speed gate | Paired diagnostic measurements below; required Release/hardware/full-count/pixel/custom-work gates remain unproven. |

## Before/after timing protocol

Both variants run in the same process on a shared macOS 26 hosted runner, Debug SwiftPM build, at a 360 × 240 pt window. Pass 1 runs muted then collapsed; pass 2 reverses order. Each variant/fixture receives 100 synthetic `x` key events through the window, with exact final source and active TextKit 2 asserted. Fixtures are 1/10/100 KiB mixed Markdown plus a separate 100 KiB paragraph, followed by a 1 MiB `insertText` paste proxy. Large restores retain the production source-mode fallback; this is not a fully rendered 100 KiB Markdown-document benchmark. There is no vault/SwiftUI model or storage in this isolated comparison.

Ordered samples, count, nearest-rank p50/p95/p99, max and >100 ms count print as `MM_PREVIEW` JSON in the existing native-ci/core-checks test logs. The core-checks artifact retains its console output. `MM_PREVIEW_REJECTION` prints wrapping geometry. The bounded 100-key sample is diagnostic after rejection; it cannot satisfy the research's 1,000-key acceptance protocol.

| Metric | Measured interval | Required gate and limitation |
| --- | --- | --- |
| `dispatch` | Window `sendEvent` entry → return | Includes native work; cannot isolate all custom main-thread processing. |
| `dispatch-to-draw-proxy` | Same event entry → `displayIfNeeded` and CA flush return | Compare p95 33 ms/p99 50 ms and >100 ms stalls diagnostically. No compositor/scanout or OS input queue measurement. |
| `presentation-only` | Production styler interval plus all candidate repaint intervals during dispatch | Compare p95 2 ms/p99 4 ms diagnostically. Omits other app custom work, so passing is insufficient. |
| `insert-to-draw-proxy` | 1 MiB `insertText` → draw return | One observation per pass; no paste budget specified. |
| Warm/cold open | Existing unchanged app self-test/manual baseline protocol | Candidate is test-only, so no candidate hotkey/open timing is claimed. Required warm p95 ≤100 ms (100 opens), cold p95 ≤500 ms (30 terminated-process opens). |

Hosted numbers pending. The [baseline manual procedure](markdown-editor-baseline.md) retains the full 1,000 keys, 100 warm opens and 30 cold opens on Release M1 Air/8 GB, macOS 14 and current OS. Instruments and high-frame-rate video must establish actual pixels, all custom processing and no >100 ms typing stalls. This comparison stops after rejection and does not invent those measurements.

## Rerun and scope

On a Mac:

```sh
swift test --package-path native --filter MarkdownPreviewComparisonTests
```

Existing hosted Mac tests, app builds, sandbox self-test and UI journeys run without workflow changes. Linux runs the portable suite and syntax-parses the new Swift file; it cannot execute AppKit. Hosted and local check results will be recorded here and in the PR.

Only a test file, this evidence, DESIGN, the journal and local tracker change. Runtime behavior, source mode and muted-marker appearance remain the baseline. No other feature or performance work is included. The PR must remain unmerged; any future visible editor change requires Shomo's approval.
