# Capture speed

Ticket 27 measures only Mac Capture performance. Baseline: latest main `61eca6a`, [native-ci 40180636797](https://github.com/shomoD9/mind-machine/actions/runs/40180636797). The downloaded `pill-selftest/result.json` passed every check; [baseline.json](baseline.json) retains its synthetic raw timing samples. Nothing here contains vault content from a person.

Both comparisons use the existing Debug shared macOS 26 runner profile, 20 warm opens and 100 keys per fixture, forced animation. Open starts before the production hotkey handler and ends at visible, key, focused first-input acceptance and drawing. Typing starts at window event dispatch and ends at draw completion. OS hotkey delivery, input queuing, compositor and physical display latency remain outside these intervals. See [boundaries and Release rerun](../markdown-editor-baseline.md).

| p95 milliseconds | Before | After |
| --- | ---: | ---: |
| Warm open to input | 74.368 | Pending |
| 1 KiB key to draw | 9.677 | Pending |
| 10 KiB key to draw | 4.354 | Pending |
| 100 KiB key to draw | 8.758 | Pending |
| 100 KiB one paragraph key to draw | 71.433 | Pending |

The baseline's huge-paragraph styling p95 is 0.553 ms versus 71.397 ms dispatch. Native layout dominates that dispatch. The existing stock/Capture benchmark adds 8–11 ms when it simulates the adapter's byte-exact binding echo. First measurement push adds a contiguous-byte comparison candidate to that benchmark (without adopting it in production), a direct generic-versus-contiguous comparison and synchronous show-request timings. This distinguishes application overhead from native layout/animation before choosing changes. Timings remain observations; no budgets, assertions, sample counts or deadlines are relaxed.
