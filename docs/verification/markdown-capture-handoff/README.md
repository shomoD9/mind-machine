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

| Before key dispatch → draw proxy | p50 | p95 | p99 |
| --- | ---: | ---: | ---: |
| 1KiB | 1.953 | 4.087 | 4.574 |
| 10KiB | 1.516 | 3.924 | 5.166 |
| 100KiB | 1.852 | 6.108 | 7.454 |
| 100KiB-one-paragraph | 40.093 | 70.065 | 80.378 |

Warm open p50/p95/p99: 35.601/41.228/44.497 ms. After samples will be added from this PR's actual sandbox artifact. The held-write native test separately prints `MM_HANDOFF_BENCH` input-processing samples; those exclude display/compositor latency.

These are synthetic shared-runner measurements. Draw completion is a proxy, not actual displayed pixels; Release M1 Air, OS event receipt, hardware IME and physical display latency remain unmeasured. The huge-paragraph baseline misses the research's proposed 33 ms p95 budget. No budget, timeout or fixture has been relaxed.

## Hosted verification

First implementation checkpoint: pending. This Linux workspace cannot execute AppKit; syntax parsing is not presented as native runtime proof. Final check links, results and measured after samples will be recorded before completion. Protected workflows, signing, entitlements, Info.plist and PRODUCT are untouched. No merge is authorized.
