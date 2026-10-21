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

Record executable evidence and remaining limitations here. Compilation, simulator behavior and real-device proof are separate facts.

## Comments

- 2026-10-20: Human approved the eight-ticket breakdown, blockers, test boundaries and baseline. Waiting for the listed blockers.

- 2026-10-21: Ticket 02 resolved after explicit human acceptance of editor behavior and dormant-host-caret limitation. Claimed this unblocked reminder slice using the previously approved saved-vault test boundary; no further cursor QA requested.
