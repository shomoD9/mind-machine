# Design

This project is defining a headless second brain: capture without filing, then find and reuse saved material inside the apps the person already uses. Product and UX design are in progress; no app has been implemented.

## Current research and requirements effort — 2026-10-19

The human's latest direction is a **headless second brain**: capture thoughts, reflections, memories, tasks, lists, events, reminders, links, pictures, and voice without filing them, then retrieve them through simple, strong search. Everyday access lives in a secondary iPhone keyboard with Capture/Find/Chat and a Mac hotkey surface. A continuing remembered chat and external LLM access use the same vault; Temporary chat segments are excluded from retained memory.

This session is producing evidence and a draft product requirements document before implementation. The latest brief and interview answers take precedence over the earlier scope; decisions and remaining boundaries are recorded explicitly. Earlier sections below remain a historical record. Mac-only, typing-only, maker/publishing-only, and the two-wiki proposal are not the current release specification; natural resurfacing now explicitly includes feed encounters.

The decision frontier is recorded through selectable interview questions. Research covers firsthand public discussions, first-party alternatives, and Apple platform constraints. Product recommendations stay visibly provisional until the human answers and confirms shared understanding. No implementation stack has been selected.

### Current documents

- [PRD](PRD.md): current vision, jobs to be done, proposed acceptance examples, rough ASCII blueprints, platform constraints, and open decisions.
- [UX journeys](UX.md): keyboard capture/search, feed/new-tab/message encounters, continuous chat, and the selected browser-based phone journey.
- [Research synthesis](RESEARCH-2026-10-19.md): findings, counterevidence, coverage limits, and links to seven detailed reports, including direct X, UniiChat, and resurfacing-surface follow-ups.
- [Private sync and optional AI decision](adr/0001-private-sync-and-optional-cloud-ai.md): the accepted privacy contract, with implementation unchosen.
- [Headless second brain decision ticket](../.scratch/scattered-ambitious-pitch/issues/20-headless-second-brain.md): design tree and interview answers. It remains claimed until the product decisions are complete.
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
- A saved action sentence can receive a non-blocking soft reminder prompt, with date/time selectors beneath it. Checklists remain interactive; a due-date offer is proposed, with date-versus-alert and list-versus-item scope still Q27–Q28.
- Unfinished items are available through Open tasks in Find and through Chat, retaining links to original captures.
- This app owns reminders. Optional Apple/Google Calendar connections and calendar timeboxing are a later direction; the human asked to solve the current problems first. No calendar synchronization or automatic timeboxing is added to current scope.
- Temporary chat can read relevant saved material and saves no new segment content or derived memory.

The current questions are Q27 due date versus alert and Q28 checklist date scope. Selection priorities remain deferred. The platform follow-up supports a compact keyboard-Chat concept for testing but supplies no supported keyboard-to-companion launch. No such handoff is promised.

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
