# Design

This repo is finding its way to a product pitch. The product is not specified yet.

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
