# MVP scope

This is a living scope index for [Scattered ambitious pitch](map.md). The MVP is still being defined.

## Scope revision in progress — 2026-10-20

The current [headless second brain PRD](../../docs/PRD.md), [UX journeys](../../docs/UX.md), and [decision ticket 20](issues/20-headless-second-brain.md) record the human's broader whole-day, multimodal vision. Confirmed: iPhone and Mac together in the first release; a secondary capture/search keyboard; private sync with cloud AI opt-in; free local use with monetized sync; save task-like thoughts before offering reminder creation; continuous chat history retained by default; optional browser-feed/new-tab/message resurfacing. Each encounter shows one item, repeats are allowed, private details stay in the vault, and timed messages require accepted reminders. The selected phone experience uses browser feeds plus new-tab/messages. A keyboard resurfacing card, passage-save receipts, and once-per-item suppression were rejected. Thoughts open their private original and bookmarks open their link; passing preserves eligibility while explicit stop excludes; Capture opens first; forgetting removes the original exchange and derived memory. Eligibility is automatic, with private or uncertain material kept private; no per-item excerpt approval. Selection priorities are explicitly deferred. Resurfacing uses captured material only; checklists are interactive and linked to originals; Chat is also a keyboard mode; Temporary segments stay out of retained history/derived memory. Rich-text Markdown-style capture and soft post-save reminder offers supersede automatic-list conversion. Open tasks in Find/Chat, app-owned reminders, and Temporary read access without new retention are settled. A single whole-checklist due date also schedules its reminder; item-level due dates are excluded. A date-only choice uses a visible, configurable default time that can be changed before scheduling. Completing every checklist item cancels its pending reminder; any unfinished item keeps it scheduled. After the due reminder, unfinished lists remain overdue in Open tasks. Further timed alerts require explicit rescheduling; Q33 excludes a separate snooze control. Editing/removal, fixed time zones and new reminder offers on reopening are settled in Q32–Q35; delivery implementation, remaining interactions, imports, and recovery remain open; calendar timeboxing is deferred.

The commitments below preserve the earlier scope. Mac-only, typing-only, and maker/publishing-specific behavior cannot be read as the current release specification. Keep compatible preservation/no-filing commitments; reconcile changed behavior through ticket 20. The release is not locked, and this revision does not close earlier interaction tickets.

## Inclusion rule

The human wants an ambitious MVP limited to product decisions that are fully concrete and settled. Engineering capacity does not constrain ambition in this planning effort. Explicit agreement settles the behavior discussed; it does not settle every detail of a larger feature.

Decision detail stays in the linked tickets. This index distinguishes settled commitments from the choices needed to turn them into a complete first release.

## Settled commitments

| Commitment | Decision source |
| --- | --- |
| One product joins capture and retrieval; the maker does not classify thoughts while capturing. | [One product or a series](issues/05-one-product-or-a-series.md) |
| Preserve separate thoughts and the maker's wording, allowing very minor corrections for legibility. | [What capture must preserve — accepted answers](issues/10-what-capture-must-preserve.md#comments) |
| Keep inferred connections revisable and retain a source or draft reference when available. | [What capture must preserve — accepted answers](issues/10-what-capture-must-preserve.md#comments) |
| Allow an adjacent writing space for a new thought while another stays unfinished. | [What capture must preserve — accepted answers](issues/10-what-capture-must-preserve.md#comments) |
| Related notes during capture are optional and easy to ignore. | [What capture must preserve — accepted answers](issues/10-what-capture-must-preserve.md#comments) |
| A simple capture overlay blurs and darkens the background; a shortcut opens and dismisses it. | [What capture must preserve — accepted answers](issues/10-what-capture-must-preserve.md#comments) |
| Wikilinks are a first-class interaction: a simple hotkey creates a new dialog linked from a selected word or phrase in the current dialog. | [What capture must preserve — accepted answers](issues/10-what-capture-must-preserve.md#comments) |
| A wikilink creates an independent note that can be retrieved and acted on by itself, and keeps the selected phrase as its source reference. | [What capture must preserve — accepted answers](issues/10-what-capture-must-preserve.md#comments) |
| A multi-thought block gets a split hint. The hint is optional and ignorable, and accepting or adjusting it is Explode. | [What capture must preserve — accepted answers](issues/10-what-capture-must-preserve.md#comments) |
| A point-of-decision card shows a backend chunk of a multi-thought block. The split hint shows the maker the proposed boundary so they can see and fix it. | [What capture must preserve — accepted answers](issues/10-what-capture-must-preserve.md#comments) |
| Capture is typing only. The product has no speech-to-text. The maker can still dictate into it using their own tool, such as Wispr. | [What capture must preserve — accepted answers](issues/10-what-capture-must-preserve.md#comments) |
| Bring a dumped note into an app the maker already has open; one click takes it to the chosen destination. There is no separate home they must remember to open. | [Form of the creation session](issues/11-form-of-the-creation-session.md) |
| Rare label corrections do not gate the point of decision. | [Form of the creation session](issues/11-form-of-the-creation-session.md) |
| In any Mac text box, a related note appears beside the cursor. It is quiet while typing, appears on a pause or a hotkey, and shows one card at most. Clicking inserts the note's text at the cursor; a secondary control opens it as a dialog. | Grilling 2026-10-02, recorded in [Vision capture](../../docs/VISION-CAPTURE-2026-10-01.md) |
| Notes tagged private are never prompted and never leave the device. | Grilling 2026-10-02 |
| The product never displays audience reaction. It reads whether a piece shipped. | Grilling 2026-10-02 |
| A daily canvas (earlier days, notes in the background, a central agent-written note) is a browsing view and is never required. Its central note is a mirror of the day. | Grilling 2026-10-02 |
| The MVP runs on the Mac only. | Grilling 2026-10-02 |
| First surfaces: prompts in the X timeline, and Substack as the publishing target. GitHub and code come after. | Grilling 2026-10-02 |

## Product vision beyond the MVP

- **Native speech capture**: the product turns speech into text itself. Later, and only if the point of decision follows the maker's cursor.
- **Explode as a standalone hotkey**: divides a large captured text block into atomic notes by meaning on demand. Explode is in the MVP only as accepting or adjusting the split hint. See [What capture must preserve](issues/10-what-capture-must-preserve.md#comments).

## Boundaries still being settled

- Capture: exact key combinations and visual styling belong to the rough interface.
- Retrieval: the apps, cues, destinations, and amount of draft content remain open. See [Last pass on passive cues](issues/13-last-pass-on-passive-cues.md) and [Day in the life and rough interface](issues/07-day-and-rough-interface.md).
- The map still carries questions about cross-surface capture, first use, empty days, and return after abandonment. Determine which are required for a complete MVP as these choices become concrete.
- Pricing is set in [Which price band](issues/12-which-price-band.md): utility band, free bring-your-own-key tier, paid sync and managed AI, notes on the device by default. The exact price is open. Sync and managed AI are business-tier commitments, not yet a specified MVP feature.

[Lock the pitch](issues/08-lock-the-pitch.md) will confirm the vision and complete MVP scope with the human. Until then, this index records commitments without claiming the release is fully specified.


**20 October launch direction:** Q32–Q35 add linked due reminders in the continuing chat, conversational rescheduling, optional WhatsApp/SMS, Edit/Remove controls without a separate Snooze control, original time zones, and a new reminder offer when reopening. The human authorized MVP design and a launch attempt today. Detailed interviewing is paused; the human agreed to a private native pilot with sync and rejected browser fallback. See [MVP launch design](../../docs/MVP.md).


**Keyboard-first clarification:** the notepad, Find, original reading and Chat live in the keyboard as the primary phone workspace. Companion/setup screens are secondary. Minimised/Default/Expanded preserve note and caret; minimising alone preserves note input, while explicit host-field selection can change the destination. iPhone fullscreen is unverified; Mac window resizing/fullscreen is planned. Preferred-keyboard inheritance is a future investigation. See [experience roadmap](../../docs/ROADMAP.md).


**Host layout/focus correction:** the example composer follows the entire keyboard workspace and stays visible as its conversation area shrinks. Tap-host versus tap-note selects the desired typing destination; resizing alone preserves focus and both drafts. Native unchanged-caret detection and host-specific layout are unverified. The explicit destination selector is a fallback proposal.
