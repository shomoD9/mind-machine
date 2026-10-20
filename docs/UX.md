# Capture, search, resurfacing, and continuing chat

Save a thought when it arrives. Find material while using another app. Encounter selected material during existing browsing. Continue a chat without rebuilding its context.

Working UX draft, 20 October 2026, after round nine; MVP design is authorized. A whole-checklist due date also schedules its reminder; individual-item due dates are excluded. A date-only choice uses a visible, configurable default time that can be changed before scheduling. Completing every checklist item cancels its pending reminder; any unfinished item keeps it scheduled. After the due reminder, unfinished lists remain overdue in Open tasks. Further timed alerts require explicit rescheduling; Q33 excludes a separate snooze control. Resurfacing uses captured material only, with selection priorities deferred. Details labeled **proposed** remain open. The [PRD](PRD.md) records requirements; the [decision ticket](../.scratch/scattered-ambitious-pitch/issues/20-headless-second-brain.md) tracks unresolved choices. The current [editable FigCraft design](design/native-mvp.figcraft) starts with keyboard flows. The HTML preview is superseded. Designs use fictional state; the connected app has not been launched.

## Primary interaction

The keyboard is the primary iPhone workspace. Capture opens by default with a notepad above the keys inside the extension; Find, original inspection, Chat and reminder controls remain in that workspace. The companion app is secondary for setup, settings, recovery and entry points the keyboard cannot support.

Minimised, Default and Expanded sizes preserve the same draft and cursor. Minimised retains a single visible note line and continues typing into the note; it does not redirect input to the host app. Expanded requests more extension height, with exact device limits to be tested. Mac uses a resizable hotkey panel with a fullscreen option; true iPhone fullscreen remains unverified. See [roadmap and feasibility](ROADMAP.md).

## Surface responsibilities

| Surface | What the person does or encounters |
| --- | --- |
| Secondary iPhone keyboard | Capture, Find, or Chat while a supported text field is open; insert a chosen result deliberately. |
| Mac hotkey surface | Capture or search, then return to the active app. |
| Share sheet / companion | Save links, images, voice, and other supported material that need these entry points. |
| Continuing chat | Talk, explore, and retrieve; ordinary conversation remains in history automatically. |
| Enabled browser feeds | Encounter material among an existing browsing flow. Site-specific support is untested. |
| Browser new tab | Encounter material when opening a tab. |
| Permitted WhatsApp/SMS channel | Receive a commitment cue under the chosen deadline and content rules. |

Resurfacing does not occupy the keyboard. Its three work modes are Capture, Find, and Chat, with Capture opening by default.

## 1. Capture a mixed thought

The capture is a lightweight rich-text document with visual Markdown-style controls, bullets, explicit checkboxes, links, and media. It supports an essay as well as a short action sentence. The keyboard is the primary writing surface, with Minimised, Default and Expanded note viewports. The minimised pad continues receiving note input and keeps the host draft unchanged. The same draft/cursor survives resizing; true iPhone fullscreen needs feasibility testing.

The person is replying in another app and thinks of a reflection, a task, and a useful link. They switch to the secondary keyboard, which opens Capture by default, and enter the mixed text. They save without choosing a category. The original remains together; background organization can help retrieve its parts later. The Mac hotkey also opens Capture; a single toggle reaches Find, preserving drafts in both modes.

```text
Existing app                  Secondary keyboard
--------------------------    ---------------------------
Host draft remains intact     Capture | Find | Chat
                              [private input buffer]
                              Save
                              Saved on this device
                              Switch back to usual keyboard
```

**Proposed details:** queries and capture drafts stay out of the host message; Save confirms durable local storage; sync and processing have separate status. A possible reminder is offered after saving, without blocking the capture. Its exact presentation is still open. Photo/voice capture uses the share or companion flow appropriate to the medium.

### Captured checklists

The human chose interactive to-do lists linked to their original capture. A checkbox changes completion state while the source remains accessible. Capture alone creates no timed reminder.

```text
Original capture
  Things for the trip:
  book train / pack charger / send itinerary
             |
Linked interactive checklist
  [ ] Book train
  [x] Pack charger
  [ ] Send itinerary
```

The rich-text editor lets the person deliberately create bullets and checkbox lists. A saved action sentence can get a soft reminder offer with date/time selectors. Open tasks in Find and Chat retrieves unfinished items; this app owns reminders. A checklist has one due date for the whole list, and choosing it also schedules the reminder. A date-only choice uses a visible, configurable default time that can be changed before scheduling. Completing every checklist item cancels its pending reminder; any unfinished item keeps it scheduled. After the due reminder, unfinished lists remain overdue in Open tasks. Further timed alerts require explicit rescheduling; Q33 excludes a separate snooze control. Calendar timeboxing is a later integration direction.

```text
Save checklist → Saved, no reminder
                      |
            Set whole-list date + visible time
                      |
              Reminder scheduled
                 /       \
     All items complete      Due time; unfinished items
            |                         |
     Cancel pending alert       Deliver reminder
                                      |
                             Open tasks: overdue
                                      |
                       Edit date/time explicitly
                                      |
                              Next timed alert
```

Reopening a completed list offers a new reminder. Its cancelled reminder is not restored. Reminder controls are Edit and Remove, with rescheduling also available through Chat; no separate Snooze control. Existing reminders keep their original time zone and instant.

## 2. Find and reuse a prior thought

While composing, the person switches to Find or invokes the Mac hotkey. They type “the thought about maintaining a second brain.” Results show recognizable originals, with date and source. They inspect a match and choose Insert, Copy, or Open. Their unfinished host draft remains available.

**Proposed details:** matches can come from captures or conversation history. A chat result identifies the speaker and surrounding exchange. A result from an image or voice transcription retains access to that original. Search wording can be approximate; an exact remembered phrase also works.

## 3. Encounter an idea in a browser feed

The person scrolls X in a supported browser with the integration enabled. An app-authored item introduces something they previously thought about. It belongs in the scrolling experience; opening a separate review page is unnecessary.

Selection uses the person's captured material, including retained ordinary chat; it does not use the current page/topic or retain browsing history. Recognizing the enabled surface to place the cue does not authorize analyzing the consumed content for relevance. The human explicitly deferred which captured items should be preferred; no ranking strategy is selected here.

```text
X website                     YouTube Shorts website
--------------------------    ---------------------------
Normal feed item              Normal Short
Normal feed item              Returned bookmark encounter
From your saved material      Normal Short
  [eligible thought]          Continue existing browsing
  Open / use / dismiss
Normal feed item
```

The human requested a saved bookmark or useful item during Shorts. Whether that encounter is a text/thumbnail stop, another layout, or a richer representation remains to design. Automatic generation of a new video was not requested or decided.

**Confirmed:** one item appears per encounter, and it may return later. A thought opens its original in a private reading view with Continue in chat available; a bookmark opens its saved destination. Scrolling past leaves the item eligible; an explicit Stop showing this excludes it while preserving the original. Eligible ideas/bookmarks can appear; private details remain in the vault. **Proposed details:** origin is recognizable as the person's vault; viewing a thought does not publish an X post or upload a Short. Eligibility is automatic, with private or uncertain material kept private. Exact placement remains open. Website integration and permissions must be tested. The page may gain access to plaintext inserted into its shared document; an app-owned isolated surface may have a different exposure boundary. The presentation has not been selected.

## 4. Encounter an idea in a new tab

Opening a browser tab already creates an uncommitted moment. The enabled new-tab surface places a returned thought or bookmark there. The person can use it or continue to their original destination.

```text
New tab
+------------------------------------------------+
| Search or enter a destination                  |
|                                                |
| [returned material]                            |
| Source / open / use / dismiss                   |
|                                                |
+------------------------------------------------+
```

**Confirmed:** the person encounters a single item without choosing between alternatives; repeats are allowed. Passing leaves eligibility intact; Stop showing this excludes it. **Proposed details:** usual navigation remains immediate. Users who already rely on another new-tab extension need a deliberate choice during setup; existing settings are not replaced silently.

## 5. Notice an approaching commitment

A capture says “application closes Friday.” It is saved immediately. The person can accept the offered reminder. At the agreed time, a permitted channel delivers a cue.

```text
Save original → Offer reminder → Accept / decline
                                      |
                                  If accepted
                                      |
                             Confirm time and channel
                                      |
                           Due cue → open vault details
```

**Confirmed:** timed messages require an accepted reminder. Declining the offered reminder does not authorize a later timed deadline message. Private details stay in the vault; a neutral private-deadline cue opens them there. The one-item rule does not prohibit repeats or create a once-ever delivery guarantee. The due reminder also appears in the continuing chat. The person can edit or remove it, including asking Chat to reschedule it; no separate Snooze control is included. Reminders retain their original time zone. Reopening a completed checklist offers a new reminder. Delivery and failure/retry behavior need validation.

WhatsApp/SMS are distinct delivery channels with their own permission and content handling. A message service accepting a cue, delivering it, and the person reading it are different outcomes. A neutral message opening vault details is a proposed privacy option. Templates, opt-outs, and delivery failures belong in the design; no live message has been sent.

## 6. Continue the same chat

The person returns after a week: “What did I decide about the keyboard?” The chat can draw on the earlier exchange and the wider captures. They continue discussing another topic in the same conversation. No save-passage question appears.

```text
One continuing conversation
  User message ── retained with context ─┐
  Assistant reply ─ retained as reply ──┤
  Later correction ─ retained ──────────┤
                                        v
                  Shared retrieval over history + captures
                                        |
                  Answer with inspectable source exchanges
```

**Confirmed:** history persists by default and can participate in the corpus. **Proposed refinement:** summaries help navigate; original exchanges stay available. “I am considering Pune” retains its uncertainty. A quoted passage retains its author. “I decided to stay” can supersede an earlier plan for current answers while historical questions can recover the earlier discussion. An assistant's interpretation is attributable to the assistant.

**Confirmed forgetting behavior:** selecting Forget this removes the original exchange and its derived memory across synced devices. It must no longer return in history, search, answers, or resurfacing. Previously shared copies have a separate deletion boundary. Recovery, offline-device handling, and the exact deletion control remain to design.

### Chat inside the keyboard

Chat is an additional keyboard mode. **Proposed compact layout:** recent turns in a scrollable region, a private message composer, and a clearly visible Temporary state. Send addresses the assistant; a separate explicit Insert action can put chosen text into the host app.

```text
Host draft stays intact
+--------------------------------------+
| Capture | Find | [Chat]               |
| Continuing chat     Temporary: off    |
| Recent user / assistant turns        |
| [scrollable conversation area]       |
| [message composer]             Send  |
| Insert selected text / switch mode   |
+--------------------------------------+
```

The mode is confirmed; this layout is proposed. The keyboard has a bounded viewport and platform duties. An independently opened companion may show the same conversation; no direct keyboard-to-app launch is promised. [Platform follow-up](../.scratch/scattered-ambitious-pitch/research/17-platform-feasibility-2026-10-19.md) distinguishes documented custom UI capabilities from untested Chat composition and review outcomes.

### Temporary conversation

The person can explicitly enable Temporary for a conversation segment. Its messages and derived memory stay out of retained vault history. Ordinary chat remains saved by default. The state must be apparent while composing. Temporary can read relevant saved material without retaining new segment messages or derived memory. Ending the segment and returning to retained conversation still need a concrete lifecycle. External provider retention remains separate.

[UniiChat research](../.scratch/scattered-ambitious-pitch/research/22-uniichat-identity-and-memory-2026-10-20.md) verifies the relevant reference and its limits. Its memory approach is not yet selected as this app's architecture. Detailed keyboard layout, Mac chat placement, Temporary lifecycle, and imports from other chat apps remain open.

## 7. Confirmed iPhone browsing journey

The human chose browser feeds plus new-tab/messages. Ordinary apps cannot insert content into native X or YouTube feeds under the reviewed iPhone platform contract; native feed insertion is outside the first-release promise. The keyboard does not act as a scrolling overlay.

| Situation | Selected experience | Remaining validation |
| --- | --- | --- |
| Scrolling X in a supported phone browser | Enabled website integration introduces one eligible item. | Safari extension direction is documented; actual X placement, visibility, permissions, and return flow need a pilot. |
| Watching Shorts in a supported phone browser | Enabled website integration introduces one eligible bookmark/item. | Actual page navigation, fullscreen behavior, and encounter presentation need testing. |
| Opening a new tab | A supported browser's enabled new-tab surface shows one item. | Setup and compatibility with the person's existing new-tab habit need testing. |
| Accepted reminder becomes due | A chosen permitted message channel delivers a neutral private cue. | Channel setup, scheduling status, delivery and failure handling remain to design. |

This choice introduces a browsing-habit and extension-setup cost. It does not authorize monitoring other native apps or establish automatic idle detection. Those are separate questions if later proposed.

## Decisions needed before detailed screens

Q13 is settled: assess idea/bookmark eligibility automatically and keep private or uncertain material private. The person does not approve an excerpt before resurfacing. This is a product policy to test, rather than a claim that automatic sensitivity judgment is infallible.

Q18 selection priorities are explicitly deferred. Q19–Q22 are answered: captured-material context only, interactive checklists, Chat as a keyboard mode, and Temporary segments. Round six settled the rich-editor/post-save-offer model, Open tasks in Find and Chat, app-owned reminders, and Temporary read access with no new retained content. Q27–Q28 set whole-checklist dates that also schedule reminders. Q29–Q31 confirm a visible default alert time, cancellation on whole-list completion, and overdue retention with repeats only by choice. Q32–Q35 add reminder events in chat with conversational rescheduling, optional WhatsApp/SMS, Edit/Remove controls, original time zones, and a new reminder offer on reopening. Detailed interviewing is paused for MVP design; see [launch design](MVP.md). Reminder channels/failure, keyboard layout, cadence, media capture, external imports, sync conflicts, and recovery remain visible branches. Pending recommendations are not acceptance criteria.
