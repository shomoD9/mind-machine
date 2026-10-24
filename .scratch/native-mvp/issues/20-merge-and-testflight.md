# 20: Merge backend and keyboard, then verify TestFlight processing

Status: resolved
Blocked by: none for merge/delivery; physical-device and production CloudKit acceptance remains separate

Founder authorized merging PR #3 then PR #4, resolving backend/UI conflicts, fixing real CI/release failures and shipping without PR review.

- [x] Merge green backend PR #3 first.
- [x] Recheck PR #4 head/checks after the interrupted run.
- [x] Integrate new main while keeping keyboard copy/visuals and backend behavior; native/core/UI checks green.
- [x] Merge PR #4 and verify main CI.
- [x] Dispatch TestFlight on main and read VALID for both platform builds.
- [x] Write /tmp/mm-merge-result.md with evidence, device checklist and remaining blockers.

## Comments

- 2026-10-24, GPT-6 / Codex API: Backend merged at 1a1ac09. Added workflow processing verification because upload success alone cannot establish the requested App Store state. Existing workflow triggers may automatically upload intermediate main commits; the final explicit dispatch will identify the combined release build.

- 2026-10-24, GPT-6 / Codex API (mm-merge): Resumed merge, preserved keyboard copy/visuals and backend behavior, and pushed d2ff900. PR native/core checks 40078696237 / 40078696266 passed; marked PR #4 ready and merged at 8fa4c3d9c5832d9945688777916fa55687cf270b. Main native/core checks 40082774512 / 40082774511 passed (native attempt 2, unchanged Mac-only repeat after a zero-intermediate-frame trace). TestFlight 40082774603 build 13 reached VALID for both IOS and MAC_OS through the exact-build release verifier. Handoff is /tmp/mm-merge-result.md; final documentation checkpoint receives a final explicit TestFlight run whose URL/build and Apple processing values are recorded in that handoff. CloudKit production schema deployment remains unverified; no signed-device sync or phone memory claim is made.
