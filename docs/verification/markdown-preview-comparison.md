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
| Selection/source | Candidate test checks exact UTF-8 including emoji/decomposed accents, preserved native range and plain-source clipboard. Passed in both green Mac lanes. Drag/word selection remains unproven. |
| Undo | Candidate test inserts, undoes once with no remaining undo action, and redoes; presentation does not register undo. Passed in both green Mac lanes. |
| Composition | Real marked-input repaint deferral and committed Japanese source are checked. Passed in both green Mac lanes; no physical IME latency claim. |
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

The recorded measurements below are diagnostic. The [baseline manual procedure](markdown-editor-baseline.md) retains the full 1,000 keys, 100 warm opens and 30 cold opens on Release M1 Air/8 GB, macOS 14 and current OS. Instruments and high-frame-rate video must establish actual pixels, all custom processing and no >100 ms typing stalls. This comparison stops after rejection and does not invent those measurements.

## Recorded before/after measurements

Measured at `1fa22ac` in [native-ci 40215135518, SwiftPM job](https://github.com/shomoD9/mind-machine/actions/runs/40215135518/job/121234757049). macOS 26.6.2 arm64 hosted VM, Xcode 26.2, Debug; 100 keys per cell. The same-process before is muted, after is the test-only candidate. Each pass is kept separate; no tails are averaged. The second pass runs collapsed first. All 52 JSON rows decoded, with zero malformed rows; the separate [core-checks job](https://github.com/shomoD9/mind-machine/actions/runs/40215135527/job/121234532023) independently retained 52 valid rows and reproduced the 90 →18 →90 pt rejection.

Dispatch-to-draw proxy:

| Fixture | Pass | Muted p50 / p95 / p99 / max (ms); >100 ms count | Collapsed p50 / p95 / p99 / max (ms); >100 ms count |
| --- | --- | --- | --- |
| 1KiB | 1 | 3.499 / 7.204 / 8.463 / 19.343; 0 | 3.519 / 7.762 / 8.643 / 9.102; 0 |
| 10KiB | 1 | 5.702 / 10.404 / 11.994 / 14.076; 0 | 4.673 / 9.202 / 23.482 / 36.346; 0 |
| 100KiB | 1 | 12.690 / 18.381 / 21.934 / 30.644; 0 | 11.998 / 13.666 / 16.300 / 18.247; 0 |
| 100KiB-one-paragraph | 1 | 107.562 / 137.496 / 144.258 / 144.339; 63 | 97.252 / 133.487 / 162.273 / 223.812; 45 |
| 1KiB | 2 | 4.223 / 8.391 / 12.212 / 16.735; 0 | 4.558 / 11.359 / 16.168 / 17.107; 0 |
| 10KiB | 2 | 5.093 / 9.418 / 11.547 / 12.278; 0 | 6.181 / 15.159 / 29.666 / 29.737; 0 |
| 100KiB | 2 | 11.920 / 13.291 / 13.711 / 14.080; 0 | 14.700 / 27.015 / 62.885 / 65.855; 0 |
| 100KiB-one-paragraph | 2 | 99.107 / 130.516 / 163.816 / 180.126; 49 | 132.582 / 257.792 / 376.044 / 455.530; 92 |

Presentation work only (production styler plus candidate repaint; other app custom work is excluded):

| Fixture | Pass | Muted p50 / p95 / p99 (ms) | Collapsed p50 / p95 / p99 (ms) |
| --- | --- | --- | --- |
| 1KiB | 1 | 0.197 / 0.496 / 0.691 | 0.388 / 1.156 / 1.605 |
| 10KiB | 1 | 0.227 / 0.585 / 0.789 | 0.479 / 1.263 / 4.173 |
| 100KiB | 1 | 0.203 / 0.550 / 1.005 | 0.524 / 0.773 / 1.139 |
| 100KiB-one-paragraph | 1 | 0.209 / 0.462 / 0.510 | 1.043 / 1.418 / 1.843 |
| 1KiB | 2 | 0.236 / 0.575 / 0.703 | 0.602 / 1.976 / 2.679 |
| 10KiB | 2 | 0.212 / 0.501 / 0.627 | 0.615 / 1.929 / 5.470 |
| 100KiB | 2 | 0.193 / 0.422 / 0.490 | 0.653 / 1.722 / 3.750 |
| 100KiB-one-paragraph | 2 | 0.205 / 0.372 / 0.560 | 1.202 / 2.915 / 3.270 |

1 MiB insert-to-draw proxy, one sample per variant/pass: muted 437.481 / 653.391 ms; collapsed 611.443 / 568.592 ms. Exact source survived each insertion; these are not paste percentile distributions.

Both variants miss the proposed huge-paragraph glyph budgets and have >100 ms diagnostic stalls. Candidate pass 2 additionally misses p99 50 ms at 100 KiB (62.885 ms), presentation p95 2 ms on the huge paragraph (2.915 ms), and presentation p99 4 ms at 10 KiB (5.470 ms; pass 1 also 4.173 ms). Shared-runner variance prevents attributing all changes to hiding: the independent core-checks draw p95 at 100 KiB is muted 16.739/21.900 and collapsed 17.599/27.753 ms. These measurements support rejection and do not justify a performance fix in ticket 6.

All three candidate tests pass in both green Mac lanes, including exact Unicode source/copy, native selection, undo/redo and marked-input deferral. Main-package result: 69 tests, one pre-existing skip, zero failures; Pill tests and all fixed-order gates also pass. All eight PR checks on `1fa22ac` pass, including the unchanged sandbox self-test, both native UI jobs and app builds. Final evidence-checkpoint checks are watched separately. Raw ordered samples remain in the linked job logs and core-checks artifact.

## Rerun and scope

On a Mac:

```sh
swift test --package-path native --filter MarkdownPreviewComparisonTests
```

Existing hosted Mac tests, app builds, sandbox self-test and UI journeys run without workflow changes. Linux runs the portable suite and syntax-parses the new Swift file; it cannot execute AppKit. Local Swift 6.2.1 portable suite: 39 tests passed; new Swift syntax parsing and whitespace checks passed. Hosted results are recorded above and in the PR.

Only a test file, this evidence, DESIGN, the journal and local tracker change. Runtime behavior, source mode and muted-marker appearance remain the baseline. No other feature or performance work is included. The PR must remain unmerged; any future visible editor change requires Shomo's approval.

First checkpoint `4168f50`: native-ci [40213570027](https://github.com/shomoD9/mind-machine/actions/runs/40213570027) and core-checks [40213570072](https://github.com/shomoD9/mind-machine/actions/runs/40213570072) both pass the wrapping-rejection and paired timing tests. Both stop the source/undo fixture on `NSUndoManager ... must begin a group before registering undo`: the harness disabled event grouping but supplied no explicit group for direct insertion. The correction adds synthetic event groups and keeps the same one-undo/redo assertions. JSON output is changed to a single write per row after buffered prints interleaved with XCTest logs. The unchanged Mac app passes 73/74 checks; only Recall-card draw p95 fails (39.690 ms versus 33 ms). Both Linux checks, Mac UI and iOS build pass; keyboard UI was cancelled. No baseline/Recall performance code or gate is changed.

The downloaded `pill-selftest/result.json` from green run 40215135518 has `failed: []`, all 74 checks true and unchanged Recall-card draw p95 31.620 ms. Its first-run miss is retained above; no production change was needed for the later pass.
