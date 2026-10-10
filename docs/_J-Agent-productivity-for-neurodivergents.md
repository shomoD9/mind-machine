# Agent journal — productivity-for-neurodivergents

## 2026-10-02

### Sonnet 5.5 - Claude Code Desktop

Recorded the human's answers to the first grilling round in `docs/VISION-CAPTURE-2026-10-01.md`. They rejected the offered core idea ("a note is an open loop until it ships") and named spontaneity as the core: no plans or timetables, thoughts written down on arrival, easy posting, easy recall, prompts while scrolling. They described the shipping failure they want to design around (fear of audience reaction, people-pleasing, cue overload). Settled: private notes are never prompted; the canvas is a browsing view and never required; X and Substack first, plus retrieval beside the cursor in any text box. Nothing was moved into CONTEXT.md, DESIGN.md, or tickets yet, because the spine (spontaneity versus goal neglect) is still being reconciled. Next round asks how the spine reconciles, what the product does at the shipping moment, what triggers retrieval beside the cursor, and what the click does in a generic text box.

Second round: the human settled that spontaneity is the spine and goal neglect is the problem statement, that the product never shows audience reaction, that cursor retrieval is quiet and appears on a pause or hotkey, and that the click inserts the note's text. Added Spontaneity and Ship to CONTEXT.md and adjusted the Goal neglect entry. Added the decisions to DESIGN.md and five rows to the MVP index's settled table. The human asked for research on reaching goals without scheduled action, using the repo's research skill. Launched a background agent to write `.scratch/scattered-ambitious-pitch/research/15-goals-without-planning.md` from primary sources, with a section on what the literature does not answer. The first-principles reasoning is left for the human and me to do after it reports.

Third round: the human rejected the note-state options and restated the product's one job at length: never forget a thought and recall the right ones at the right point, with no organizing. They described two wikis (self, ideas) with a one-way link, background agents that sort ideas and write pages as stories, a search box beside the cursor with drill-down to related notes, feed prompts on X and YouTube, letters from worker agents, and later reconciliation against public surfaces. They chose a mirror of the day for the canvas's central note and Mac only. Recorded all of it in `docs/VISION-CAPTURE-2026-10-01.md`, DESIGN.md, and the MVP index, marked as awaiting lock because the core wording is not yet confirmed. The research agent finished note 15 (about 10,000 words); I checked that the file exists and its section headings match the agent's report, and did not read the full text. Next: confirm the core sentence, resolve private notes versus cloud models, wiki pages versus the maker's wording, and the one-card rule versus the search box.

## 2026-10-01

### Sonnet 5.5 - Claude Code Desktop

Started a grilling session after the human restated the vision (tool for thinking; capture and retrieve anywhere; publishing as the point of retrieval; X-feed prompts with Substack deep links; private versus public notes; Write_On and Noterepo as note surfaces). Read CONTEXT.md, DESIGN.md, the journal, the map, and the MVP index to find where the new statements agree or conflict with settled decisions. Fetched the Noterepo page; fetched the text of Jason Fried's Write_On post in the browser pane (WebFetch returned 402). The video cannot be viewed by me. Saved the full message, regrouped by topic with a list of tensions against settled decisions, in `docs/VISION-CAPTURE-2026-10-01.md`. No decision was settled or changed. Next: the first grilling round on the core idea, private notes, whether a daily canvas is a home, and the MVP publishing and surface scope.

## 2026-09-30

### Sonnet 5.5 - Claude Code Desktop

Closed Which price band at the human's request and started the prototype for Day in the life and rough interface. The question is what the interface should look like, so I used the UI prototype branch as a new page, since no app exists to host it. Built one HTML file at `.scratch/scattered-ambitious-pitch/prototypes/07-day-and-rough-interface/index.html` with a four-moment day, the settled capture behaviors, and three structurally different versions of the point-of-decision surface. Ran it in the browser pane: no console errors, and the cue, the click, the split hint, the wikilink, and closing capture all behave. Fixed a stop-word gap that let "because" count as a shared idea and a low-contrast key label in the overlay. Recorded the prototype in ticket 07 and DESIGN.md. Ticket 07 stays claimed until the human reacts.

## 2026-09-29

### Sonnet 5.5 - Claude Code Desktop

Resumed the grilling on What capture must preserve after reading CONTEXT.md, DESIGN.md, the journal, the map, the MVP index, and tickets 10, 12, and 13. Asked the two open capture boundaries plus where the human's four pasted issues (Editor agent design, Newspaper psychology and Page themes, AI Jargon dictionary, Newspaper surface and layout) belong. The human dropped the four issues as belonging to an adjacent project, so nothing was recorded for them. They settled that a wikilink creates an independent note, and that a multi-thought block gets a split hint. They challenged the case for Explode at capture, since the backend chunks captures by idea space anyway; that case is still open. Recorded the independent-note decision in CONTEXT.md, DESIGN.md, the MVP index, and ticket 10. No ticket was closed.

Second round: the human accepted that a card shows a backend chunk with a visible split hint, and that the MVP captures typing only, since makers already dictate with their own tools. They floated a retrieval surface that travels with the keyboard or mouse cursor, which would justify native speech later. Recorded the chunk, the hint, and the speech boundary in ticket 10, the MVP index, and DESIGN.md. Kept the cursor idea out of the settled record as a direction for Last pass on passive cues, at the human's request not to branch the model from it.

Third round: the human admitted Explode to the MVP only as accepting or adjusting the split hint, and kept the standalone hotkey beyond it. They confirmed the cursor-following point of decision is an open direction, and restated the job: the place where the maker types acts as a search box over their dumped notes. Updated CONTEXT.md, DESIGN.md, the MVP index, and tickets 10 and 13. The human confirmed ticket 10 can close. Closed it, added its resolution to the map's Decisions so far, and claimed Which price band, whose blocker (Form of the creation session) is closed. The human chose the utility band and a free tier where the maker brings their own API keys, with cross-device sync and managed services in the paid tier. Recorded it in ticket 12 and DESIGN.md. The human then confirmed that notes live on the device by default with paid sync, and that the paid tier includes managed AI. Recorded both in ticket 12, the map, and DESIGN.md, and removed the cross-surface question from the map's unspecified list. Marked ticket 10 resolved to match the tracker's status word. Ticket 12 stays claimed until the human confirms it can close.

### GPT-6 - Codex App

Read the current pitch, capture commitments, MVP index, and prior retrieval research to scope the requested open-source survey. Used the research skill to delegate primary-source checks of reusable capture, organization, and retrieval code; independently checked Jev's first-party SDK, candidate repositories, licensing, and the availability of the existing `interfaces-that-think` lead. Saved the cited findings in `.scratch/scattered-ambitious-pitch/research/14-open-source-capture-organization-retrieval.md` and linked them from DESIGN.md so future product and engineering choices can find the evidence. No stack, schema, or product behavior was locked and no code was copied or run; the next choices require a small capture and point-of-decision pilot.

Recorded the simple blurred and darkened capture overlay, defined Explode and its explicit MVP exclusion, and recorded first-class hotkey creation of dialogs linked from selected text. Updated the capture ticket, glossary, DESIGN.md, and MVP index. Raised the remaining boundary between preserving separate thoughts and automatically dividing a block, and the meaning of a linked dialog, to avoid silently deciding either. The capture ticket remains claimed.

Recorded agreement on adjacent writing spaces and optional related notes in the capture ticket and DESIGN.md. Expanded the map's destination and Lock the pitch to include an ambitious MVP made from concrete, human-settled product decisions. Created a linked MVP scope index separating settled commitments from unresolved feature boundaries, so broad vision statements cannot silently become fully specified release features. Continued the capture interview; no ticket was closed and no implementation began.

Recorded the human's capture decisions in What capture must preserve, CONTEXT.md, and DESIGN.md: preserve separate thoughts and wording with minor legibility corrections, retain available source or draft references, and keep inferred connections revisable. Read the glossary format before updating its definition. Continued the live interview with capture-interaction choices; the ticket remains claimed because those choices are unresolved.

Read the wayfinder, grilling, and domain-modeling skills, the existing map, glossary, design document, and local tracker conventions to resume the established pitch effort. Checked ticket statuses and dependencies and claimed What capture must preserve, the first available decision. Delegated read-only context checking under the grilling skill. The directory has no Git repository. A memory lookup found only another project's wayfinder setup, so the current project's files govern this session. Preparing a live conversation about what a capture retains and which capture interactions are required; no product decision has been made or changed.

## 2026-09-28 - Grok - Cursor

Closed Form of the creation session. The form is a point of decision: a dumped note appears inside an app they already have open, and one click takes it where they chose. There is no home. A rare label correction does not gate it. The word landing was rejected. The list of apps and points of decision stays in Last pass on passive cues. Which price band is now unblocked.

Opened Last pass on passive cues and left it open. It waits on the form, capture, the price band, and the rough day, and Lock the pitch waits on it. In Form of the creation session, the human rejected a separate sitting-down. They described the product appearing on Substack, on a chat, and inside Twitter, and they named point of thinking and point of making. Asked what a cue has to make them do, and whether the dump stays a third moment.

Claimed Form of the creation session. The glossary already treats that session as a sitting-down to make, and treats an inspiration feed as the wrong job. Asked whether the scroll and the injected feed are that session, or only how the session starts.

Closed Pay, keep paying, tell a peer. The first buyer is the maker. They stay because the dump and the creation session are one product. They tell another maker, and they tell from pride. Passive productivity is the marketing stance: calm upkeep, extreme making. Price waits on the form. Opened Form of the creation session and Which price band.

Claimed Pay, keep paying, tell a peer. The human described a wedge of creatives and idea-driven makers, a dump they do not organize, and a creation session fed by a stream. The infinite scroll and the feed injection stay unlocked in this ticket. Asked who the first buyer is, why they stay, and what they pay.

## 2026-09-27 - Grok - Cursor

Recorded [When an intention comes back](7db838f7-7b6e-488b-b74e-87994b224002) on the map. An intention governs the next act only when a cue retrieves it at the moment of action. Graduated What capture must preserve from the chrome fog, and pointed Day in the life and rough interface at that ticket plus Pay, keep paying, tell a peer.

Closed One product or a series. One product, two moments: capture without classification, retrieval that changes the next act. Capture chrome stays directional. Opened When an intention comes back and sent it to research.

Claimed One product or a series after the human said the pitch is one product and described a parallel capture surface. Did not lock the hotkeys, blur, explode, or wikilinks. Opened When an intention comes back, because goal neglect is a retrieval failure and the capture sketch does not answer when an intention governs action again. Asked the human to cut what the one product includes.

Closed Name the spine. The human chose goal neglect: intentions stop governing action under the load of many open projects. Recorded the term in `CONTEXT.md`. One product or a series, and Pay, keep paying, tell a peer, are now the frontier.

Recorded [Load-bearing failure](f3882e7f-29d7-4528-a6ff-0a23f4353583) on the map and claimed Name the spine. Sources refuse a single cause. The closest upstream failure is losing active control of intentions already formed under concurrent load. Asked the human to name the spine.

Recorded [What they already pay for](08af1a2e-ab5e-4d44-b9c3-268a3646efee) on the map. Published prices span a few dollars a month up to the mid-thirties; referral programs exist; retention rates were not published. Pay, keep paying, tell a peer stays blocked on Name the spine.

Recorded [Why tools lose them](1f660ff2-2907-477d-9906-ef2a66a24d5c) on the map. The gist: tools lose this person when upkeep outruns benefit as project load grows. Name the spine stays blocked on Load-bearing failure.

The first launch of Load-bearing failure, Why tools lose them, and What they already pay for died immediately: the inherited model is not available on this plan. A relaunch on Grok 4.7 died the same way. Relaunched all three on Composer 2.5. The tickets stay claimed. Nothing was resolved.

Charted the wayfinder map Scattered ambitious pitch at `.scratch/scattered-ambitious-pitch/map.md`. The destination is a locked self-pay pitch for the scattered ambitious person, not a build. Wrote `CONTEXT.md` so the audience term is fixed: diagnosis is not the gate, and the buyer is the person. Opened eight tickets. Claimed the three research tickets — Load-bearing failure, Why tools lose them, and What they already pay for — and sent them to background research. Left the grilling and prototype tickets blocked until those answers exist. Wrote `docs/DESIGN.md` so the effort's shape is readable without opening the map.
