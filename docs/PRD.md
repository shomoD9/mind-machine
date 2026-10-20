# Headless second brain

Capture without filing. Find material where you need it. Let useful thoughts return during your existing day.

**Status:** research-backed working draft, begun 2026-10-19 and updated 2026-10-20 after round nine; MVP design and launch preparation are authorized. A checklist due date applies to the whole list and also schedules its reminder. There are no individual-item due dates. A date-only choice uses a visible, configurable default time that can be changed before scheduling. Completing every checklist item cancels its pending reminder; any unfinished item keeps it scheduled. After the due reminder, unfinished lists remain overdue in Open tasks. Further timed alerts require explicit rescheduling; Q33 excludes a separate snooze control. The complete vision remains intact; today’s target is a private native pilot with cross-device sync, iPhone keyboard and Mac global hotkey. Browser fallback is rejected.

## 1. Product and problem

A personal vault accepts thoughts, reflections, memories, lists, commitments, links, images, and voice. The person submits something without choosing a folder, title, or category. The system makes it searchable in the background. A secondary iPhone keyboard offers Capture, Find, and Chat; a Mac hotkey brings capture/search into the existing activity. Optional resurfacing returns material in enabled feeds, browser new tabs, and permitted messages. One continuing chat retains its history by default and can draw on the wider corpus; explicit Temporary segments stay out of retained history and derived memory. External LLM connections provide another way to use the vault.

People already save personal information in notes, bookmarks, self-chats, screenshots, and voice messages. Filing and maintaining these collections adds work. Later, people may remember only an approximate concept, person, source, or time. They may also forget that they saved something at all.

The research supports these recurring situations. It does not establish that everyone abandons second brains, or that a new product will retain users. See [research synthesis](RESEARCH-2026-10-19.md) and its source registers.

**Initial user, confirmed:** the founder, across their whole personal and creative day. Broader demand must be tested with people who already struggle with fragmented capture and retrieval. A neurodivergence diagnosis is not a condition of use.

**Differentiation to test:** the complete save → find → reuse journey requires less effort than the person's current self-chat or notes workflow. Automatic tags, AI search, chat, and hotkeys already have competitors; feature presence alone does not establish a reason to switch.

## 2. Jobs to be done

| When… | I want to… | So I can… |
| --- | --- | --- |
| A thought arrives while I am doing something else | Save it immediately without deciding what kind of thing it is | Continue without holding it in my head |
| I encounter a useful link, photo, screenshot, or voice thought | Keep the material and any context I choose to add | Avoid reconstructing it later |
| I remember the gist but have lost the wording | Search with my own description and contextual clues | Recognize and recover the original |
| I am writing or replying in another app | Retrieve and deliberately insert or copy relevant material | Use it without moving through a separate workspace |
| I am scrolling a feed or opening a browser tab | Encounter useful material I previously saved, through surfaces I enabled | Rediscover it during an existing habit without opening a review workspace |
| An accepted commitment is approaching | Receive a permitted cue and open its private details | Notice it in time without automatically messaging about an unaccepted reminder |
| I capture something I intend to do | Save it immediately and be offered reminder creation | Choose the commitment and know whether it was actually scheduled |
| I ask an AI assistant about my saved material | Get an answer grounded in the captures I allowed it to access | Inspect its evidence and reuse my own information |
| I return to the chat after days or a change of subject | Continue with access to what we discussed before | Avoid starting over or deciding which passages to save |

## 3. Experience rules

Rules 1–3 and 8–22 follow the latest brief, confirmed interview answers, and existing preservation commitments. Rules 4–7 are proposed acceptance criteria.

1. Capture requires no organization. A mixed block can remain intact.
2. Preserve the person's original content. Interpretations, tags, chunks, and links can change without destroying it.
3. Everyday capture and search are available outside a dedicated organizing workspace.
4. Saving confirms persistence. Processing and sync have separate, visible states.
5. Search returns recognizable originals and enough context to judge a match.
6. Copying, inserting, sharing, and creating a reminder are explicit effects with visible outcomes.
7. Incorrect organization must not strand a capture. Search and recent captures provide recovery paths.
8. The keyboard serves Capture, Find, and Chat. Resurfacing belongs in the person's enabled browsing and messaging surfaces.
9. Chat retains conversation history by default. Repeated passage-save prompts and inferred-save receipts are excluded from the current experience.
10. A resurfacing encounter shows one item. Repeats are allowed; the person does not choose between several resurfaced ideas or bookmarks.
11. Ideas/bookmarks may be eligible for external resurfacing; private details stay in the vault. Private deadline cues use neutral wording and open vault details.
12. Timed messages require an accepted reminder. Browsing resurfacing does not silently acquire reminder authority.
13. A resurfaced thought opens its original in a private reading view; a bookmark opens its saved destination. Continue in chat is available from the reading view.
14. Scrolling past leaves the item eligible for repeats. An explicit “Stop showing this” excludes it from resurfacing while preserving the saved material.
15. Capture is the default entry mode for the Mac hotkey and secondary keyboard; one toggle reaches Find, preserving drafts in both modes.
16. “Forget this” deletes the selected chat exchange and derived memory across synced devices. It removes that material from later retrieval; copies previously shared with other services have a separate boundary.
17. Ideas/bookmarks become eligible automatically; private or uncertain material stays private. There is no per-item excerpt-approval step.
18. Resurfacing selection uses captured material. The current webpage/topic and general browsing history are excluded.
19. A captured to-do list is an interactive checklist tied to its source. Reminder creation still requires acceptance.
20. Chat is also available as a keyboard mode, with the same continuing conversation and private input boundary.
21. Chat offers an explicit Temporary mode whose segments do not enter retained vault history or derived memory. External provider handling remains a separate boundary.
22. A checklist has one optional due date for the whole list. Choosing it also schedules the checklist reminder; checkbox items have no individual due dates.

The single-item rule applies to resurfacing encounters. Explicit search can return ranked matches for the person's query.

## 4. Surfaces and blueprints

These are rough interaction sketches. The platform review found a callable Open Design CLI, but its default daemon endpoint was unreachable in this session. No editable Open Design board or rendered design was created.

### The primary phone interface is the keyboard

The keyboard is the primary iPhone workspace. Capture opens by default with a notepad above the keys inside the extension; Find, original inspection, Chat and reminder controls remain in that workspace. The companion app is secondary for setup, settings, recovery and entry points the keyboard cannot support.

Minimised, Default and Expanded sizes preserve both drafts, their cursor positions and the active typing destination. Minimised retains a single visible note line. Minimising alone does not redirect note input into the host app; the person can explicitly select the host field or return to the notepad. Expanded requests more extension height, with exact device limits to be tested. Mac uses a resizable hotkey panel with a fullscreen option; true iPhone fullscreen remains unverified. See [experience roadmap](ROADMAP.md). The first FigCraft page is Keyboard first; companion screens follow on a secondary page.

### Host field and note focus

The host composer should remain immediately above the complete keyboard/notepad workspace as it grows or shrinks. The person can tap the host field to type there, then tap the note to type in the note, without switching keyboards. Initial Capture focus is Note; a size change preserves the current destination. The active destination must be visible. These are the desired interactions; host layout and unchanged-caret focus transitions require native validation. A destination-selector safeguard is shown as a proposal. See [layout/focus details](ROADMAP.md#host-composer-and-typing-destination--20-october-clarification).

### The captured note is a rich document

**Confirmed Q23 refinement:** capture supports a short thought or a full essay with lightweight, visual Markdown-style formatting and simple rich-text controls. The person can deliberately create bullets or checkbox lists. Preserve those author-chosen forms; “clearly written lists” is no longer the current conversion rule. An action sentence such as “Buy a gift for mum's birthday” can receive a soft reminder offer after it is saved, with date/time selectors directly beneath the question. The offer does not gate persistence or require a task form before writing.

```text
Rich note: short thought or essay
  [simple formatting] [bullets] [checkboxes] [attachments]
  [document body]
  Save
       |
  Saved · optional soft prompt
  Make this a reminder?
  [date] [time] [Set reminder] [Not now]
```

A checkbox list remains interactive and linked to its source. The optional post-save prompt offers one due date for the whole checklist. Choosing that due date also schedules the reminder and counts as accepting reminder creation. The control must communicate this combined effect. No separate Remind me toggle or individual-item due dates are included. A date-only choice uses a visible, configurable default time that can be changed before scheduling. Completing every checklist item cancels its pending reminder; any unfinished item keeps it scheduled. After the due reminder, unfinished lists remain overdue in Open tasks. Further timed alerts require explicit rescheduling; Q33 excludes a separate snooze control. The same document is viewed through a user-sized keyboard notepad. A companion editor is secondary; it is not a required detour for everyday capture, search, reading or chat. Exact extension-height limits need real-device testing, without promising a keyboard-to-companion launch.

### Mac: one hotkey, Capture / Find / Chat

```text
Existing app remains behind a dismissible overlay
+----------------------------------------------------+
|  [ Capture ]   Find                         Esc     |
|                                                    |
|  Idea about the opening paragraph...                |
|  https://...                                       |
|  [image] [voice attachment]                        |
|                                                    |
|  Attach                                      Save  |
+----------------------------------------------------+
               Saved locally · processing pending

+----------------------------------------------------+
|  Capture     [ Find ]                       Esc     |
|  the paper about attention I saved last month       |
|                                                    |
|  Matching passage...              12 Sep · Safari  |
|  Original text/image/link                         >|
|                         Open   Copy   Insert        |
|  More matches                                      |
+----------------------------------------------------+
```

Capture opens by default. A single toggle reaches Find while preserving drafts in both modes. Dismissal returns focus to the prior app. Exact hotkeys, result layout, and whether insertion uses accessibility permissions remain unsettled. Copy is a fallback where insertion is unsupported. The earlier adjacent-dialog design remains a candidate; the latest brief does not require its removal.

### iPhone: secondary keyboard plus complementary capture

```text
+----------------------------------+
| Existing app                     |
| Host text field                  |
+----------------------------------+
| Vault keyboard                   |
| [Capture] [Find] [Chat]           |
|                                  |
| Private capture or search buffer |
| [Save] / [Search]                 |
| Result preview → [Insert]        |
|                                  |
| Type in host / switch keyboard   |
+----------------------------------+

Photo / URL / file → Share sheet → Save to vault
Voice / camera    → Companion capture surface
Setup / access / export / recovery → Companion app
```

**Proposed safeguard:** a capture draft or search query stays separate from the host app's message until the person chooses Insert. Saving to the vault must not accidentally send a message to another person.

Apple excludes custom keyboards from secure text fields, certain phone fields, and apps that disable third-party keyboards. Keyboard microphone access is restricted. Full Access controls networking and shared-container writes. Therefore “keyboard-accessible where supported” is the viable promise; voice, images, setup, and recovery need complementary surfaces. Review [platform evidence](../.scratch/scattered-ambitious-pitch/research/17-platform-feasibility-2026-10-19.md) before implementation. Keyboard access is a product goal, not proof of App Store acceptance.

**Confirmed Q21:** Chat is also a keyboard mode. **Proposed layout:** show recent turns with scrolling and a private composer inside the available keyboard view. Send addresses the continuing chat; inserting an answer into the host text field is a separate explicit action. The companion can separately offer the same conversation. Apple does not establish a supported keyboard-to-companion launch here, so no one-tap app-opening promise is made. Exact keyboard Chat layout and Mac chat placement remain to design.

### Resurfacing: enabled feeds, new tabs, and messages

The human wants encounters while idle, scrolling, or about to enter an unproductive browsing habit. Requested surfaces are X, YouTube Shorts, a browser new tab, and WhatsApp/SMS deadline cues. All remain in the product direction; there is no forced choice of a single resurfacing surface. An unsolicited card occupying the keyboard was explicitly rejected.

```text
Existing browser feed       Browser new tab        Permitted message
---------------------       ----------------       -------------------
Normal item                 One returned idea      A commitment cue
Your returned material      or saved bookmark      Open private details
Normal item                 Open / use / dismiss   in the vault
```

**Confirmed:** each encounter shows one item; repeats are allowed. Eligible ideas/bookmarks can appear outside the vault while private details stay inside it. Timed deadline messages require accepted reminders. The human chose browser feeds plus new-tab/messages for iPhone. Ordinary iPhone apps have no supported route to insert material into native X or YouTube feeds; that is not a first-release promise. Tapping a thought opens its private original; a bookmark opens its link. Passing leaves eligibility intact, and an explicit control stops resurfacing. Exact eligibility, cadence/selection, and layout remain to design. See [surface research](../.scratch/scattered-ambitious-pitch/research/23-resurfacing-surface-contracts-2026-10-20.md) and the [UX journeys](UX.md).

### One vault behind every surface

```text
 Keyboard   Mac hotkey   Share   Companion   Chat/LLM
      \          |        |         |          /
       +---------+--------+---------+---------+
                         |
                 CAPTURE ORIGINAL
            content · attachments · origin
                         |
              Background interpretation
          transcription / OCR / links / concepts
                         |
             Search index + access controls
                         |
          Find → inspect source → open/copy/insert
                         |
             Approved reminders / optional resurfacing

Continuous chat history → same searchable corpus
    speaker · original turn · conversation context
```

This describes responsibilities, without choosing databases, models, hosting, or a wiki structure. Processing should be retryable without requiring recapture.

## 5. Requirements and acceptance examples

**Labels:** **Brief** = explicitly requested now; **Confirmed** = answered by the human in this interview; **Existing** = compatible earlier commitment; **Proposed** = recommended detail requiring confirmation; **Conditional** = depends on an unanswered decision. All detailed release criteria remain subject to the final scope review.

| ID | Requirement | Acceptance example | Basis |
| --- | --- | --- | --- |
| C1 | Accept mixed freeform capture without mandatory metadata. | Save a reflection, shopping list, and three links together without selecting a type or folder. | Brief |
| C2 | Support text, multiple links, multiple images, and voice across suitable surfaces. | Keep an image alongside its explanatory text; retain audio alongside its transcript. Exact file types and limits must be specified. | Brief; retention detail Proposed |
| C3 | Keep originals and attachment relationships accessible. | A result from a chunk opens the complete capture; a bad transcript does not replace the audio. | Existing; media detail Proposed |
| C4 | Make submission durable before claiming it is saved. | After confirmation, reopening finds the record even if classification failed. Offline capture reports local and pending-sync state accurately. | Proposed; local/private-sync direction Confirmed |
| C5 | Preserve drafts and recover failed submissions. | Switching to Find or dismissing does not silently discard an unsaved thought. Retry cannot create accidental duplicates. | Proposed |
| O1 | Organize enough to make retrieval work without manual filing. | Find a screenshot using recognized text or a description, even if its inferred topic was wrong. | Brief |
| O2 | Keep inferred labels, entities, relations, and chunks revisable. | Correcting “work” to “personal” changes retrieval context without rewriting the capture. Uncertain dates and categories remain uncertain. | Existing; details Proposed |
| S1 | Search exact wording and approximate meaning. | Find a unique code exactly and an old idea using different words. Related material cannot hide an exact match. | Brief; ranking detail Proposed |
| S2 | Use remembered context where available. | “The article Maya sent last month” can narrow matches only if person/date/source information was captured or explicitly connected. | Proposed |
| S3 | Make results inspectable and useful in place. | See the matched passage, date, source, and original; copy or insert deliberately. Preserve the host draft. | Brief; presentation Proposed |
| S4 | Handle insufficient evidence honestly. | An empty result offers recent captures or a simpler query; chat says when the vault has no supporting record. | Proposed |
| S5 | Search supported media content after processing. | OCR/transcript-derived hits link to the image/audio and relevant excerpt; pending or failed extraction is visible. | Brief; failure behavior Proposed |
| H1 | Provide Mac hotkey capture/search with a simple toggle. | Invoke from a supported app, save or search, and return to the prior context. | Brief |
| H2 | Provide a secondary iPhone capture/search keyboard plus complementary capture. | Switch from the usual keyboard, save or find material, then return. It provides usable keyboard input without Full Access. No resurfacing item displaces the keyboard. | Confirmed Q5/Q6; detailed interaction Proposed |
| A1 | Keep one continuing chat with retained conversation history. | Return after a week and ask about a prior discussion without starting a new thread or manually saving its passages. | Confirmed Q7; retrieval quality must be tested |
| A2 | Make conversation history usable within the wider corpus without per-passage save prompts. | Search can return an original exchange. User words, quotations, assistant output, and later corrections remain attributable. A discussion of an option is not silently asserted as a personal fact. | History/corpus direction Confirmed Q7; evidence behavior Proposed |
| A3 | Allow scoped external LLM access. | A connected assistant retrieves permitted captures and can cite them. Saving, changing, deleting, and scheduling require separately defined permissions. | Brief; permission contract Proposed; private sync/cloud AI policy Confirmed |
| T1 | Save task-like captures, then offer reminder creation. | “Call Maya tomorrow at 5” is saved immediately. A reminder is created only after the person chooses the offered action; its schedule and outcome are visible. | Confirmed Q3; interaction details Proposed |
| R1 | Include optional resurfacing across enabled browser feeds, new tabs, and permitted message channels. | An automatically eligible idea/bookmark returns during browsing; private or uncertain material stays private. A neutral private-deadline cue arrives only for an accepted reminder. | Confirmed Q2/Q6/Q10–Q13 |
| R2 | Show one item per resurfacing encounter; allow repeats. | One thought or bookmark appears. Passing leaves it eligible; “Stop showing this” excludes it while preserving the original. | Confirmed Q9/Q15; cadence/selection open |
| R3 | Open the appropriate destination on tap. | A thought opens its original in a private reading view with Continue in chat available; a bookmark opens its saved destination. | Confirmed Q14 |
| H3 | Open Capture by default, with one toggle to Find. | Both entry surfaces open Capture; capture and query drafts survive mode changes. | Confirmed Q16 |
| A4 | Support forgetting selected conversation material. | “Forget this” removes the exchange and derived memory across synced devices so it no longer appears in history, search, answers, or resurfacing. | Confirmed Q17; offline/recovery mechanics open |
| A5 | Offer Temporary chat segments. | Turning Temporary on visibly excludes that segment from retained vault history and derived memory. Ordinary conversation remains saved by default. | Confirmed Q22/Q26; temporary lifecycle open |
| H4 | Offer Chat within the secondary keyboard. | Capture, Find, and Chat are accessible without treating chat input as a host-app message. Explicitly inserting an answer is a separate action. | Mode Confirmed Q21; detailed layout/buffering Proposed |
| T2 | Make captured to-do lists interactive. | Tick off a checklist item and retain its link to the original capture; no timed reminder is created by capture alone. | Confirmed Q20/Q23/Q27–Q31; Confirmed Q32–Q35 lifecycle; delivery implementation open |
| C6 | Provide a lightweight visual Markdown-style rich-text document. | Write an essay, formatted bullets, or explicit checkboxes with simple controls; save without classification. An action sentence gets an optional soft reminder offer with date/time selectors. | Confirmed Q23 refinement; exact controls/layout open |
| T3 | Find unfinished items across captures. | Use Open tasks within Find or ask Chat; each item opens its original capture. | Confirmed Q24 |
| T4 | Keep reminder ownership inside this app. | Accepted reminders are linked to captures and managed here. External calendar connections and calendar timeboxes are a later integration direction. | Confirmed Q25; calendar integration deferred |
| R4 | Select resurfacing content from captured material only. | The integration displays an eligible item without using the current page's topic or retaining browsing history for selection. Retained chat belongs to the corpus; Temporary segments are excluded. | Confirmed Q19; selection priorities explicitly deferred Q18 |
| D1 | Provide inspection, editing, deletion, export, and recovery outside the daily flow. | Export originals plus attachments and provenance; deletion removes active search/AI access and follows a documented backup-retention policy. | Proposed |
| D2 | Keep cross-device state understandable with private sync. | A phone capture appears on the Mac; offline devices show pending changes; conflicting edits and deletes cannot silently resurrect private content. | Private sync Confirmed Q4; conflict/recovery details Proposed |

“As many pictures or links as possible” expresses a low-friction goal. The release must publish supported formats, per-item and total limits, upload progress, and partial-failure behavior. Unlimited media is not an established requirement.

For links, preserving a URL and preserving the linked page are separate promises. The person must be able to tell what was actually retained when a page later changes or disappears. Snapshot scope remains open.

## 6. Commitment and chat boundaries

The user's examples include both information and things to do. They can share an entry point while carrying different responsibilities.

```text
“Call Maya tomorrow at 5”
          |
    Original saved
          |
    Commitment candidate
          |
     Offer reminder creation
          |
      Person accepts
          |
 Resolved time + time zone + chosen destination
          |
 Creation attempted → Confirmed scheduled / Failed / Unknown
```

**Confirmed Q3 policy:** save immediately, then offer an explicit reminder action. “Tomorrow” needs capture-time context; “5” can be ambiguous. Editing the capture and editing an external reminder require a defined relationship. A retry after uncertain delivery must avoid duplicate reminders. The policy is settled; the interaction, destination, and failure behavior still need design.

**Confirmed Q11:** a timed message requires an accepted reminder. Declining the offer does not authorize a later timed deadline message. An eligible idea or bookmark may still return through quiet browser resurfacing under its content policy; scrolling past a cue is not task completion.

### Continuous chat and its memory

**Confirmed Q7 direction:** one continuing conversation retains its history by default and contributes to the wider corpus. The human rejected automatic passage-selection receipts, repeated save approval, and relying on explicit “save this” commands for ordinary chat memory.

**Proposed refinement:** retain the original exchanges as conversation evidence. Derived summaries and connections help retrieval and link back to the turns that support them. A user saying “maybe Berlin” remains a discussion of Berlin; an assistant suggestion remains the assistant's suggestion. Later corrections should be available when older claims are recalled. Useful memory means retrieving the appropriate history; it does not promise flawless recall of every detail.

Chat can search captures and history in one request, show the supporting originals, and continue the conversation without a filing step. Side effects retain their own policy: remembering a sentence containing a deadline does not by itself create a reminder. External assistants receive only content within their granted access. **Confirmed Q17:** forgetting removes the selected original exchange and derived memory across synced devices; copies already sent to an external service have a separate deletion boundary. **Confirmed Q21/Q22/Q26:** Chat is also a keyboard mode; Temporary can read relevant saved vault material while retaining no new segment messages or derived memory. Importing other chat apps, correction UI, recovery mechanics, exact temporary-segment lifecycle, keyboard layout, and Mac chat placement remain to design.

### Reminder ownership and later calendar integration

The app owns reminders and their schedule/completion state. Accepting the post-save offer creates a reminder here. Open tasks in Find and Chat provide cross-capture retrieval. Exact editing, delivery, completion, and failure flows remain to specify.

The human also described future optional Apple/Google Calendar connections. Those could send chosen commitments or schedule calendar timeboxes. A timebox is a scheduled activity with a time interval; it is distinct from a reminder cue. The human explicitly asked to solve the current capture/reminder problem first. Calendar connections, automatic timeboxing, and bidirectional calendar synchronization are not current first-release commitments.

UNIIChAT is the named reference. Victor Taelin's official [source repository](https://github.com/VictorTaelin/UniiChat) documents one continuous conversation, original logs, and summarized views that can be expanded to earlier detail. Source review informs the experience; adoption, memory quality, and compatibility with this product's privacy contract remain unchosen. The user's request is to refine design before implementation.

### Local use, paid sync, and optional AI

The human wants a free local version with local storage, retrieval, and connection to a compatible locally available chat app if possible. Sync is the intended monetization direction. Its exact packaging, the role of managed AI, and whether resurfacing is premium remain open.

Local-first means a device has a usable copy. Sync sends changes between copies. Organization can also happen on a device: some techniques search words and metadata, some compare meanings, and some use a local model. These capabilities have different device and quality constraints. There is no need to select their implementation to decide the experience. [Local-first research](https://www.inkandswitch.com/essay/local-first/), [Apple on-device model documentation](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models).

```text
Mac: usable local vault  <--- encrypted changes --->  Sync service
                                                         |
                                              encrypted changes
                                                         |
                                              iPhone: local vault

Optional AI processing is a separate route:
Selected allowed content ---> chosen AI service ---> derived results
```

**Confirmed Q4 policy:** paid sync stores encrypted data that our service cannot read; cloud AI is a separate opt-in. A synced vault can still be local-first. Sending a passage to a cloud model discloses that passage to the chosen provider, even if sync is encrypted. Existing encrypted sync demonstrates that these are separable promises; this project has not chosen an encryption design. [Obsidian Sync security](https://help.obsidian.md/Obsidian+Sync/Security+and+privacy).

Showing plaintext in a third-party webpage or sending it through WhatsApp/SMS creates another content boundary. **Confirmed Q10/Q13:** eligible ideas/bookmarks may resurface automatically; personal chat passages and private reflections are excluded by default, and private or uncertain material stays private. No per-item excerpt approval is required. Private deadline messages use neutral cues that open vault details. Automatic sensitivity detection is not a proven guarantee; test mixed private/idea captures, uncertainty handling, and correction behavior before release. The [surface report](../.scratch/scattered-ambitious-pitch/research/23-resurfacing-surface-contracts-2026-10-20.md) distinguishes app-owned pages, shared webpage content, and message delivery.

Design the person-facing states separately: **Saved on this device**, **Waiting to sync**, **Available on your devices**, **Search processing pending**, and **Using cloud AI** when applicable. Declining cloud AI should leave the agreed local experience usable. What local semantic retrieval and organization must achieve on each supported device remains a quality/design decision to settle before release.

## 7. What the first release must settle

The first release includes iPhone and Mac together, as confirmed in Q8. The full vision includes multimodal capture, automatic organization, semantic search, chat, external LLM access, and optional resurfacing across the requested surfaces. Engineering capacity is not the reason to exclude behavior; inclusion requires concrete product decisions and an honest surface contract.

Decisions already answered:

- **Q1:** the founder's whole day defines the first experience.
- **Q2:** optional resurfacing belongs, with different strategies to explore. Premium packaging is undecided.
- **Q3:** save task-like thoughts, then offer reminder creation.
- **Q4:** private sync that the service cannot read; cloud AI opt-in. Free local use and monetized sync remain the tier direction.
- **Q5:** a secondary capture/search keyboard.
- **Q6:** natural encounters across X, Shorts, new tabs, and WhatsApp/SMS; keyboard resurfacing rejected. Q9 defines one item per encounter and Q12 selects browser-based phone encounters.
- **Q7:** one continuing chat with history retained by default and usable in the corpus; repeated passage-save interactions rejected.
- **Q8:** iPhone and Mac together in the first release.
- **Q9:** one item per resurfacing encounter; repeats allowed. The phrase “once” did not mean once per item or once across channels.
- **Q10:** ideas/bookmarks may be eligible; private details stay in the vault. Private reflections and personal chat passages are excluded by default; private deadline cues use neutral wording.
- **Q11:** timed messages require accepted reminder creation.
- **Q12:** browser feeds plus new-tab/messages on iPhone; native-feed insertion is outside the first-release promise.
- **Q13:** automatically show eligible ideas/bookmarks; keep uncertain items private. The proposed excerpt-approval step was rejected.
- **Q14:** thought opens the private original reading view with Continue in chat available; bookmark opens its link.
- **Q15:** scrolling past preserves eligibility; explicit Stop showing this excludes it.
- **Q16:** Capture opens by default; one toggle reaches Find, with preserved drafts.
- **Q17:** forgetting removes the selected original exchange and derived memory across synced devices.
- **Q18:** selection priorities deferred by the human; do not choose a strategy or re-ask it in this round.
- **Q19:** selection uses captured material only, without current-page/topic context or retained browsing history.
- **Q20:** interactive checklist tied to the original capture; capturing it creates no reminder by itself.
- **Q21:** Chat is also a keyboard mode. The proposed companion-only chat placement was not adopted.
- **Q22:** offer explicit Temporary chat segments, excluded from retained history and derived memory.
- **Q23 refinement:** visual Markdown-style rich documents with simple controls, explicit bullets/checklists, essay-length writing, and a soft date/time reminder offer after saving an action-like note. Q27–Q28 subsequently set one whole-checklist due date that also schedules the reminder.
- **Q24:** Open tasks in Find and Chat, linked to original captures.
- **Q25:** this app owns reminders. Apple/Google Calendar connections and calendar timeboxing are a future direction, deferred while current problems are solved.
- **Q26:** Temporary may read relevant saved vault memory, saving no new messages or derived memory.
- **Q27:** choosing a checklist due date also schedules its reminder; a separate optional alert toggle was not chosen.
- **Q28:** dates apply to the whole checklist only; individual-item dates are excluded.
- **Q29:** use a visible configurable default time, editable before scheduling.
- **Q30:** completing every item cancels the pending checklist reminder.
- **Q31:** unfinished lists remain overdue; repeat timed alerts require an explicit choice; Q33 refines this to editing/rescheduling without a separate snooze control.

A date-only choice uses a visible, configurable default time that can be changed before scheduling. Completing every checklist item cancels its pending reminder; any unfinished item keeps it scheduled. After the due reminder, unfinished lists remain overdue in Open tasks. Further timed alerts require explicit rescheduling; Q33 excludes a separate snooze control.

The human has authorized MVP design and a launch attempt today. Detailed interviewing is paused; remaining design choices will be made explicit in the [MVP launch design](MVP.md). The human agreed to a private pilot with sync, required native iPhone keyboard and Mac hotkey, and rejected a browser fallback. Design is in FigCraft, using greyscale industrial minimalism without brand exploration. Signing and actual two-device behavior remain launch gates.

- **Q32 refinement:** due reminders also appear in the app's continuing chat, where the person can request rescheduling. WhatsApp/SMS are optional connected channels. Device notifications remain the proposed primary external cue; exact delivery needs validation.
- **Q33:** edit or remove reminders, preserving original captures. A separate snooze control is excluded. Explicit chat rescheduling is an edit.
- **Q34:** retain the original time zone and scheduled instant when travelling; display the zone when setting/editing.
- **Q35:** reopening a completed checklist offers a new reminder; it does not automatically restore the cancelled reminder.

A due reminder in chat is a linked app event, distinguishable from user and assistant messages. A reschedule request must identify the reminder and resolve date/time before changing it; the chat shows the resulting schedule or a visible failure. Clarify ambiguous references rather than edit an arbitrary reminder. These are proposed interaction details for the MVP design.

**Resolved Q13:** after clarification, the human chose automatic eligibility with uncertain items kept private. The exact-snippet approval proposal is retained only in interview history as a rejected alternative. It is not part of the current capture or resurfacing flow.

Selection priorities (Q18) remain explicitly deferred. Other remaining branches include activation/return flows, keyboard Chat layout, temporary-segment lifecycle, capture formats/limits and voice languages, resurfacing cadence, reminder delivery/failure, external-history imports, access scopes, sync conflicts, and recovery. These stay visible without treating them as settled release behavior.

## 8. Validation and success

**Desired outcome:** the person trusts that chosen material is saved and can recover and use it with less effort. Capture count and graph size alone are insufficient.

Proposed tests, not results:

1. **Capture comparison:** observe the same text, mixed text/link, screenshot, and voice tasks using the prototype and the person's self-chat/notes workflow. Include setup and keyboard switching costs.
2. **Refinding benchmark:** with consent, assemble about 200 representative captures and 60 held-out queries spanning exact strings, paraphrases, contextual clues, images, voice, and no-match cases. Compare keyword-only, semantic-only, and combined retrieval. The person judges relevance before rankings are tuned on a separate set.
3. **Cross-app feasibility:** test keyboard availability, private-buffer behavior, attachment handoff, and explicit insertion in the person's actual iPhone and Mac apps. Record denied permissions and offline behavior. A document review cannot replace this pilot.
4. **Return and abandonment:** after a week away, recover a record without cleaning an inbox or reorganizing the vault. For optional resurfacing, measure useful returns, unwanted interruptions, and duplicate encounters separately.
5. **Conversation continuity:** return to an old exchange, retrieve its exact original, correct an earlier statement, and confirm the assistant attributes quoted/hypothetical content correctly. Compare summaries against their source turns.
6. **Trust:** interrupt processing and sync, deny access, correct interpretations, delete records, and retry commitment creation. Verify the visible status matches what happened.

Candidate release targets to confirm after a baseline: at least 85% of answerable benchmark queries have a relevant original in the first three results; first useful search results within 1.5 seconds at the agreed corpus/device; local text-save confirmation within 300 milliseconds after submission. These are proposed quality bars, not measured capability or research-derived thresholds. Large attachments and optional cloud synthesis need separate progress and latency criteria.

## 9. Earlier decisions to reconcile

| Earlier record | Latest brief | Treatment now |
| --- | --- | --- |
| Maker/publishing and spontaneity framing | Personal thoughts, memories, tasks, events, links, and notes | Q1 confirms the founder's whole day. Publishing remains one use case. |
| Mac-only, typed capture in MVP | iPhone keyboard plus Mac; images and voice | Q8 confirms both platforms in the first release. Capture-format limits remain open. |
| System prompts in X; Substack publishing target | Capture/search plus natural resurfacing and remembered chat | X/Shorts browser feeds, new tabs, and permitted messages are selected; no native-phone feed insertion promise. |
| Two story-written wikis with one-way privacy boundary | Automatic organization behind a simple surface | Storage/presentation structure remains open; original-preservation commitment carries forward. |
| Private notes remain on device | Private sync and explicit cloud AI choice | Q4 settles service-unreadable sync and cloud AI opt-in. Q10/Q13 keep private or uncertain material private while allowing automatic idea/bookmark eligibility. |
| Utility price band and free BYOK tier | Free local version; monetization through sync | Current tier direction recorded. Exact price, BYOK, managed AI, and resurfacing packaging remain open. |

The [private-sync decision](adr/0001-private-sync-and-optional-cloud-ai.md) records the product privacy boundary without selecting its implementation. The glossary contains resolved language; open product choices remain here and in the [decision ticket](../.scratch/scattered-ambitious-pitch/issues/20-headless-second-brain.md).
