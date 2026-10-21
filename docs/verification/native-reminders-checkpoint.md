# Native checklist/reminder checkpoint — 21 October 2026

Ticket 03 is claimed. Ticket 02 is resolved after the human accepted the editor and dormant-host-caret limitation. No more manual cursor tests are requested.

## Implemented behavior

- Original-linked checklist completion on Mac/companion and keyboard; Open tasks includes incomplete lists, including overdue work.
- Optional non-blocking post-save offers. Latest ordinary notes and completed lists clear prior offers.
- One whole-capture/checklist commitment, date/time and displayed zone; configurable saved default time, initially 09:00. Edits preserve the existing zone. Only Edit and Remove controls are exposed.
- Full completion cancels pending commitments; reopening offers a new date without reviving a cancelled alert. Completed lists reject new scheduling/edits until reopened.
- Due Chat events reconcile once per occurrence and link to the original for reminder management. No automatic repeat alerts or calendar/timeboxing integration.
- Separate device-notification status. Permission is an explicit companion/Mac action; keyboard scheduling never presents permission UI. The adapter reconciles revision-specific pending requests against fresh persisted state, including cancellation/edit races, without claiming actual delivery.

## Test evidence

Five new red→green cycles at the previously approved saved-vault/presentation boundary:

1. A revised accepted date originally produced two persisted reminders; after the change it updates one current commitment.
2. The default-time API was absent; persisted clock preferences now produce the expected future instant in Asia/Kolkata, including the next local day after the clock time passes.
3. A stale offer followed an ordinary note, and a fully checked list received an offer; both now remain saved without that prompt.
4. Completed checklists allowed new/edited reminders and reused cancelled work; they now require reopening and an explicit fresh acceptance.

5. Review found offers surviving local/external completion; a failing public-interface regression now verifies refresh/completion clears them and reopening offers again without scheduling.

The full Swift package suite passes 21 tests with zero failures. Existing domain tests cover completion cancellation, due-event idempotence/overdue state, retained zone on edit, removal preserving source and storage coordination. OS notifications are disabled in saved-vault tests; these do not establish native pending-request or delivery behavior.

Mac, iPhone companion and embedded keyboard builds succeeded with the commands in native/README.md. Independent Standards and Spec follow-up reviews against the approved c319917 baseline reported zero remaining actionable code findings.

## Pending verification

Native layout/action verification and actual notification authorization/scheduling/delivery remain separate steps. No new device permission has been granted and no delivery is claimed. This checkpoint does not complete remembered inference, encrypted sync, media or release verification.

Initial reviews found scroll clipping for long lists, stale offers after completion, and notification delegate ownership/lifetime. Fixed each: controls/settings scroll, offers validate against saved state, and only app entry points install a process-lifetime foreground presenter. Added save-state disabling and original-reader restoration during date editing. Follow-up reviews are clear and rebuilt native artifacts succeeded. The Mac is currently locked; an unlock request is pending, so no new native interaction or notification permission/delivery proof is claimed.
