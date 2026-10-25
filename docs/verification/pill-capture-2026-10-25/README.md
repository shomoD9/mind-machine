# Pill Capture window redesign — 25 October 2026

Ticket 24, PR #10. All images come from CI artifacts, not local renders. The Mac images are `PillSelfTest` `cacheDisplay` snapshots (`pill-selftest` artifact). The iPhone images come from `Scripts/simulator_screenshots.sh` (`simulator-screenshots` artifact).

| View | Before (main `898952f`, native-ci [40104384896](https://github.com/shomoD9/mind-machine/actions/runs/40104384896)) | After (PR head `5a2531f`, native-ci [40125756997](https://github.com/shomoD9/mind-machine/actions/runs/40125756997)) |
| --- | --- | --- |
| Mac Capture, typed note | `before-capture.png` | `after-capture.png` |
| Mac Recall, query "hello" | `before-recall.png` | `after-recall.png` |
| Mac collapsed pill | `before-collapsed.png` | `after-collapsed.png` |
| iPhone companion vault, light | `before-iphone-vault-light.png` | `after-iphone-vault-light.png` (also `after-iphone-vault-dark.png`) |

`after-capture-empty.png` shows the empty page: the caret sits at the first letter of the faint prompt and the disabled Save is dimmed. It comes from native-ci [40128785762](https://github.com/shomoD9/mind-machine/actions/runs/40128785762) at `4315b4c`, after this PR added the snapshot. That run also passed 51/51 checks, with expand median 220.13 ms, collapse median 175.81 ms and Reduce Motion expand 10.41 ms.

## Self-test measurements on the same runner type

| | main `898952f` | PR `5a2531f` |
| --- | --- | --- |
| Checks | 49/51 (failed: expand median < 250 ms, Reduce Motion expands instantly) | 51/51 |
| Expand median / max | 270.49 / 591.32 ms | 203.67 / 574.25 ms |
| Collapse median | 206.65 ms | 169.72 ms |
| Reduce Motion expand | 95.08 ms | 14.08 ms |
| First expand | 277.04 ms | 313.45 ms |
| Idle CPU / resident | 0.07 % / 98 MB | 0.07 % / 95 MB |

These come from two runs on shared GitHub VMs. One pair of runs cannot show that the redesign made the panel faster. It fits with replacing the live behind-window blur by a flat fill that is not redrawn during the resize, but runner variance could also explain it. First expand was slower in this run.

## Not covered

Hover tooltips, the sync setup sheet opened from the new glyph, the "attention" sync state with a real CloudKit error, the reminder offer row and a populated Recall list were not captured. The XCUITest journey opens a real Recall result but keeps only failure screenshots. Dark appearance of the Mac panel was not captured; the runner uses light appearance.
