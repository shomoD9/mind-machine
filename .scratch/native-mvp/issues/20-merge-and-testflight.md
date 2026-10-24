# 20: Merge backend and keyboard, then verify TestFlight processing

Status: claimed
Blocked by: process 207171 must exit before keyboard-ui integration; Apple signing/processing must pass

Founder authorized merging PR #3 then PR #4, resolving backend/UI conflicts, fixing real CI/release failures and shipping without PR review.

- [x] Merge green backend PR #3 first.
- [ ] Wait for keyboard process exit and recheck PR #4 head/checks.
- [ ] Integrate new main while keeping keyboard copy/visuals and backend behavior; native/core/UI checks green.
- [ ] Merge PR #4 and verify main CI.
- [ ] Dispatch TestFlight on main and read VALID for both platform builds.
- [ ] Write /tmp/mm-merge-result.md with evidence, device checklist and remaining blockers.

## Comments

- 2026-10-24, GPT-6 / Codex API: Backend merged at 1a1ac09. Added workflow processing verification because upload success alone cannot establish the requested App Store state. Existing workflow triggers may automatically upload intermediate main commits; the final explicit dispatch will identify the combined release build.
