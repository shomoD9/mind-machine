# Overnight core work

Status: resolved
Blocked by: none; founder authorizes unattended implementation and macOS CI.

1. Four TLC regressions red then green; fold equivalent heads without losing their ancestry, branch-local deletes, preserve unseen edits, defer incomplete revision chains.
2. Backend access/save guards, keyboard sync status, safe retry path; Copy/Mac Insert follow up.
3. Measure Release performance before/after; optimize only measured paths and set evidenced budgets.
4. One deterministic checks script and one-page gate documentation; macOS CI proof, focused commits and PR.

UI views/visuals, TestFlight signing, live Apple provisioning and real-device acceptance remain outside this branch. Historical tickets 10–17 retain any unmet acceptance criteria.

Evidence: unified macOS gates [40055609213](https://github.com/shomoD9/mind-machine/actions/runs/40055609213) and native/sandbox CI [40055611973](https://github.com/shomoD9/mind-machine/actions/runs/40055611973) passed. Six sync stories include the four red-before-green bugs, 151-revision batches and incomplete deletes. Performance and scope are in docs/verification/overnight-perf.md. PR: https://github.com/shomoD9/mind-machine/pull/3.

Follow-ups: Note Copy/Mac Insert, stable conflict-copy IDs (M11), first-download progress, loaded-keyboard reinitialization after enabling Full Access, signed CloudKit recovery and actual iPhone footprint/activation. Upgrade all synced clients together because old clients use global tombstones. Full four-revision exploration remains the extended gate; the deterministic push gate proves the stated three-revision model and real-code regressions, not all transport behavior.
