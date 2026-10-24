# 23: Repair keyboard acceptance accessibility observation

Status: resolved
Blocked by: none

Finish PR #9’s CI after the keyboard-feel handoff. Fix the real product or test cause; preserve all journeys, Apple keyboard feel, greyscale dithered UI, copy and the absence of Next keyboard. Do not modify PRODUCT, workflows, signing, entitlements or the release pipeline, and do not merge.

- [x] Identify the failure from the actual log and result bundle.
- [x] Fix the incorrect observation seam without relaxing expected values or retrying input.
- [x] Verify the correction with all jobs green at `8a245a5`; watch the documentation checkpoint separately before handoff (at most three rounds of up to 60 minutes).
- [x] Record root cause and changes here and in the audit; `/tmp/mm-kbfix-result.md` receives the final checkpoint’s per-job status and head SHA before handoff.

## Comments

- 2026-10-24, GPT-6 / Codex API (mm-kbfeel): run 40110448639 canceled a 30-second AX query at its enclosing five-second predicate deadline. The failure screenshot/tree and later diagnostic show an empty Recall query. Replaced shared keyboard text assertions with completed synchronous snapshots, retained exact equality/five-second settling and added exact checks after each delete. Xcode is unavailable locally; CI is the real simulator loop. Ticket 22’s physical-device acceptance remains separate.

- 2026-10-24, GPT-6 / Codex API (mm-kbfeel), continuation: run 40113103269 fails twice on nil versus empty immediately after Save and after host delete-repeat, with eleven other journeys passing. The expected TextView exists; its AX value read completes in 7 ms with an empty dictionary and no error. The screenshot/tree confirm empty text. Corrected the observation helper to map nil to empty only for a successful TextView snapshot, preserving all missing-element/error/type/text failures, and added an initial-empty check. Hosted verification pending; the earlier blanket requirement that nil fail was an incorrect test assumption.

- 2026-10-25, GPT-6 / Codex API (mm-kbfeel): correction 8a245a5 passed native-ci 40119415188 (all five jobs), core-checks 40119415192 and both push/PR fast-core runs. Downloaded the actual xcresult: 13 Success, 0 Failure, 0 Skipped. Reviewed the diff: only TextView nil representation is normalized after successful resolution, all expected text and gestures remain, errors still fail, and the initial empty editor is now checked. Resolved this CI-observation ticket; physical-device work in ticket 22 remains separate. Watching the documentation checkpoint before final reporting.
