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

## Verification status

Mac checklist/reminder controls and companion/keyboard reminder inspection were exercised after unlock. Both device notification permissions are enabled under explicit human approval. Simulator background delivery is verified below; Mac visual delivery remains open because the computer-use service failed. Real-phone verification remains a release gate. This checkpoint does not complete remembered inference, encrypted sync, media or release verification.

Initial reviews found scroll clipping for long lists, stale offers after completion, and notification delegate ownership/lifetime. Fixed each: controls/settings scroll, offers validate against saved state, and only app entry points install a process-lifetime foreground presenter. Added save-state disabling and original-reader restoration during date editing. Follow-up reviews are clear and rebuilt native artifacts succeeded. The earlier locked-Mac block was cleared by the human; subsequent native evidence is recorded below.

## Native checks after unlock

- Mac: saved a test checklist through the visual editor, accepted the optional reminder, found it through Open tasks, edited its date while retaining Asia/Kolkata, completed it (no pending reminder), reopened it (new offer, no automatic schedule), accepted a fresh reminder and removed it while preserving the original.
- iPhone simulator: installed b02142d, captured an action, accepted and edited its reminder through the companion, enabled notifications with explicit human approval, and observed one pending OS request. The due occurrence appeared in keyboard Chat with Open reminder source, the original showed Overdue, and the pending OS count became zero. This alone does not prove visual notification delivery.
- Keyboard: directly opened Find and the original, inspected the accepted date/zone in Expanded, opened the in-extension date wheels, cancelled and verified the original reader returned. Custom controls remain absent from AX; visible coordinate actions worked this time.
- Mac OS notification enablement failed with UNErrorDomain code 1, then “Notifications are not allowed for this application” after ad-hoc signing the app bundle and relaunching. At that stage System Settings did not list the app under Application Notifications. The installed-bundle follow-up below resolved authorization. No permission reset or unrelated setting changes were performed.
- Human approved notification permission on Mac and simulator. Simulator permission succeeded immediately; Mac permission succeeded after installing the signed bundle and enabling its app-specific system toggle.

### OS delivery evidence

The second explicitly edited simulator occurrence was accepted for 21 October at 21:07 Asia/Kolkata, with one pending OS request shown before backgrounding. At 21:07 the Home screen visibly displayed the OS banner: “A reminder from your vault” / “Open Second brain for the details.” This proves simulator background delivery for that occurrence, independently of Chat reconciliation.

Mac installation follow-up: signing and registering the temporary build did not fix authorization. Installing the same signed bundle at `/Users/shomo/Applications/SecondBrainMac.app` made SecondBrainMac appear in System Settings → Notifications. Enabled its app-specific notification switch under the human's approval; the app then reported one pending request for an accepted 21:12 Asia/Kolkata test occurrence. Opening the Mac notification surface then failed with “Sky Computer Use service startup request failed” after a long blocked tool call; actual Mac visual delivery was not observed. This establishes an installation/setup difference; it does not establish that an Apple membership is needed for local Mac notifications.
