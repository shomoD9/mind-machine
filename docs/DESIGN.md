# Design

This project is defining a headless second brain: capture without filing, then find and reuse saved material inside the apps the person already uses. The human has authorized MVP design and a launch attempt on 20 October 2026. The repository now contains an editable FigCraft native MVP design. The human approved a private pilot with sync and requires native iPhone keyboard plus Mac hotkey today. Browser fallback is rejected. The human explicitly authorized starting the native build after design review, including both UI and supporting behavior. The existing core is the baseline; new engineering work is routing through the requested ask-matt stack. Installation, sync and release are not yet verified. See [MVP launch design](MVP.md) for today’s proposed slice and release decisions.

## Native implementation workflow — 2026-10-20

The human approved the Matt Pocock engineering setup, three public test boundaries and eight vertical slices. Root `AGENTS.md` routes tracker/domain guidance through `docs/agents/`. The authoritative native build spec is `.scratch/native-mvp/spec.md`; separate tickets live under `.scratch/native-mvp/issues/`. Ticket 01 is resolved; ticket 02 is claimed. Review compares against c319917 and includes pending changes. Tests exercise keyboard workspace state, saved-vault behavior and encrypted two-vault replication; actual host/device behavior needs separate native evidence. Resurfacing selection remains decision-blocked.

## Native capture/refind architecture

The local Swift package supplies domain records, coordinated JSON persistence, retrieval and observable presentation. A generated, committed Xcode project links those libraries into three targets. The Mac AppKit adapter registers Control–Option–Space through Carbon and hosts the shared SwiftUI workspace in a floating resizable panel; Escape hides the panel without replacing its model. The companion provides scrolling setup content and a bottom safe-area composer. This representative host keeps its composer directly above the entire keyboard workspace as the extension grows; setup content scrolls away first. The keyboard controller owns a private UIKit editor and custom keyplane, routes deliberate host input through `textDocumentProxy`, and exposes original inspection with explicit Insert. Initial typing support is basic English keys, shift, digits/punctuation, delete, return and keyboard switching; Apple parity is not established.

Phone targets resolve the same entitled App Group URL before constructing the model. The keyboard requires Full Access and refuses an isolated fallback vault if sharing is unavailable. App Groups share a file on one device; cross-device sync is still unimplemented. Ordinary host typing is never appended as a capture. Save confirmation follows a coordinated atomic update; Find returns complete original text. The pure saved-vault test reopens storage using another caller before querying it. A separate public workspace regression test proves that activation selects Capture and preserves Capture/Find/Chat drafts. Both native adapters invoke that shared activation operation. The domain owns lexical/ranking logic; the platform model supplies optional local semantic scores, so keyboard and panel use one retrieval path. Shared views also expose the existing preliminary inference adapter, but chat retention/search/Forget and reminder controls have not met their tickets yet.

All three targets compiled with Xcode 26.2. Ticket 01 passed its ten-test checkpoint and independent reviews; the human then confirmed keyboard capture/Find/original/Insert and the real Mac global hotkey. The ticket is resolved. Mac builds use an explicit arm64 destination. The installed simulator runtime is iOS 17.5; target-based SDK compilation succeeds despite scheme-destination selection failing. The app installed and launched in the iOS 17.5 simulator. The unsigned build correctly reported unavailable sharing; an ad-hoc-signed simulator build then registered its App Group and rendered the setup/test-host screen without that error. After the Mac was unlocked, native save/Find/original checks passed on Mac and companion; the human confirmed the real Mac global hotkey. The keyboard is enabled and renders after standard bundle metadata completion and a discovery refresh, with simulator-only Full Access explicitly authorized. The corrected test-host composer is visible above the workspace. The human confirmed the complete custom-key capture/Find/original/Insert path after simulator automation returned noWindowsAvailable on those controls. Human ticket-02 checks passed sizing/selection preservation and formatted save/reopen. The reported tap failure was reproduced and corrected. On 21 October the human confirmed on-screen-key routing in the simulator test host; broader native verification remains open. No real-device installation or synced launch is claimed.

## Pad sizing and visual editing — implementation in progress

Ticket 01 is resolved after the human confirmed the simulator keyboard capture → Find → original → Insert path, with the host field untouched until Insert. Mac and companion UI checks, the real global shortcut, builds, tests and two review axes were already complete. Ticket 02 is claimed; ticket 06 is unblocked and unclaimed.

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

### Host composer and focus correction — 2026-10-20

The human pointed out that the mock host composer should move with the keyboard workspace. The generator now anchors it above the full extension at each size, rather than at one fixed screen coordinate; the expanded example keeps the composer visible while its conversation viewport shrinks. This is a representative host layout, not authority to control another app’s composer.

Tap-host-to-type-in-host and tap-note-to-type-in-note are the desired interaction. Initial Capture selects Note; size changes preserve whichever destination is active. The new Typing destination page shows both carets/drafts and an active-field indication. The indicator is tappable as a proposed fallback because callbacks do not guarantee every unchanged-caret host tap. A first-responder solution remains plausible and untested. No new native feature implementation occurred during this correction. [Research](../.scratch/scattered-ambitious-pitch/research/25-keyboard-focus-and-host-layout-2026-10-20.md).

### Engineering workflow requested — 2026-10-20

The human requested the local ask-matt skill stack and approved its setup on 2026-10-20. The route for this native build is setup → spec → vertical tickets → implement/TDD → Standards/Spec review. Root AGENTS.md and docs/agents now configure the retained local Markdown tracker, default triage labels and single domain context.

The [engineering plan](../.scratch/native-mvp/review-plan.md), [published build spec](../.scratch/native-mvp/spec.md), three public test boundaries and eight individual tickets are approved. Review baseline is c319917. Ticket 01 is resolved after saved-vault/workspace tests and native/human acceptance; ticket 02 is claimed. Native runtime evidence and two independent review axes are recorded separately from test approval.

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

Routing passes the human's on-screen-key test. Both host and note carets can remain visible while Private note is selected. The keyboard owns and hides its private caret during App routing; CUA verified that transition. The host draws its own caret, and the reviewed public proxy API has no visibility/styling control for it. This remains a visual limitation of the current responder arrangement. Resigning the private editor previously switched back to Apple's keyboard, so that experiment was rejected. The human confirmed the private caret also remains visible during App routing and supplied a screenshot with both edit menus open. A candidate now hides private caret/selection geometry as well as tint during App routing, deactivates public selection display interactions, and dismisses owned edit-menu interactions. Private simple taps suppress collapsed-caret menus; deliberate hold or selected text retains editing menus. This candidate compiles and is installed; native visual/hold/routing acceptance is pending. The host app still owns its own caret and menu. Do not claim single-caret behavior across arbitrary host apps.
