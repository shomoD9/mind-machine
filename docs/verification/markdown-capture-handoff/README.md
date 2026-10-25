# Markdown editor ticket 5: Capture handoff

Mac Save submits an immutable Markdown snapshot to background storage. Edits stay synchronous in memory. Durable completion clears only the submitted draft revision; newer writing survives. Pending duplicate saves are suppressed and failures retain the draft for retry. Close/reopen keeps the resident draft, including Unicode and final characters. Copy/cut exports selected Markdown as plain source only.

## Portable test-first evidence

The four vertical red/green slices are recorded in [portable-tests.txt](portable-tests.txt):

1. A delayed successful acknowledgement incorrectly returned permission to clear a newer draft (`XCTAssertFalse failed`).
2. Blank and duplicate submissions were accepted; a replayed completion also cleared (`XCTAssertNil` / `XCTAssertFalse failed`).
3. A source snapshot had no authored checklist items (`[]` versus four expected items).
4. A stubbed save acknowledged without persisting (`[]` versus the expected reopened Unicode source).

Each failed assertion was run before its implementation, then passed before the next slice. All 44 Linux SwiftPM tests pass (Swift 6.2.1); the held-storage test edits the main-actor handoff while the write executor waits on a semaphore. Storage completion is followed by a reopen through another VaultFile, rather than trusting the return value alone.

Reproduce: `swift test --package-path native --jobs 2`. Mac runtime tests run automatically in the unchanged native-ci and core-checks lanes; they cover real hosted SwiftUI binding/window recreation with no gap after final input, held write/read storage, newer typing, failure and durable save, and selected-source clipboard types. The real pill XCUITest now hides/reopens immediately before Save. Existing undo, IME, selection, command and timing tests remain intact.

## Before/after typing latency

Before: [raw samples](before.json), successful [ticket-4 native-ci run 40203281622](https://github.com/shomoD9/mind-machine/actions/runs/40203281622), head `fba087b8f0aba7ef0d3da0053d54d09523185e55`. This is the predecessor's unchanged Capture input path. Shared macOS 26 runner, Debug, 20 warm opens and 100 keys per fixture; nearest-rank percentiles in milliseconds. The existing harness counts and budgets are unchanged.

| Key dispatch → draw proxy | Before p50/p95/p99 | After p50/p95/p99 |
| --- | ---: | ---: |
| 1KiB | 1.953/4.087/4.574 | 1.304/1.711/3.554 |
| 10KiB | 1.516/3.924/5.166 | 1.451/1.989/2.620 |
| 100KiB | 1.852/6.108/7.454 | 1.276/3.247/3.630 |
| 100KiB-one-paragraph | 40.093/70.065/80.378 | 34.218/46.322/66.555 |

Warm open p50/p95/p99: 35.601/41.228/44.497 ms. After warm open p50/p95/p99: 34.983/36.564/36.684 ms. [After raw samples](after-round1.json) are from the successful sandbox job in [run 40209079845](https://github.com/shomoD9/mind-machine/actions/runs/40209079845), head `87ace2f`; all 61 sandbox checks passed. The unchanged huge-paragraph native layout remains above the proposed p95 budget. Host variation prevents attributing the before/after difference to this change. The held-write native test separately prints `MM_HANDOFF_BENCH`: p50/p95/max 0.238/1.278/1.278 ms over 10 character insertions with storage held (native-ci); the independent core-checks runner measured 0.363/0.721/0.721 ms. These short-fixture samples include editor styling/publication but exclude display/compositor latency. They demonstrate accepting input before storage is released, not a full physical typing speed claim.

These are synthetic shared-runner measurements. Draw completion is a proxy, not actual displayed pixels; Release M1 Air, OS event receipt, hardware IME and physical display latency remain unmeasured. The huge-paragraph baseline misses the research's proposed 33 ms p95 budget. No budget, timeout or fixture has been relaxed.

## Hosted verification

Round 1 `87ace2f`: both Linux checks and Mac build/sandbox passed. Read both failed Swift job logs ([native package](https://github.com/shomoD9/mind-machine/actions/runs/40209079845/job/121216236003), [core-checks](https://github.com/shomoD9/mind-machine/actions/runs/40209079863/job/121216235760)): each ran 73 tests (one pre-existing skip) and failed only the new clipboard check plus the existing copy/save/reopen check. The inherited single-type writer returned false/nil when only `.string` was advertised; all four other new handoff tests passed, including hosted binding/window recreation and held storage. Round 2 implements the selected-source single-type writer, preserving the failing assertions and using AppKit's existing multi-type declaration/dispatch. Same-session failure/retry and held-read assertions were strengthened. Trailing spaces in the copied portable transcript were removed. Native package/core-checks are pending the correction; other round-1 native jobs are still running. This Linux workspace cannot execute AppKit; syntax parsing is not presented as native runtime proof. Final check links, results and measured after samples will be recorded before completion. Protected workflows, signing, entitlements, Info.plist and PRODUCT are untouched. No merge is authorized.
