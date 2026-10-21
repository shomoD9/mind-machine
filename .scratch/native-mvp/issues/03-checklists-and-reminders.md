# 03 — Capture a checklist, accept a reminder, and change it

Status: claimed
Blocked by: 01, 02
Spec: [Native MVP](../spec.md)
Review baseline: c319917

## Acceptance criteria

- [ ] Explicit checklists remain interactive and appear in Open tasks. A post-save action/checklist reminder offer is optional and non-blocking.
- [ ] Choosing the whole-list due date schedules a reminder with a visible editable default time and time zone. App owns schedule/completion; controls are Edit and Remove.
- [ ] System notifications and app-authored due Chat events use the accepted schedule. Distinguish disabled/failed notification delivery from saved commitment.
- [ ] All items complete cancels pending reminders. Reopening offers a new reminder. Unfinished overdue work stays open without automatic repeated alerts.
- [ ] Edits preserve original zone unless deliberately changed. Removing a reminder preserves the source. Verify persistence and actual notification scheduling separately.

## Verification

The full package suite passes 21 tests with zero failures, including five new failing-first regressions at the approved saved-vault/presentation boundary. Mac, iPhone companion and embedded keyboard builds succeeded. Independent Standards/Spec follow-up reviews against c319917 found no remaining actionable code findings. See [checkpoint evidence](../../../docs/verification/native-reminders-checkpoint.md).

Native checklist/date-form interaction and actual OS notification authorization, pending requests and delivery remain unverified. The Mac is locked and one unlock request is pending. Ticket remains claimed; compilation and domain tests do not satisfy these native acceptance gates.

## Comments

- 2026-10-20: Human approved the eight-ticket breakdown, blockers, test boundaries and baseline. Waiting for the listed blockers.

- 2026-10-21: Ticket 02 resolved after explicit human acceptance of editor behavior and dormant-host-caret limitation. Claimed this unblocked reminder slice using the previously approved saved-vault test boundary; no further cursor QA requested.
