# Capture speed

Ticket 27 measures only Mac Capture performance. Raw synthetic samples: [baseline](baseline.json) at latest-main `61eca6a` ([run 40180636797](https://github.com/shomoD9/mind-machine/actions/runs/40180636797)), [measurement only](measurement-only.json) at `3ace8b5` ([run 40183421967](https://github.com/shomoD9/mind-machine/actions/runs/40183421967)), and [production after](after.json) at `f01a1ef` ([run 40186348032, attempt 2](https://github.com/shomoD9/mind-machine/actions/runs/40186348032/attempts/2)). All three recorded reports pass every self-test check. Samples contain no personal vault content.

All use the existing Debug shared macOS 26 runner profile, 20 warm opens and 100 keys per fixture, forced animation. Open starts before the production hotkey handler and ends at visible, key, focused first-input acceptance and drawing. Typing starts at window event dispatch and ends at draw completion. OS hotkey delivery, input queuing, compositor and physical display latency remain outside these intervals. See [boundaries and Release rerun](../markdown-editor-baseline.md).

| p95 milliseconds | Before | Measurement only | After |
| --- | ---: | ---: | ---: |
| Warm open to input | 74.368 | 37.996 | 42.298 |
| 1 KiB key to draw | 9.677 | 2.770 | 3.715 |
| 10 KiB key to draw | 4.354 | 1.681 | 4.149 |
| 100 KiB key to draw | 8.758 | 1.890 | 9.020 |
| 100 KiB one paragraph key to draw | 71.433 | 44.535 | 72.679 |

These whole-flow differences do **not** establish an end-to-end speedup. The unchanged measurement-only checkpoint was faster, showing substantial host variation. The after run retains all source/input/TextKit checks, including the 1 MiB insertion. The 100 KiB single paragraph remains above the proposed 33 ms draw-proxy budget.

The baseline's huge-paragraph styling p95 is 0.553 ms versus 71.397 ms dispatch. Stock/Capture editor controls also spend tens of milliseconds on native insertion/layout. Changing layout, animation or native editing is not justified within this performance-only ticket. Synchronous show-request p95 is 5.454 ms in the measurement checkpoint and 5.482 ms after, versus 37.996/42.298 ms to visible input. No show behavior changed; the empty synthetic vault does not establish populated-vault database costs.

The byte-exact binding comparison is the only production change. The adapter now materialises contiguous UTF-8 and uses a bulk byte comparison rather than Debug generic byte iteration. Canonically equivalent but byte-distinct source still restores; native selection, undo and marked text retain their existing paths. In the same-process native-string microbenchmark at `f01a1ef`, 100 KiB comparison p95 was 6.069 ms generic versus 0.003 ms contiguous. Full editor insertion medians with old/new binding echoes were 50.71/46.17 ms in pass 1 and 47.15/46.87 ms in pass 2: a mixed result, not evidence of an instant huge-paragraph editor. Final instrumentation also compares strings read from actual text storage, including that read in both variants; see the final PR check logs for `MM_BYTES_BENCH representation=textStorage`. The isolated benchmark uses warmed, sequential variants and is supporting evidence, not physical typing latency.

The first `f01a1ef` Mac self-test failed `all 20 cycles completed` (19 expansions, 20 collapses), while all open/typing checks passed. An unchanged job rerun completed all 20 cycles and every assertion; the earlier failure remains visible in attempt 1. No animation assertions, counts, budgets or deadlines were changed. Both Swift jobs failed only because the new selection fixture requested UTF-16 `{7,2}`, spanning a space and part of a decomposed accent; AppKit correctly expanded it to `{7,3}`. The final correction selects the complete accent at `{8,2}` and keeps exact selection/source assertions. Existing tests remain intact.

Reproduce on a Mac with `swift test --package-path native --filter CaptureTypingCostTests` and the existing sandbox self-test/Release rerun linked above. Hosted final-commit compilation and all acceptance checks are tracked on [PR #14](https://github.com/shomoD9/mind-machine/pull/14); final results are also written to `/tmp/mm-speed-result.md`. Release physical-Mac, OS hotkey delivery and screen-visible latency remain unmeasured.
