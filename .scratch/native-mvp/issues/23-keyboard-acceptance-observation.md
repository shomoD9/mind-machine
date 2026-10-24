# 23: Repair keyboard acceptance accessibility observation

Status: claimed
Blocked by: none

Finish PR #9’s CI after the keyboard-feel handoff. Fix the real product or test cause; preserve all journeys, Apple keyboard feel, greyscale dithered UI, copy and the absence of Next keyboard. Do not modify PRODUCT, workflows, signing, entitlements or the release pipeline, and do not merge.

- [x] Identify the failure from the actual log and result bundle.
- [x] Fix the incorrect observation seam without relaxing expected values or retrying input.
- [ ] Verify all jobs at the final pushed head, using at most three rounds of up to 60 minutes.
- [ ] Record root cause, changes, per-job status and head SHA in `/tmp/mm-kbfix-result.md`.

## Comments

- 2026-10-24, GPT-6 / Codex API (mm-kbfeel): run 40110448639 canceled a 30-second AX query at its enclosing five-second predicate deadline. The failure screenshot/tree and later diagnostic show an empty Recall query. Replaced shared keyboard text assertions with completed synchronous snapshots, retained exact equality/five-second settling and added exact checks after each delete. Xcode is unavailable locally; CI is the real simulator loop. Ticket 22’s physical-device acceptance remains separate.
