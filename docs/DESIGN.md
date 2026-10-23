# Design

This project is a headless second brain: capture without filing, then find and reuse saved material inside the apps the person already uses. On 23 October the human approved the core MVP: Capture → Find → reuse, with the iPhone keyboard, persistent movable Mac control, resident offline copies and private cross-device sync. The Mac control expands from its anchor; hotkey access remains complementary. Chat, reminders and resurfacing are deferred, with existing work preserved. Image/voice inclusion and search acceptance remain explicit scope work. See [the core MVP definition](MVP-CORE.md) for the current release boundary.

The human authorized a private native pilot and implementation after the earlier design review; browser fallback was rejected. The repository contains greyscale FigCraft designs and a working native development baseline. Protected indexed retrieval, encrypted cross-device sync and release readiness remain unverified. Engineering uses the requested Matt Pocock skill stack and approved public test boundaries. [The 20 October launch design](MVP.md) records earlier scope; later explicit decisions take precedence.

## Native implementation workflow — 2026-10-20

The human approved the Matt Pocock engineering setup, three public test boundaries and eight vertical slices. Root `AGENTS.md` routes tracker/domain guidance through `docs/agents/`. The authoritative native build spec is `.scratch/native-mvp/spec.md`; separate tickets live under `.scratch/native-mvp/issues/`. Ticket 01 is resolved; ticket 02 is resolved; ticket 03 is claimed. Review compares against c319917 and includes pending changes. Tests exercise keyboard workspace state, saved-vault behavior and encrypted two-vault replication; actual host/device behavior needs separate native evidence. Resurfacing selection remains decision-blocked.

## Native capture/refind architecture

The local Swift package supplies domain records, coordinated JSON persistence, retrieval and observable presentation. A generated, committed Xcode project links those libraries into three targets. The Mac AppKit adapter registers Control–Option–Space through Carbon and hosts the shared SwiftUI workspace in a floating resizable panel; Escape hides the panel without replacing its model. The companion provides scrolling setup content and a bottom safe-area composer. This representative host keeps its composer directly above the entire keyboard workspace as the extension grows; setup content scrolls away first. The keyboard controller owns a private UIKit editor and custom keyplane, routes deliberate host input through `textDocumentProxy`, and exposes original inspection with explicit Insert. Initial typing support is basic English keys, shift, digits/punctuation, delete, return and keyboard switching; Apple parity is not established.

Phone targets resolve the same entitled App Group URL before constructing the model. The keyboard requires Full Access and refuses an isolated fallback vault if sharing is unavailable. App Groups share a file on one device; cross-device sync is still unimplemented. Ordinary host typing is never appended as a capture. Save confirmation follows a coordinated atomic update; Find returns complete original text. The pure saved-vault test reopens storage using another caller before querying it. A separate public workspace regression test proves that activation selects Capture and preserves Capture/Find/Chat drafts. Both native adapters invoke that shared activation operation. The domain owns lexical/ranking logic; the platform model supplies optional local semantic scores, so keyboard and panel use one retrieval path. Shared views also expose the existing preliminary inference adapter, but chat retention/search/Forget and reminder controls have not met their tickets yet.

All three targets compiled with Xcode 26.2. Ticket 01 passed its ten-test checkpoint and independent reviews; the human then confirmed keyboard capture/Find/original/Insert and the real Mac global hotkey. The ticket is resolved. Mac builds use an explicit arm64 destination. The installed simulator runtime is iOS 17.5; target-based SDK compilation succeeds despite scheme-destination selection failing. The app installed and launched in the iOS 17.5 simulator. The unsigned build correctly reported unavailable sharing; an ad-hoc-signed simulator build then registered its App Group and rendered the setup/test-host screen without that error. After the Mac was unlocked, native save/Find/original checks passed on Mac and companion; the human confirmed the real Mac global hotkey. The keyboard is enabled and renders after standard bundle metadata completion and a discovery refresh, with simulator-only Full Access explicitly authorized. The corrected test-host composer is visible above the workspace. The human confirmed the complete custom-key capture/Find/original/Insert path after simulator automation returned noWindowsAvailable on those controls. Human ticket-02 checks passed sizing/selection preservation and formatted save/reopen. The reported tap failure was reproduced and corrected. On 21 October the human confirmed on-screen-key routing in the simulator test host; broader native verification remains open. No real-device installation or synced launch is claimed.

## Pad sizing and visual editing — implementation in progress

Ticket 01 is resolved after the human confirmed the simulator keyboard capture → Find → original → Insert path, with the host field untouched until Insert. Mac and companion UI checks, the real global shortcut, builds, tests and two review axes were already complete. Ticket 02 is resolved; ticket 03 is claimed; ticket 06 is unblocked and unclaimed.

The native keyboard now uses a public KeyboardWorkspace session for destination, size and per-mode private draft metadata. Private drafts carry original text, RTF, UTF-16 selection and scroll offset; host text stays in the host app. Resizing changes layout constraints around the same live editor. Independent tests established that sizing preserves writing context and that Capture/Find/Chat recover their separate drafts and selections without rerouting host input.

The keyboard observes the proxy's document identity after private editing begins because iOS may return the proxy to the host without ending the private responder. A host context callback selects App, retains that proxy and hides the local caret. A simultaneous notepad tap reselects private input; custom keys and basic hardware insertion/deletion follow the route. Keeping the local responder avoids replacing the extension with Apple's keyboard. Basic hardware typing and human on-screen-key routing pass in the simulator test host; real devices and other hosts remain release checks. Identity is read after context delivery or an explicit write, never during view construction. All App insertion/deletion uses one validated host-proxy path; an absent host produces a visible tap-the-app-field message instead of falling back to a private document.


Native visual editors use UITextView/NSTextView with optional Bold, Italic, Bullet and Checkbox controls. RTF is stored alongside the exact original string; retrieval uses the string. The saved-vault tests verify rich capture survives reopening and explicit visual checkbox glyphs produce authored checklist items without scheduling reminders. The keyboard shares the same editing operations as Mac/companion. The Mac visual bold → Save → Find → original path retained formatting in the native UI. Original readers render matching saved RTF with a plain-text fallback. Off-screen chat-send acknowledgement clears only the unchanged outgoing draft, preserving newer writing and the active mode. New native sizes, formatting controls and tap-to-host callbacks need runtime validation; public state tests alone do not establish cross-process focus behavior. No universal fullscreen or Apple keyboard parity claim is made.

## Current research and requirements effort — 2026-10-19

The human's latest direction is a **headless second brain**: capture thoughts, reflections, memories, tasks, lists, events, reminders, links, pictures, and voice without filing them, then retrieve them through simple, strong search. Everyday access lives in a secondary iPhone keyboard with Capture/Find/Chat and a Mac hotkey surface. A continuing remembered chat and external LLM access use the same vault; Temporary chat segments are excluded from retained memory.

The research/design stage has produced a PRD and native FigCraft states. The current stage is native implementation through the approved build spec, vertical tickets, TDD and review. The latest brief and interview answers take precedence over the earlier scope; decisions and remaining boundaries are recorded explicitly. Earlier sections below remain a historical record. Mac-only, typing-only, maker/publishing-only, and the two-wiki proposal are not the current release specification; natural resurfacing now explicitly includes feed encounters.

The decision frontier is recorded through selectable interview questions. Research covers firsthand public discussions, first-party alternatives, and Apple platform constraints. Product recommendations stay visibly provisional until the human answers and confirms shared understanding. The native foundation currently uses Swift, SwiftUI, Foundation and XCTest. CloudKit with app-side encryption remains a sync proposal requiring configuration and verification.

### Keyboard-first clarification and writing space — 2026-10-20

The keyboard is the primary iPhone workspace. Capture opens by default with a notepad above the keys inside the extension; Find, original inspection, Chat and reminder controls remain in that workspace. The companion app is secondary for setup, settings, recovery and entry points the keyboard cannot support.

Minimised, Default and Expanded sizes preserve both drafts, their cursor positions and the active typing destination. Minimised retains a single visible note line. Minimising alone does not redirect note input into the host app; the person can explicitly select the host field or return to the notepad. Expanded requests more extension height, with exact device limits to be tested. Mac uses a resizable hotkey panel with a fullscreen option; true iPhone fullscreen remains unverified. The human requested future inheritance of their existing default keyboard; public iOS APIs do not establish a universal overlay over another keyboard. This remains a roadmap investigation, without changing the current custom-extension route.

The FigCraft file is reorganized into Keyboard first, Pad sizes, Typing destination, Mac hotkey, Companion and setup, and Components pages. “Maya” was a fictional host-app contact in the previous mock; it was never an app name. It is removed from current screens. Functional greyscale styling remains. No native feature work was added during this design clarification.

Native implementation status: three Xcode targets now compile: iPhone companion, embedded keyboard and Mac hotkey panel. A saved-vault behavior test proves local capture/reopen/refind through public persistence and retrieval. The ticket-01 keyboard flow is human-verified in the simulator; new size/focus behavior, real-device installation and private sync remain unverified. See [native status](../native/README.md).

Code identity: the product is named Mind Machine (GitHub `shomoD9/mind-machine`). Swift modules are `MindMachineCore` and `MindMachineUI`; Xcode project `MindMachine.xcodeproj` has targets `MindMachine`, `MindMachineKeyboard` and `MindMachineMac`; bundle identifiers are `dev.mindmachine.pilot[.keyboard|.mac]` with App Group `group.dev.mindmachine.pilot`. The on-disk vault stays at `SecondBrain/vault.json` and notification identifiers keep the `secondbrain.reminder.` prefix, so existing vaults and pending reminders remain readable; no migration was added. Changed bundle identifiers give a signed install a new sandbox and App Group container, so a signed device install starts with an empty vault.

### Host composer and focus correction — 2026-10-20

The human pointed out that the mock host composer should move with the keyboard workspace. The generator now anchors it above the full extension at each size, rather than at one fixed screen coordinate; the expanded example keeps the composer visible while its conversation viewport shrinks. This is a representative host layout, not authority to control another app’s composer.

Tap-host-to-type-in-host and tap-note-to-type-in-note are the desired interaction. Initial Capture selects Note; size changes preserve whichever destination is active. The new Typing destination page shows both carets/drafts and an active-field indication. The indicator is tappable as a proposed fallback because callbacks do not guarantee every unchanged-caret host tap. At that design checkpoint the first-responder route was still untested; the native routing results and outstanding caret limitations are documented above and in the caret follow-up below. [Research](../.scratch/scattered-ambitious-pitch/research/25-keyboard-focus-and-host-layout-2026-10-20.md).

### Engineering workflow requested — 2026-10-20

The human requested the local ask-matt skill stack and approved its setup on 2026-10-20. The route for this native build is setup → spec → vertical tickets → implement/TDD → Standards/Spec review. Root AGENTS.md and docs/agents now configure the retained local Markdown tracker, default triage labels and single domain context.

The [engineering plan](../.scratch/native-mvp/review-plan.md), [published build spec](../.scratch/native-mvp/spec.md), three public test boundaries and eight individual tickets are approved. Review baseline is c319917. Ticket 01 is resolved after saved-vault/workspace tests and native/human acceptance; ticket 02 is resolved; ticket 03 is claimed. Native runtime evidence and two independent review axes are recorded separately from test approval.

The human asked about automatic categorisation. The current proposal is to preserve originals and build an automatic index with provenance, dates, links, explicit structure and local retrieval, adding replaceable topic/tag inference only where it improves outcomes. No mandatory category taxonomy has been chosen. This proposal does not settle resurfacing ranking or privacy eligibility.

### Current documents

- [FigCraft native MVP](design/native-mvp.figcraft) and [design handoff](design/README.md): greyscale phone, keyboard and Mac states with linked components and prototype flows. The earlier HTML preview is superseded.
- [MVP launch design](MVP.md): today’s proposed pilot, screens, implementation gates and release decisions.
- [PRD](PRD.md): current vision, jobs to be done, proposed acceptance examples, rough ASCII blueprints, platform constraints, and open decisions.
- [UX journeys](UX.md): keyboard capture/search, feed/new-tab/message encounters, continuous chat, and the selected browser-based phone journey.
- [Research synthesis](RESEARCH-2026-10-19.md): findings, counterevidence, coverage limits, and links to seven detailed reports, including direct X, UniiChat, and resurfacing-surface follow-ups.
- [Private sync and optional AI decision](adr/0001-private-sync-and-optional-cloud-ai.md): the accepted privacy contract, with implementation unchosen.
- [Headless second brain decision ticket](../.scratch/scattered-ambitious-pitch/issues/20-headless-second-brain.md): design tree and interview answers. It remains claimed until the product decisions are complete.
- [Experience roadmap](ROADMAP.md): user-controlled writing space and preferred-keyboard inheritance, with platform boundaries.
- [Glossary](../CONTEXT.md): resolved domain language.

### Confirmed in the first round — 2026-10-20

- Design around the founder's whole day, including personal and creative material.
- Include optional resurfacing and explore different strategies. Whether it is premium is undecided.
- Save task-like thoughts immediately, then offer reminder creation. Do not equate a stored thought with a scheduled reminder.
- Provide a free local experience with storage/retrieval and compatible local assistant access where feasible. Monetize sync. The human wants guidance on processing/privacy while keeping this stage focused on design and user experience.

### Confirmed and redirected in round two — 2026-10-20

- Sync is private: the sync service cannot read the content. Cloud AI is opt-in. Encryption/recovery implementation remains undecided.
- The iPhone surface is a secondary capture/search keyboard. iPhone and Mac belong in the first release together.
- Resurfacing appears naturally in the person's existing activity: X scrolling, YouTube Shorts, browser new tabs, and WhatsApp/SMS deadline cues. A resurfacing card in the keyboard was explicitly rejected. The phrase “once” was clarified in round three as one item per encounter, with repeats allowed.
- Chat is one continuing conversation with its own retained history by default. The history can be used within the wider corpus. Per-passage inferred-save receipts and repeated save-approval prompts were rejected. UNIIChAT is a named research reference, with adoption and fit still unchosen.

### Confirmed in round three — 2026-10-20

- Each resurfacing encounter shows one item; the person does not choose between multiple ideas or bookmarks. Repeats are allowed. There is no once-ever or cross-surface once-only delivery requirement.
- Ideas/bookmarks may be eligible for external resurfacing; private details stay in the vault. Personal chat passages and private reflections are excluded by default; private-deadline cues use neutral wording.
- Timed messages require an accepted reminder. A captured deadline alone does not grant timed-message authority.
- The iPhone browsing journey uses browser feeds plus new-tab/messages. Native X/YouTube feed insertion is outside the first-release promise; browser integrations remain to be tested.

### Confirmed in round four — 2026-10-20

- Tapping a thought opens its original private reading view, with Continue in chat available. A bookmark opens its saved destination.
- Passing a resurfaced item leaves it eligible to return. Stop showing this excludes it from resurfacing while retaining the saved material.
- Capture opens by default through the Mac hotkey or secondary keyboard; a single toggle reaches Find, preserving drafts.
- Forget this removes the selected conversation exchange and derived memory across synced devices. Already-shared external copies have a separate boundary.

After asking for clarification, the human chose automatic idea/bookmark eligibility with uncertain items kept private (Q13). The proposed per-item excerpt-approval step was rejected. This preserves immediate capture and automatic resurfacing; sensitivity quality, mixed captures, and correction behavior still need validation.

### Confirmed and deferred in round five — 2026-10-20

- Selection priorities (Q18) are deferred at the human's request. No recent-interest, neglected-item, or random-selection strategy is chosen; do not reopen that branch now.
- Resurfacing uses captured material only. Do not use the current webpage/topic for relevance or retain general browsing history. The integration still needs to recognize an enabled surface to display its cue.
- Captured to-do lists are interactive checklists linked to their originals. Capture alone creates no timed reminder.
- Chat is also a keyboard mode. The keyboard now offers Capture, Find, and Chat; a resurfacing card remains excluded. Detailed keyboard Chat layout and Mac chat placement remain open.
- Offer explicit Temporary chat segments excluded from retained vault history and derived memory. Ordinary chat remains saved by default; access to existing memory and segment lifecycle remain to design.

### Confirmed and refined in round six — 2026-10-20

- Capture is a full, lightweight, visual Markdown-style rich-text document, usable for an essay, bullets, or explicit checkbox lists. Respect author-chosen formatting. The earlier “clearly written lists” conversion proposal is superseded by this editor-and-post-save-offer model.
- A saved action sentence can receive a non-blocking soft reminder prompt, with date/time selectors beneath it. Checklists remain interactive; Q27–Q28 subsequently confirmed a whole-checklist due date that also schedules its reminder.
- Unfinished items are available through Open tasks in Find and through Chat, retaining links to original captures.
- This app owns reminders. Optional Apple/Google Calendar connections and calendar timeboxing are a later direction; the human asked to solve the current problems first. No calendar synchronization or automatic timeboxing is added to current scope.
- Temporary chat can read relevant saved material and saves no new segment content or derived memory.

### Confirmed in round seven — 2026-10-20

- Choosing a checklist due date also schedules its reminder. This interaction counts as accepting reminder creation and must visibly communicate the combined effect; there is no separate optional Remind me toggle.
- The date belongs to the whole checklist. Individual checkbox items have no due dates.

### Confirmed in round eight — 2026-10-20

A date-only choice uses a visible, configurable default time that can be changed before scheduling. Completing every checklist item cancels its pending reminder; any unfinished item keeps it scheduled. After the due reminder, unfinished lists remain overdue in Open tasks. Further timed alerts require explicit rescheduling; Q33 excludes a separate snooze control.

### Confirmed and redirected in round nine — 2026-10-20

- Due reminders also appear in the continuing app chat; the person can ask Chat to reschedule them. WhatsApp/SMS remain optional connected channels.
- Reminder controls are Edit and Remove. A separate Snooze control is excluded; conversational rescheduling edits the reminder.
- Preserve the original time zone and scheduled instant during travel.
- Reopening a completed checklist offers a new reminder without restoring the cancelled one.
- The human asked to begin MVP design and launch by the end of today. Pause detailed interviewing and make the core loop reviewable. Subsequently, the human agreed to the private-pilot recommendation with sync, required both native surfaces today, rejected browser design/delivery, and selected FigCraft. They requested functional greyscale industrial minimalism with no brand exploration.

Environment check at the earlier design kickoff: no app/package existed then; Xcode 26.2 is installed, and `security find-identity -v -p codesigning` returned zero valid identities. This does not establish that native signing can never be configured; native installation cannot yet be claimed. No release route is silently substituted. Selection priorities remain deferred. The platform follow-up supports a compact keyboard-Chat concept for testing but supplies no supported keyboard-to-companion launch. No such handoff is promised.

The UniiChat reference is verified as Victor Taelin's official Apache-2.0 project and creator announcement. Its original-log plus navigable-summary approach informs the chat refinement: history is retained without save prompts, while retrieval preserves attribution and tentative statements. Its server/inference/client arrangement has not been chosen for this product. The source report is pinned to an inspected commit and distinguishes retention from measured recall.

The keyboard is a frequent access surface rather than a guarantee of universal availability. Share-sheet and companion capture cover media and contexts the keyboard cannot support. The PRD records those constraints without choosing a technical stack. Open Design CLI help works, but the default daemon endpoint was unreachable; this draft uses ASCII blueprints and has no Open Design board.

## Earlier design baseline — through 2026-10-02

The sections below preserve the earlier pitch and its reasoning. Where they conflict with the current whole-day direction, the PRD and ticket 20 identify the change. They are not the current complete release specification.

## Where this is going

The destination is a locked product-and-business pitch: the problem that is actually true, what the product does, a day in the life plus a rough interface, and a business in which the person pays, keeps paying, and tells a peer.

Alongside the product vision, maintain an ambitious [MVP scope](../.scratch/scattered-ambitious-pitch/mvp.md). Inclusion requires concrete product decisions settled by the human. Engineering capacity is not a reason to reduce ambition. The scope index records settled commitments and remaining boundaries; it is not yet a complete release specification.

The map is [Scattered ambitious pitch](../.scratch/scattered-ambitious-pitch/map.md). Decisions live on that map's tickets. This file records the shape of the effort, not the pitch itself.

## Who it is for

The audience is the scattered ambitious person, defined in `CONTEXT.md`. The first buyer is the maker: someone whose work is to ideate and then create or publish. The failure that matters is goal neglect. A diagnosis is not required.

The maker pays. Employers, schools, parents, and clinicians are not the buyer.

## What is already decided

- The spine is goal neglect. Intentions stop governing action under the load of many open projects. Many projects and context switching amplify it. Organizing thoughts is compensation. Inability to stay on one thing is downstream.
- The pitch is one product with two moments. Capture takes parallel bursts and the person does not classify. Retrieval has to change the next act. That change happens at the moment of action, when a cue retrieves the intended act. Capture, a related note beside the cursor, and a later review can all leave notes that are never acted on.
- The pitch will include a day in the life and a rough interface.
- Capture requires adjacent writing spaces so a new thought can be opened while another remains unfinished. Related notes during capture are optional and easy to ignore.
- The capture overlay blurs and darkens the background and uses a shortcut to open and dismiss it. Wikilinks are a first-class interaction: select a word or phrase and use a simple hotkey to create a linked dialog. Both belong in the MVP at the level of behavior agreed so far. A wikilink creates an independent note, not a fragment of its parent. A multi-thought block gets an optional split hint. A card shows a backend chunk of the block, and the hint shows the maker the proposed boundary so they can fix it. Accepting or adjusting the hint is Explode, and it is in the MVP. The standalone Explode hotkey is beyond the MVP. Capture in the MVP is typing only; the maker can dictate with their own tool, and native speech capture is later.
- Explode splits a large text block into atomic notes by meaning. In the MVP it happens by accepting the split hint. The standalone hotkey is part of the product vision and outside the MVP.
- Capture preserves separate thoughts and the maker's wording, allowing minor corrections for legibility. It retains a source or draft reference when available; inferred connections remain revisable. These choices are recorded in [What capture must preserve](../.scratch/scattered-ambitious-pitch/issues/10-what-capture-must-preserve.md), whose interaction decisions remain open.
- The first buyer is the maker. They stay because the dump and the point of decision are one product. They tell another maker, and they tell from pride. Passive productivity names the offer: the upkeep is calm, and the start is one click. The piece is made after that.
- The form is a point of decision. A dumped note appears inside an app the maker already has open. One click takes it to a place they chose. There is no home they must remember to open. A rare label correction does not gate that click. The price band is the utility band, about $3 to $12 a month, with a free tier where the maker brings their own API keys. Notes live on the maker's device by default. The paid tier adds cross-device sync and managed AI, so a paying maker needs no keys. The exact price inside the band is open. The list of apps and points of decision is still ahead.
- The effort refuses clinical treatment and a general productivity suite for everyone.
- Decided 2026-10-02: the spine is spontaneity. The maker works from the thought that arrives, with no schedules or timetables. Goal neglect stays as the problem statement for why planned work fails. The founder is the first user and the claim is that solving for self solves for many neurodivergent people. Research on reaching goals without scheduled action is [15-goals-without-planning](../.scratch/scattered-ambitious-pitch/research/15-goals-without-planning.md), with first-principles reasoning to follow.
- Decided 2026-10-02: the product never shows audience reaction (likes, replies, views, counts). It reads whether a piece shipped. The reason is the founder's own failure at the moment of shipping: attention to what others think.
- Decided 2026-10-02: notes tagged private by a small local model are captured and recalled but never turned into prompts and never leave the device. The daily canvas (scrollable earlier days, the day's notes in the background, a central agent-written note) is a browsing view and is never required. The first surfaces are prompts in the X timeline and Substack as the publishing target; GitHub and code come after.
- Decided 2026-10-02: in any text box on the Mac, including chat boxes of coding tools, a related note appears beside the cursor. It is quiet while the maker types, appears when they pause or on a hotkey, and shows at most one card. Clicking it inserts the note's text at the cursor, with a secondary control that opens it as a dialog.
- Stated 2026-10-02, awaiting lock: the one job of the product is that the maker never fears forgetting a thought and the right thoughts come back at the right point in a creative session, with no organizing. Captured thoughts are sorted by background agents into two wikis, a private wiki of the self and a wiki of ideas, where the ideas wiki never links to the self wiki. Pages are told as stories. Capture dialogs are an aid and not the stored structure. A note is not marked posted by a click: the product asks the maker later and reads public surfaces on a cadence to reconcile. The daily canvas's central note is a mirror of the day. The MVP is Mac only.
- Research note 15 (goals without planning) reports that no study tests a schedule-free way for adults with ADHD to finish things, that cue-based and if-then mechanisms have partial support, and that planning-based CBT works on average in adults. It does not decide anything for the product.
- Source for the 2026-10-02 decisions and the unsettled remainder: [Vision capture](VISION-CAPTURE-2026-10-01.md).

## Technical research

[Open-source components for capture, organization, and retrieval](../.scratch/scattered-ambitious-pitch/research/14-open-source-capture-organization-retrieval.md) surveys code we could reuse and a provisional, source-preserving capture schema. It identifies separate starting points for the desktop capture surface, in-page decision cues, and low-cost organization and retrieval. No implementation stack or organization schema has been chosen; the report records what needs a product-specific pilot before those choices.

## Prototype

[Day in the life and rough interface](../.scratch/scattered-ambitious-pitch/prototypes/07-day-and-rough-interface/index.html) is a throwaway single-file prototype for ticket 07. It runs one day across four apps (an X post, a newsletter draft, a chat, a script) and the capture overlay. It offers three versions of the point-of-decision surface: a card at the text cursor, a margin column, and a strip under the text box. It assumes the click inserts the note into the box, which is not settled. Open the file by double-click. The human has not yet reacted, so no version is chosen.

## What is deliberately unset

The exact price inside the band. The list of apps and points of decision is a last pass before the pitch is locked. Venture-scale versus a smaller company, brand, and the objects the product keeps are still fog.

## Caret ownership follow-up — 21 October 2026

Basic routed input passed an earlier human on-screen-key check, but the latest focus/selection acceptance failed. The human reports dual carets initially, host caret visibility while the private note is selected, and word selection/replacement menus on ordinary taps. Selecting App does hide the private caret in their latest report. This does not satisfy the requested single moving caret across surfaces. The host draws its own caret; the reviewed public keyboard proxy has no API to hide/style it. A single caret across arbitrary host apps therefore remains unsupported by the current extension architecture, not a completed feature.

The geometry suppression for the private caret during App routing remains. A previous custom hold/edit-menu gate failed acceptance and is removed from the next candidate. Screenshots show “No Replacements Found”; Apple's text-input-traits documentation describes single-tap spelling corrections, which are separate from ordinary copy/paste edit menus. The next candidate disables native spell checking and autocorrection only in the private editor, retaining UIKit's native selection and copy/paste menus. This keeps fragments and search queries as authored. It compiles and is now installed; private tap/menu acceptance remains pending.

With Apple's keyboard selected, CUA host activation also selected the test word and opened a menu; AX activation is not proof of an equivalent human single tap. The human baseline screenshots show a spelling/autocorrection suggestion popup in the host while our keyboard is inactive. The software keyboard was hidden by Simulator hardware-input mode; Command–K made Apple’s software keyboard visibly open before continuing. This establishes host spelling UI outside our extension, not universal simulator/real-device tap behavior. A decision about accepting the dormant host caret for the keyboard MVP is pending. Do not alter the companion's caret/menus to mask third-party-host limits, and do not close ticket 02 or claim launch until the behavior and any required product compromise are explicit.

## Editor acceptance and reminders — 21 October 2026

The human accepted the installed spelling-isolation editor as working and explicitly chose to keep the keyboard with the dormant host caret visible. Ticket 02 is resolved using prior tests/builds/reviews and this native acceptance. No further cursor testing is requested. Ticket 03 is claimed for interactive checklists, whole-list accepted reminders, Edit/Remove controls, due Chat events and distinct system-notification status. The original typing destination/draft preservation and privacy decisions remain in force.

## Checklist and reminder implementation — ticket 03

The native original reader now exposes explicit checklist items as completion controls; original text/RTF remains unchanged. Find has an Open tasks filter, and incomplete overdue checklists remain there. The keyboard presents the same operations inside its workspace, including a whole-capture date/time wheel that temporarily replaces keys. Draft state is retained while the date is chosen. Mac/companion use native date controls with the stored zone shown. A post-save reminder offer does not block a new capture; completed lists and ordinary notes cannot inherit an earlier offer.

One capture has one current accepted commitment. Accepting a revised date edits it; cancelled history remains, and a new acceptance after reopening a cancelled list creates a fresh reminder. Completed checklists reject new/edit scheduling until reopened. Completing every item cancels pending reminders, while reopening offers a new date without restoring an old alert. A persisted optional default clock preference starts at 09:00 and is applied in the displayed zone; edits retain the existing reminder's zone. Due reconciliation appends one reminder-role Chat event per accepted occurrence. Removing a reminder preserves its source.

`DeviceReminders` is the OS adapter behind `VaultModel`. It uses revision-specific local-notification identifiers, rereads coordinated storage around asynchronous adds, removes stale/cancelled requests without cancelling a newer revision, and checks the OS pending list. A due Chat event does not cancel an accepted OS request that is about to display. Neutral notification content keeps source details in the vault. Device scheduling status is separate from saved commitment and actual delivery; disabled permissions and scheduling failure remain visible. Permission is an explicit companion/Mac action; a keyboard cannot present that prompt. Foreground presentation uses a process-lifetime delegate installed only by the iPhone/Mac app entry points; the keyboard never sets that application-only delegate. Startup/foreground reload reconciles due Chat events and OS schedules; a 15-second foreground timer is not a claim of background execution.

Five failing-first behavior cycles cover one active reminder after file reopen, persisted default time in a chosen zone, eligible latest-capture offers, completed-list scheduling/reopening, and stale-offer removal after local/external completion. They use the approved saved-vault/public presentation boundary and disable the OS boundary in those tests. Native build, visual checks and actual OS scheduling/delivery are separate checks; ticket 03 remains claimed while verification runs.

Review fixes place long-list controls inside the original reader scroll view and make settings scrollable. Completing or refreshing a completed offered list clears its prompt; reopening offers a fresh acceptance. Keyboard date controls are disabled during save, and returning from a date form restores the actual original reader rather than its Find query.

Native verification on 21 October exercised Mac checklist save, Open tasks, accepted date/zone, edit, completion cancellation, reopening/new offer and removal preserving the original. Companion reminder acceptance/edit and keyboard Expanded/date editor/Cancel/overdue/due Chat were observed. The simulator delivered a neutral OS banner at 21:07 while the companion was backgrounded, separately proving one actual OS delivery. Mac notification authorization required a signed bundle installed in the user's Applications folder plus its app-specific system notification toggle; the installed app then reported a pending request. Real iPhone behavior, cross-device delivery and release signing remain separate gates.

## Consumer backend and Mac launcher revision — 22 October 2026

The human now wants the Mac hotkey to open a compact Find bar with results while typing, preferably beside the current text field. This overrides Capture-by-default on Mac only; the iPhone keyboard still opens Capture. Consumer screens must not require Ollama/server/model configuration. Search, storage, sync and assistant behavior remain separate modules, with original preservation, optional cloud AI and provider-unreadable sync retained.

Source inspection confirmed that current Find recomputes every document embedding on the UI actor per query, while local persistence is plaintext coordinated JSON and encrypted sync is unimplemented. The [measured current baseline](verification/search-baseline-2026-10-22.md) records Release samples around 0.82–0.89 seconds for 100 synthetic captures and 8.71–8.98 seconds for 1,000; these are single-host characterization samples, not real-device percentiles or quality validation.

The [proposed execution plan](../.scratch/native-mvp/plans/consumer-backend-2026-10-22.md) covers protected local capture/indexed Find, precomputed semantic retrieval, a compact Mac launcher, consumer-ready remembered chat and encrypted per-record sync. The human requested [state-machine walkthroughs](design/consumer-state-machines.md) before approving the revised ticket breakdown; no new tickets are published or claimed. Existing incomplete tickets retain their status. The walkthrough is a blueprint and changes no app permissions/data.

Primary-source reports cover [retrieval](research/2026-10-22-fast-private-retrieval.md), [privacy/sync/current security advisories](research/2026-10-22-private-sync-security.md), and [keyboard/launcher reuse](research/2026-10-22-keyboard-launcher-reuse.md). FTS5/BM25 plus precomputed vectors is the proposed retrieval path. RustCast is retired; SnipKey's MIT key plane merits an isolated compatibility/typing pilot, preserving the accepted keyboard workspace/routing. No upstream code or dependency has been adopted. Encryption/library/key-recovery decisions remain executable-pilot and review gates; no security certification or sync-speed claim is established.

### Reuse-first investigation — 22 October 2026

The human specifically requested reusable search/sync engines and keyboard/hotkey clients, including Omnisearch's underlying library. The [reuse recommendation](research/2026-10-22-reuse-first-recommendation.md) compares licensed components and records the remaining custom integration. Omnisearch uses MiniSearch; its MIT library can run through JavaScriptCore without importing the GPL Obsidian plugin. The isolated [native probe](verification/minisearch-native-probe-2026-10-22.md) passed exact/prefix/typo/Hindi literal retrieval plus serialization/deletion. A 10k synthetic timed run had query p95 about 0.12–3.81 ms for successful queries, with about 95 MiB whole-process peak RSS including duplicate indexes/fixtures. No actual keyboard, diverse-corpus quality or end-to-end latency claim follows. MiniSearch is now a lexical comparison candidate alongside FTS5; semantic encoding remains a separate adapter.

Point-Free SQLiteData is the leading proposed CloudKit-wrapper pilot. Current main needs Swift 6.4, above the installed 6.2.3, and its per-column last-edit-wins policy cannot guarantee preservation of concurrent originals. Before adoption, test a compatible revision, protected local store plus syncable app ciphertext, recoverable content revisions, key lifecycle, deletion and companion/extension coordination. Direct CKSyncEngine remains the fallback. Automerge, PowerSync, Electric and cr-sqlite solve other portions with additional integration/operational requirements. No encrypted sync is implemented by this research.

SnipKey remains the proposed selective iPhone key-plane pilot; Noty/Maccy/KeyboardShortcuts provide Mac interaction sources. Additional Jev Jarvis inspection found a reply-candidate keyboard with full QWERTY/knowledge base on its roadmap. Diction's public repository supplies its gateway, without establishing reusable iOS client source. No reviewed project was verified to cover the full product. Keep current routing, rich pad, drafts/sizing and reminders. Only an isolated benchmark source and documentation changed; production dependencies, behavior and ticket statuses remain unchanged. The revised execution plan still awaits approval after the requested walkthrough.

### Core-memory MVP and persistent entry — 22 October 2026

The human's latest priority is capture and recall from the current activity, optimized for speed, familiarity and convenience. The [core MVP document](MVP-CORE.md) records jobs, keyboard/Mac sketches, resident-storage behavior, both-direction keyboard-only sync acceptance and proposed release boundaries. No app/workspace visit or categorization should be required for ordinary capture/refind. The Mac entry is now a persistent movable floating/edge control opening an anchored Capture/Find panel; existing hotkey access is complementary. The proposed deferral of remembered Chat, reminders and resurfacing remains pending the explicit scope answer. Image/voice inclusion and visual-search acceptance are still explicit scope decisions, without silently dropping them.

[Grammarly/client research](research/2026-10-22-grammarly-form-factor-reuse.md) confirms Grammarly's proprietary clients and documents its keyboard plus Mac widget/tab interaction. EdgeNoted's MIT windowing code supplies a source-inspected expandable native panel and README-described persistent edge strip; arbitrary draggable anchoring remains an adaptation and runtime check. ILoveNotch is a secondary pill reference. SnipKey remains the first typing-layer pilot, preserving existing routing/drafts/editor behavior. No client's claims establish universal keyboard/overlay availability or Apple typing parity.

[Resident sync research](research/2026-10-22-local-resident-sync-mvp.md) distinguishes CloudKit record exchange with local SQLite from iCloud Drive file eviction. SQLiteData 1.12.1 has an older-toolchain manifest, refining the earlier main-branch compiler concern. However, app-only lifecycle calls, connection-local tracking triggers and default account-change deletion require explicit extension/residency checks. PowerSync Swift is a non-iCloud alternative with experimental multi-process constraints; companion-only networking cannot satisfy the product if keyboard captures wait for an app visit. Neither has passed real-device replication. Compare an app-owned outbox with CKSyncEngine against an extension-compatible service adapter using the same ciphertext boundary. Privacy/key/recovery and local-protection promises are retained.

[Multimodal research](research/2026-10-22-multimodal-memory-search.md) verifies MiniSearch's BM25+ algorithm. OCR/caption indexing can return image sources through words; visual meaning requires compatible image/text encoders. UForm supplies Apache-2.0 Swift/Core ML encoder code and an Apache-2.0 English-small checkpoint worth testing, while Queryable supplies MIT photo-indexing patterns. MobileCLIP code and weight licences differ; no weights are selected for shipping. Provision assets and precompute derived representations without blocking capture; measure the query encoder inside the actual keyboard before promising semantic image Find. No new production behavior or dependency was implemented in this refinement.

### Approved core scope and floating UI assessment — 23 October 2026

The human approved Capture → Find → reuse with the iPhone keyboard, Mac floating control, resident offline copies and private sync. Chat, reminders and resurfacing are later-release work; existing code and incomplete evidence remain preserved. Image/voice acceptance is still explicit scope work. Scope approval does not select a model/transport or approve the old technical ticket breakdown unchanged. The implementation spec and product documents now point to MVP-CORE as the current release boundary.

The human challenged the narrow low-adoption shortlist and clarified that only the UI form factor matters: a persistent draggable collapsed control, remembered position and an editable panel expanding from that anchor. They explicitly allow building our own component if available code does not fit. The [broader UI donor survey](research/2026-10-23-floating-client-candidates.md) verifies substantially adopted sources: Handy 34,365 stars, OpenWhispr 9,761 and native VoiceInk 6,900 on the checked date. Their surrounding product features are outside the evaluation. Source checks distinguish transient overlays, unproven idle permanence, persisted geometry and editable focus. [Overlay/library assessment](research/2026-10-23-floating-overlay-libraries.md) includes Wisp controllers, Boring Notch and tauri-nspanel, with exact mismatches.

The recommended implementation direction is a small native AppKit component behind our existing Capture/Find content interface. HuggingChat's Apache-2.0 FloatingPanel and permissively licensed orb/geometry controllers provide extraction candidates; copying GPL files requires a deliberate distribution choice. No full candidate was verified to provide every required behavior unchanged. Reuse only the code that survives fit/licence/resource review; otherwise implement the bounded component. Do not migrate the app to Electron/Tauri solely for window chrome or import unrelated recording, capture, provider or account logic. No panel extraction or runtime UI test occurred in this pass.

[UForm resource assessment](research/2026-10-23-uform-resource-budget.md) refines the earlier size claim: neural-optimized image/text packages plus metadata total 61.121 MB, while the optimized query-only subset is 38.803 MB. Default convenience constructors select ordinary artifacts totaling 239.411 MB for the pair. Downloaded bytes differ from compiled disk size, linked SDK overhead, runtime memory and cold latency; those remain unmeasured. The Swift path uses native Core ML and needs no Python/PyTorch runtime. Keep image inference optional until media scope and real keyboard budgets are established, with no loading on the typing/save/initial-results path. No model or dependency was added to the app.

### Mac floating pill — 23 October 2026

The Mac entry is a persistent pill that expands into a Capture / Find panel. Clicking it or pressing Control–Option–Space opens the panel; Esc, the × button, clicking another app or pressing the hotkey again collapses it. The app runs as an accessory process (no Dock icon). A menu-bar item offers Open, Hide/Show pill and Quit; the pill's right-click menu offers the same. The old titled hotkey panel is removed.

**Window.** One borderless non-activating `NSPanel` (`Apps/Mac/PillPanel.swift`) changes size between the 60×28 pt pill and the 540×440 pt panel, so there is no window swap and no flicker. It sits at status-bar level, joins all Spaces and is full-screen auxiliary. The collapsed pill cannot become key, so clicking it does not take focus from the app underneath. The panel becomes key without activating the app; Esc is handled in `sendEvent`, and Cmd-1/Cmd-2 and the edit shortcuts in `performKeyEquivalent`, because the app is never active. On collapse the panel gives up key status by ordering out and back in.

**Content.** `PillRootView` holds a blurred rounded background, the pill glyph, the click/drag handle and the SwiftUI panel (`PillPanelView`). The panel is laid out once at its final size and pinned to the top-left, and the window frame animates around it while the glyph and content crossfade. `WorkspaceView` is embedded with the new `showsHeader: false` parameter (default true, so other callers are unchanged). The pill draws its own tabs: Capture ⌘1, Find ⌘2 and a dashed, disabled "Soon" slot marked `PLACEHOLDER` in code for the third mode. Chat and settings are not reachable from the pill. Expanding always opens Capture and keeps all drafts in `VaultModel`; after a tab change the caret is placed in the note editor or the query field (`PillFocus`). The pill mirrors `VaultModel.mode` both ways, so "Back to Find" inside the reader switches the tab.

**Pure logic** lives in the separate package `native/Pill` (`MindMachinePill`), run by `swift test --package-path native/Pill`:

- `PillState`: events (click, hotkey, Esc, click away, select mode, close, toggle visibility) to phase `collapsed | expanded(mode)` plus the Show/Hide preference. Selecting the reserved mode, or any mode while collapsed, is a no-op. The hotkey still opens the panel while the pill is hidden and returns to hidden on close.
- `PillGeometry`: default position (bottom centre above the Dock); restoring a stored centre (clamped into the usable area, or the default when its display is gone, re-resolved when displays change so the pill returns when the monitor does); expansion centred on the pill, growing up from a pill in the lower half and down from one in the upper half, clamped to the display; collapse re-applies the pill's offset inside the panel, so a panel the user dragged takes the pill with it.
- `PillDrag`: a 4 pt movement threshold separates click from drag; the window origin is derived from the absolute cursor each event.
- `PillPreferences`: pill centre and Show/Hide in `UserDefaults`.
- `PillMotion`: expand 180 ms, collapse 140 ms, tab highlight 100 ms; 0 when Reduce Motion is on.

**Lifted code** (notices in `THIRD_PARTY_NOTICES.md`, attribution in each file header; nothing GPL): from Wisp (MIT, commit 1e86359) the clamp function, default placement, fall-back when the stored display is gone, cursor-pinned dragging and panel level/collection behaviour; from Pindrop (MIT, commit 8044a15) the 4 pt click-versus-drag distance; from HuggingChat for macOS (Apache-2.0, commit 7d13a41) the non-activating floating panel recipe. OpenWhispr, Handy and VoiceInk were read for behaviour only. Wisp's island/panel controllers were not copied wholesale: they are tied to its screenshot flow and keep separate island and panel positions, whereas here one window and one stored position serve both.

**Verification.** The `mac-build` CI job launches the built app with `--pill-selftest` (`Apps/Mac/PillSelfTest.swift`) against a temporary vault and an isolated defaults suite. It checks the window flags, expand, focus placement, typing into both modes, Cmd-1/Cmd-2, Esc, click-away, hotkey toggling, hide/show, drag with persistence, intermediate animation frames, Reduce Motion, 20-cycle timings and idle CPU, and uploads PNG snapshots and `result.json`. The GitHub macOS runner has Reduce Motion enabled, so the self-test forces it off for the animation checks. Measured on the runner (run 39910206208, Reduce Motion forced off, includes completion-callback latency): expand median 200 ms and collapse median 167 ms over 20 cycles (configured animations 180 ms and 140 ms), first expand 275 ms, caret in the note editor immediately and in the Find field about 170 ms after Cmd-2, idle CPU 0.03 %, resident memory 97 MB. These come from a shared VM with one display, not from the founder's Mac. Not covered by CI: a real keyboard/mouse session, the Carbon hotkey firing, focus returning to a specific host app, full-screen apps and multiple Spaces, and multiple displays. The runner has one display.

### Durable indexed core — 23 October 2026

`VaultFile` now uses system SQLite (public domain) through a SwiftPM C module. Its legacy JSON URL identifies an untouched migration source; a sibling `.sqlite` database is initialized in one transaction only after successful decoding. Existing metadata, rich text, checklist IDs and originals survive. WAL, FULL synchronous commits and Apple fullfsync place confirmation after the durable commit. The capture-specific append path avoids decoding/re-encoding the entire vault. General reminder/checklist mutations retain the compatible Vault API and reindex only changed sources.

FTS5 provides a disk-backed bounded-cache index, Unicode tokenization, prefix indexes, BM25 ordering and match delimiters. An indexed one-deletion vocabulary supplies bounded one-edit/transposition alternatives; query words are intersected. Results load at most 30 originals. The UI no longer loads NLEmbedding or computes all corpus vectors during typing. Semantic/paraphrase retrieval remains a gap. SQLite shares its transaction with immutable pending source revisions; JSON remains a recovery source and must not be edited after migration. Data protection covers iOS database/WAL/SHM after first unlock. App-side encryption and account isolation are separate sync responsibilities.

### Private replication and signing — 23 October 2026

`NoteRevision` is immutable and records parent revision IDs. `VaultFile` queues changes in the same SQLite transaction as the source/index. Merge keeps concurrent head revisions as deterministic original copies, and persistent tombstones dominate stale data. Deferred reminder/chat metadata stays local. `RevisionCipher` authenticates each revision using AES-256-GCM with a versioned context. A shared 256-bit key is installed explicitly through `PrivateSyncSetupView`; synchronizable Keychain with a shared access group supplies the app/keyboard and signed Mac. Create once and pair the same recovery key on the other device; never auto-create independent keys during startup. Losing all copies loses cloud decryption; retain a private recovery copy.

`PrivateCloudSync` uses CKSyncEngine (iOS 17/macOS 14 baseline) and the private database/custom zone. Only the app ciphertext is put in `CKRecord.encryptedValues["sealedRevision"]`, retaining service-unreadable content independently of Advanced Data Protection. User record identity binds to the resident vault before exchange; sign-out/account switch pauses and never erases/reuploads into another account. Per-client engine cursors share a durable revision outbox, with authenticated duplicate-upload acknowledgement. Cloud/decryption failures retain pending writes and local originals. Corrupt incoming data stops cursor advancement. Active clients request foreground sync on startup, commits and the periodic timer; keyboard background lifetime is OS-controlled and no background deadline is promised.

`Config/MindMachine.xcconfig` centralizes Team ID, the three bundle IDs, App Group, CloudKit container and shared Keychain group. The generated project references it for all configurations and unsigned CI overrides signing. Existing signed installations under the former App Group need an explicit export/copy before replacement; a new App Group cannot read another group's sandbox. See TESTING-TONIGHT for signing, pairing and live-device acceptance.

Keyboard Find now refreshes 25ms after query changes, cancels superseded refreshes and renders one bounded highlighted result page. Capture/Find are its release tabs; deferred Chat code remains. The keyboard model loads 100 recent originals and fetches inspected results by ID. It does not load neural models or a whole in-memory text index. `ProcessMemory` samples actual Mach physical footprint and OS-provided available memory; the extension records a report in the App Group and companion setup displays it. Memory warnings discard result views. A simulator/CI process measurement does not establish a signed iPhone memory limit or typing feel.

The initial 10k benchmark failed the required budget (query p95 20.40ms, save p95 7.32ms, whole test-process peak RSS 50.16MiB). FTS5 optimized `ORDER BY rank` replaces scalar-BM25 sorting; known indexed prefixes skip fuzzy dictionary expansion. Typo fallback remains one edit/transposition when the typed prefix has no vocabulary match. The threshold is unchanged.

The CI process-level probe uses the real `VaultFile` executable boundary: terminate with SIGKILL after stdout acknowledges forty committed captures, reopen and compare those literal originals, then run two processes appending 100 notes each. Account binding is also a SQLite transaction. The iOS-only OS headroom API is availability-gated; macOS reports physical footprint without inventing an extension budget.

Conflict result IDs now map to their specific logical note/head revision in SQLite. Editing a displayed conflict advances that branch alone, retaining the other original even if an old parent arrives afterward. First-SQLite-pilot stores rebuild this derived projection map transactionally. Reminder reconciliation loads only reminder-linked originals rather than pulling the full corpus into the keyboard. Sync drains bounded batches with newest pending revisions first, allowing new captures to reach the other device during initial backfill; pending writes keep a visible pending status.

CI now also runs an integrity-pinned MiniSearch 7.1.0/JavaScriptCore comparison using the same 10k text corpus, queries and 30-result page as FTS5 in separate processes. The MIT bundle stays in the runner temporary directory, with SHA-512 tarball and SHA-256 UMD verification; no npm scripts or production JavaScript dependency are introduced. Separate process measurements avoid counting duplicated serialized indexes in the earlier research probe.
