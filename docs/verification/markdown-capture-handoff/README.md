# Markdown editor ticket 5: Capture handoff

Mac Save submits an immutable Markdown snapshot to background storage. Edits stay synchronous in memory. Durable completion clears only the submitted draft revision; newer writing survives. Pending duplicate saves are suppressed and failures retain the draft for retry. Close/reopen keeps the resident draft, including Unicode and final characters. Copy/cut exports selected Markdown as plain source only.

## Portable test-first evidence

The four vertical red/green slices are recorded in [portable-tests.txt](portable-tests.txt):

1. A delayed successful acknowledgement incorrectly returned permission to clear a newer draft (`XCTAssertFalse failed`).
2. Blank and duplicate submissions were accepted; a replayed completion also cleared (`XCTAssertNil` / `XCTAssertFalse failed`).
3. A source snapshot had no authored checklist items (`[]` versus four expected items).
4. A stubbed save acknowledged without persisting (`[]` versus the expected reopened Unicode source).

Each failed assertion was run before its implementation, then passed before the next slice. All 44 Linux SwiftPM tests pass (Swift 6.2.1); the held-storage test edits the main-actor handoff while the write executor waits on a semaphore. Storage completion is followed by a reopen through another VaultFile, rather than trusting the return value alone.

Reproduce: `swift test --package-path native --jobs 2`; on Mac, `swift test --package-path native --filter MacCaptureHandoffTests` drives the adapter directly. The [existing baseline harness and Release rerun](../markdown-editor-baseline.md) reproduce the open/typing samples. Mac runtime tests run automatically in the unchanged native-ci and core-checks lanes; they cover real hosted SwiftUI binding/window recreation with no gap after final input, held write/read storage, newer typing, failure and durable save, and selected-source clipboard types. The real pill XCUITest now hides/reopens immediately before Save. Existing undo, IME, selection, command and timing tests remain intact.

## Before/after typing latency

Before: [raw samples](before.json), successful [ticket-4 native-ci run 40203281622](https://github.com/shomoD9/mind-machine/actions/runs/40203281622), head `fba087b8f0aba7ef0d3da0053d54d09523185e55`. This is the predecessor's unchanged Capture input path. Shared macOS 26 runner, Debug, 20 warm opens and 100 keys per fixture; nearest-rank percentiles in milliseconds. The existing harness counts and budgets are unchanged.

| Key dispatch → draw proxy | Before p50/p95/p99 | Round 1 p50/p95/p99 | Round 2 p50/p95/p99 |
| --- | ---: | ---: | ---: |
| 1KiB | 1.953/4.087/4.574 | 1.304/1.711/3.554 | 1.324/2.331/2.627 |
| 10KiB | 1.516/3.924/5.166 | 1.451/1.989/2.620 | 1.457/2.373/4.785 |
| 100KiB | 1.852/6.108/7.454 | 1.276/3.247/3.630 | 1.881/7.617/10.033 |
| 100KiB-one-paragraph | 40.093/70.065/80.378 | 34.218/46.322/66.555 | 46.157/61.925/74.776 |

Warm open p50/p95/p99: 35.601/41.228/44.497 ms. After warm open p50/p95/p99: 34.983/36.564/36.684 ms. [After raw samples](after-round1.json) are from the successful sandbox job in [run 40209079845](https://github.com/shomoD9/mind-machine/actions/runs/40209079845), head `87ace2f`; all 61 sandbox checks passed. The unchanged huge-paragraph native layout remains above the proposed p95 budget. Host variation prevents attributing the before/after difference to this change. Round 2 [raw samples](after-round2.json) at `61bbb91` also pass every sandbox check: open p50/p95/p99 26.289/42.047/47.080 ms. Its held-write input p50/p95/max is 0.172/0.285/0.285 ms (native-ci) and 0.188/0.308/0.308 ms (core-checks). Variation between these two unchanged input paths further rules out a general speedup claim. The held-write native test separately prints `MM_HANDOFF_BENCH`: p50/p95/max 0.238/1.278/1.278 ms over 10 character insertions with storage held (native-ci); the independent core-checks runner measured 0.363/0.721/0.721 ms. These short-fixture samples include editor styling/publication but exclude display/compositor latency. They demonstrate accepting input before storage is released, not a full physical typing speed claim.

These are synthetic shared-runner measurements. Draw completion is a proxy, not actual displayed pixels; Release M1 Air, OS event receipt, hardware IME and physical display latency remain unmeasured. The huge paragraph misses the proposed 33 ms p95 and 50 ms p99 budgets before and after. Its >100 ms draw-proxy turns are 1/100 before (max 101.097 ms), 0/100 in round 1 (max 93.255 ms), and 1/100 in round 2 (max 127.380 ms). This ticket does not establish all research speed gates. No budget, timeout or fixture has been relaxed.

## Hosted verification

Round 1 `87ace2f`: both Linux checks and Mac build/sandbox passed. Read both failed Swift job logs ([native package](https://github.com/shomoD9/mind-machine/actions/runs/40209079845/job/121216236003), [core-checks](https://github.com/shomoD9/mind-machine/actions/runs/40209079863/job/121216235760)): each ran 73 tests (one pre-existing skip) and failed only the new clipboard check plus the existing copy/save/reopen check. The inherited single-type writer returned false/nil when only `.string` was advertised; all four other new handoff tests passed, including hosted binding/window recreation and held storage. Round 2 implements the selected-source single-type writer, preserving the failing assertions and using AppKit's existing multi-type declaration/dispatch. Same-session failure/retry and held-read assertions were strengthened. Trailing spaces in the copied portable transcript were removed. Round 1 was superseded after the clipboard failure; its unfinished jobs were cancelled by the existing concurrency policy.

Round 2 `61bbb91`: [native package](https://github.com/shomoD9/mind-machine/actions/runs/40210059709/job/121219191615) passes 73 tests (one pre-existing skip), including all five Mac handoff tests and the original Unicode copy/save/reopen regression. [Core gates](https://github.com/shomoD9/mind-machine/actions/runs/40210059734/job/121219170164) pass 73 package/35 Pill tests, bounded model controls, unchanged Release query/save budgets, process durability and unsigned bundle checks. The [Mac UI journey](https://github.com/shomoD9/mind-machine/actions/runs/40210059709/job/121219191669), Mac build/sandbox, iOS build and both Linux checks pass. The [keyboard Simulator journey](https://github.com/shomoD9/mind-machine/actions/runs/40210059709/job/121219191601) also passed in 20m15s: all eight hosted checks are green at this implementation head. [Selected native outputs](native-tests.txt) preserve the exact handoff test outcomes and timing lines. This Linux workspace cannot execute AppKit; syntax parsing is not presented as native runtime proof. The third push contains evidence/journal/tracker updates only; its current check status is visible on [PR #18](https://github.com/shomoD9/mind-machine/pull/18) and the final PR body. No application code changed after the successful round-2 checkpoint. Protected workflows, signing, entitlements, Info.plist and PRODUCT are untouched. No merge is authorized.
