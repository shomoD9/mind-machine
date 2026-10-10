# Vision capture, 2026-10-01

Raw statements from the human, regrouped by topic. Nothing here is a settled decision until it is confirmed in the grilling and moved to `CONTEXT.md`, `DESIGN.md`, or a ticket. Items marked **Tension** conflict with something already settled.

## Philosophy

- The product is a tool for thinking: capture with high fidelity from wherever you are, and retrieve wherever you are.
- The world being built for is spontaneously creative and not limited by its distance from a capturing and retrieving mechanism.
- The point of an idea is to be published. The point of retrieval is publishing, not developing an idea and keeping it.
- The latest published version of an idea is the latest variant of that idea. The note corpus updates from what was published.
- The human is a thinker, builder, writer, maker. They are building for themselves first and dogfooding to refine the standard.
- Simplify: a very simple, strong idea underneath, a thorough and amazing form factor on top. The philosophy must be strong before the product is.
- The user said "retrieve with high purposefulness" may be the wrong phrase. Retrieval exists so the maker can do something with the note.

## Surfaces

- First surface is the Mac, the places the maker already visits: X (doomscrolling loops), writing places (articles, video scripts), code, product building.
- Later: video. Now: articles ("ship a story"). Code prompts were also named at the start.
- When the maker goes to write or build, relevant ideas are recalled for that project.

## Prompts (system-initiated)

- The system throws prompts at the maker. No always-on agentic system is needed.
- On X, a writing or building action item appears like a tweet in the scroll flow, highlighted and alluring.
- The prompt is based on an idea from the past.
- The prompt has a deep link to open a Substack draft (existing or new) with the idea pasted in.
- The maker may instead click the prompt box itself to keep developing the idea inside the product, without going to Substack.

## Idea state and publishing

- Open question: after a deep-link click, how does the system know the idea was worked on? Clicking probably means some progress.
- A draft developed on Substack and not posted should have a way back into the note. Or the system notices later and resurfaces it, and the maker says on the note that it was worked on or published.
- The software looks for publishing. The maker gives it the link to their Substack once. It reads the publishing surface and updates the idea in the corpus.
- It needs access to publishing services and to drafting and working surfaces (repositories).
- Process the maker would impose on themselves: commit all latest work so the system reads GitHub instead of the local machine. It should look at the app developer system somewhere.

## Corpus and privacy

- Behind the scenes a corpus builds up: philosophy, projects, reflections, ideas in progress.
- Public ideas and personal ideas are distinguished. Personal ideas stay in a private wiki.
- Sensitivity tags and markers, like PII tags, produced by a very small system-1 model (user named "Jeff or Laya"; unclear which models).

## Note-taking surface (adopted components)

- **Write_On (Jason Fried).** Per-note behaviours and conveniences. Not all AI features; only some are good enough. From the post text: "alternative control" at word, sentence, and paragraph level (not version control), a way to dim text back, and a way to stash text nearby. The video was not viewable; the exact behaviours are not captured yet.
- **Noterepo (Flavio Copes).** Default browsing view: scroll back through earlier days' notes. From the page: macOS app, opens on today, bullets with Tab to nest, local SQLite file, no accounts, no AI, shows only days with writing, pasted links fetch title and domain (YouTube titles, X post previews), screenshots can be dropped or pasted, Cmd+F search, Cmd+D jump to today, about 1.5 MB, open source, Swift.
- The human's extension of Noterepo: each day is a canvas. All of that day's notes sit in the background. A central note in the middle holds the agent's interpretation of all the thoughts that day. More detail to come from the human.

## Round 1 answers (2026-10-02)

- **Core idea is spontaneity.** The human rejected "a note is an open loop until it ships" as the core. They want to capitalise on their own spontaneity and work without plans or timetables. The app feeds that: a thought is written down the moment it comes, it is easy to post, and when posting, everything thought so far is easy to recall. While scrolling or consuming, prompts from other projects inspire a creative contribution. This is "the core" and research should double down on it.
- **The first user is the human.** The claim: solving for self solves for a large number of neurodivergent people. The product is not a clinical tool. It solves the human's problem of putting out less than they could.
- **The failure the human reports.** They go deep on theory, presentations, and storytelling and ship little. At the moment of shipping they become consumed by what others will think. Two traps: (1) "no one has to like it, so no standards", (2) standards that drift into people-pleasing. Quality cannot come from consensus; the maker knows when a story, product, or solution works. In front of people, every cue is an important cue and they are overwhelmed. The human says this is not necessarily for the product to solve, but the product should use these insights and look for innovative ways around known ADHD productivity challenges.
- **Private notes.** Agreed: a small local model tags public or private. Private notes are captured and recalled, never prompted into feeds. Implementation is not the concern now; product shape is.
- **Canvas.** The daily canvas is the browsing view and is never required.
- **First surfaces.** Agreed: X prompts and Substack first. Added requirement: wherever the cursor is, in any text box or editor (including Codex and the Claude Code chat box), the maker can retrieve notes right beside the cursor.

## Round 2 answers (2026-10-02)

- **Spine.** Spontaneity is the spine; goal neglect is the problem statement. The human's mind is highly parallel, hyperactive, fluctuates between wants, and seeks novelty. Goal-seeking through planning and regimented (scheduled) action does not work for it. Some planning may remain. The human wants a model of reaching goals that does not depend on scheduled action, possibly "spontaneous goal seeking" or a better term from literature or pop philosophy, and asked for research plus first-principles thinking. Research launched: `.scratch/scattered-ambitious-pitch/research/15-goals-without-planning.md`.
- **Shipping.** The product never shows audience reaction. The human's reason: the point is to take part in exchange with society by giving valuable products and stories and receiving attention, money, and goodwill. Work has to leave the lab.
- **Beside the cursor.** Quiet while typing; one small card appears on a pause or on a hotkey; at most one card. Clicking inserts the note's text at the cursor, with a secondary control to open the dialog.

## Round 3 answers (2026-10-02): the core, restated by the human

- **The one job.** Never forget a thought, never fear forgetting, and recall the right thoughts at the right point in a creative session, without organizing anything. "We are not solving for anything else." Every other feature serves this. The human asked to lock it.
- **Idea bag.** A working name for the feel: the maker carries a bag of ideas everywhere and is nimble with them. The product name is open.
- **Capture dialogs are an aid, not the storage structure.** The network of hotkey-operated dialog boxes exists to capture many thoughts in parallel. Stored form is two wikis.
- **Two wikis.** A wiki of the self (purely private, organized in a navigable way) and a wiki of ideas. Both have hyperlinks. The self wiki may reference the ideas wiki. The ideas wiki never references or mentions the self wiki. Names for them are open.
- **Background agents** (one or several) sort the captured ideas into the wikis. They look for stories, narratives, and product stories in the ideas. Every wiki page is a story told from the problem backwards, or from conflict to resolution. This is built into the agents' skills for the maker persona.
- **Retrieval at the draft.** When the maker sits down to write, a note search box is beside the cursor. It returns related notes; clicking any note returns the notes related to that one; the maker can insert them into the draft. The maker can select text written in a draft and send it back into the idea vault.
- **Coding tools connect to the wiki.** Codex or Claude Code, when starting a build, pull relevant thoughts and ideas from the wiki.
- **Feed prompts.** Reflective or drafting exercises appear in the X feed and the YouTube feed, based on the maker's notes.
- **Letters from a worker agent.** While sorting, an agent can leave a letter: a conflict, a question, or a follow-up about something the maker wrote, with options to select and a place for free-form writing. The answer becomes another captured thought.
- **Posted state.** Clicking "Turn this into a post" does not tell the product the note was posted. Later the product asks the maker to verify. On a regular cadence it reads the maker's public surfaces (X, Substack) and reconciles which wiki pages were posted, changed, or consolidated. The human rejected the three note-state options offered in Q9 and described this instead.
- **Central note.** A mirror of the day.
- **Phone.** Mac only for the MVP.
- **Goals without planning.** Handled as a separate investigation (research note 15). Not part of the core job above.

## Tensions with settled decisions

- **Home.** The settled form says there is no home the maker must remember to open. A daily canvas is a home.
- **Capture.** Settled: typing only, notes on device by default, separate thoughts preserved, maker's wording preserved. The daily canvas adds an agent-written interpretation, and Substack/GitHub reading needs network access and credentials.
- **Prompt on X.** Settled: the note appears inside an app the maker already has open, one click takes it to a chosen place. The tweet-like prompt in X fits; the open question is what the click does.
- **Audience.** The repo is named for neurodivergent productivity and `CONTEXT.md` names the audience scattered ambitious maker. This message describes the maker (thinker, builder, writer) without the attention framing.
