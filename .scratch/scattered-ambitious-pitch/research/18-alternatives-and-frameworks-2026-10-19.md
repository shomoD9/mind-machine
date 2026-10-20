# Alternatives and second-brain frameworks

Research date: 19 October 2026. Evidence: first-party product documentation, product pages, and official source repositories. This is a documentation comparison; no paid accounts, product trials, retrieval benchmarks, or reliability tests were performed. Capability statements below mean the owner documents the capability. They do not independently establish its quality.

The proposed app enters a crowded category. Automatic organization, semantic retrieval, chat over a personal library, external AI access, contextual resurfacing, and capture from a desktop shortcut already exist across several products. Mem documents a particularly close combination. The research supports testing a narrower promise: **save a thought from where you are, then recover and reuse its original content where you need it, with little maintenance and a visible account of what was saved or scheduled.** This is a positioning hypothesis, pending user decisions and comparison trials. [A03](https://get.mem.ai/features/push-to-remember) [A04](https://get.mem.ai/features/heads-up) [A10](https://fabric.so/features/organization) [A18](https://docs.karakeep.app/)

## Reading the matrix

- **Documented** means a source explicitly describes the behavior.
- **Unknown** means the selected evidence does not settle it. It never means the product lacks it.
- A checkbox list, a suggested action, a reminder notification, and a calendar event are different capabilities.
- An in-app shortcut and a global shortcut are different capabilities.
- A keyboard that dictates into another app does not, by itself, establish personal-vault capture or retrieval inside that keyboard.
- Automatic tagging does not establish fully automatic task scheduling, importance inference, or dependable resurfacing.
- “Unlimited pictures,” arbitrary attachment counts, and guaranteed universal capture were not verified for any product.

## Capability comparison: capture, organization, retrieval

| Product | Documented capture and organization | Documented retrieval | Main evidence |
| --- | --- | --- | --- |
| **mymind** | Notes, bookmarks, images, PDFs, highlights; automated categorization; no filing required. | Search plus OCR and color-based finding. Strict exact/semantic retrieval behavior: unknown in selected documentation. | [A01](https://mymind.com/how) |
| **Mem** | Desktop shortcut sends a spoken thought to Agent; Agent can create/update/organize workspace information. Longer Voice Mode produces a note with recording/transcript. | Agent can find prior captures; Chat queries workspace; Heads Up finds related context automatically. Exact-match semantics: unknown. | [A03](https://get.mem.ai/features/push-to-remember) [A04](https://get.mem.ai/features/heads-up) |
| **Reflect Open** | Daily-note capture, text, attachments, browser clips, screenshots, audio transcription; local Markdown source files. | Local search across notes/tags/backlinks; optional local semantic search; AI answers cite source notes. | [A06](https://github.com/team-reflect/reflect-open) [A07](https://reflect.app/blog/reflect-open) |
| **Recall** | Saves supported online sources; automatic tags and connections; notebooks for the user's writing. | Library chat; MCP searches/reads/explores saved cards. Strict exact-match behavior: unknown here. | [A08](https://docs.recall.it/use-cases/workflow/ai-extension) [A09](https://docs.recall.it/developer/mcp) |
| **Fabric** | Files, notes, links, screenshots, voice; automatic metadata, tag suggestions, relations and transcription; filing optional. | Natural-language search across connected sources; PDF/note keyword search; audio/video transcript search; visual and color search. | [A10](https://fabric.so/features/organization) [A11](https://fabric.so/features/smart-organization) [A12](https://fabric.so/features/search) |
| **Voicenotes** | Memos, meetings, dictation and text notes; transcription and AI processing. | Ask AI; external MCP has semantic search, date/tag filtering and transcript retrieval. Strict exact-search semantics: unknown. | [A13](https://help.voicenotes.com/en/articles/15391505-what-can-voicenotes-do) [A14](https://help.voicenotes.com/en/articles/14336494-voicenotes-mcp) |
| **Capacities** | Daily notes and objects; mobile capture controls; image/PDF/weblink analysis; audio transcription documented in Believer early access. | Full-text and exact phrase search; query modes Auto, Exact and Semantic; external AI can search/read. | [A15](https://docs.capacities.io/reference/search) [A16](https://docs.capacities.io/reference/media-analysis) [A17](https://docs.capacities.io/reference/ai-chat-connectors) |
| **Obsidian** | Local vault and official browser clipper; highlighter and interpreter support configurable capture. Filing requirements depend on chosen workflow. | Core search supports exact phrases, operators, regex and task queries. It searches note/canvas contents; attachment-body indexing or semantic retrieval in core: unknown here. | [A21](https://obsidian.md/help/plugins/search) [A22](https://obsidian.md/clipper) |
| **Readwise / Reader** | Articles, PDFs, EPUBs, newsletters, RSS, video transcripts and highlights; reading/annotation workflow. | Library full-text search; CLI explicitly documents hybrid search over full documents and highlights. Feed documents are excluded from full-text index until moved into Library. | [A23](https://readwise.io/read/) [A24](https://docs.readwise.io/reader/docs/faqs/searching) [A25](https://readwise.io/cli) |
| **Karakeep** | Text/URL/image/PDF bookmarks; automatic tags, summaries, OCR, page archives; self-hosting and local model support. | Full-text and semantic search documented; product page also documents hybrid mode. Search qualifiers refine retrieval. | [A18](https://docs.karakeep.app/) [A19](https://karakeep.app/) [A20](https://docs.karakeep.app/using-karakeep/search-query-language/) |
| **WhatsApp Message Yourself** | Owner documents a self-chat for keeping notes/messages; pinning and forwarding supported. Familiar chat is the capture baseline. | Chat retrieval semantics and semantic search: unknown in this source. | [A26](https://faq.whatsapp.com/1785465805163404/?cms_platform=android&helpref=platform_switcher&locale=id_ID) |
| **Raycast Notes + iOS keyboard** | Global Create Note command and floating Notes window; Markdown and task lists; iOS secondary keyboard adds AI commands, dictation, quicklinks and snippets. | Notes search by title/content; access through launcher commands. Semantic search over a personal note vault from the iOS keyboard: unknown. | [A27](https://manual.raycast.com/notes) [A28](https://manual.raycast.com/ios/keyboard) |

## Capability comparison: surfaces, resurfacing, AI access, action

| Product | Surfaces and resurfacing | External AI and actionable commitments | Main evidence |
| --- | --- | --- | --- |
| **mymind** | Mobile/browser/Mac companions; Serendipity lets users rediscover saved material. This is user-invoked browsing; relevance-triggered notifications: unknown. | To-do capture documented; notification/calendar execution and official MCP: unknown. | [A01](https://mymind.com/how) [A02](https://mymind.helpscoutdocs.com/article/44-rediscovering-things-with-serendipity) |
| **Mem** | Mac/Windows global capture over other apps; optional floating Agent; Heads Up gives related notes, meeting timelines, calendar briefings and live recording context. | Agent documents reminders/tasks/projects within plan allowances and follow-ups. External MCP: unknown in selected evidence. | [A03](https://get.mem.ai/features/push-to-remember) [A04](https://get.mem.ai/features/heads-up) [A05](https://get.mem.ai/product/agent) |
| **Reflect Open** | Mac and iPhone companion; source repo currently describes beta. Browser capture and CLI. Global cross-app palette/iOS keyboard: unknown. | CLI allows agent reading; user-configured AI providers. Tasks can be scheduled/completed; Apple Calendar events appear beside daily note. Event creation through inference: unknown. | [A06](https://github.com/team-reflect/reflect-open) [A07](https://reflect.app/blog/reflect-open) |
| **Recall** | Browser extension chats in current page; augmented browsing highlights links to existing knowledge using local processing; quiz review. | Official MCP explicitly read-only; write support is future work on that page. Reminders/calendar execution: unknown. | [A08](https://docs.recall.it/use-cases/workflow/ai-extension) [A09](https://docs.recall.it/developer/mcp) |
| **Fabric** | Connected-source search, similar-content exploration; mobile/desktop surfaces. Keyboard vault retrieval: unknown. | Product page documents AI assistant, email recaps, tasks and snoozing files/links. Official MCP and inferred calendar-event creation: unknown here. | [A11](https://fabric.so/features/smart-organization) [A12](https://fabric.so/features/search) |
| **Voicenotes** | Mac global dictation/recording shortcuts; iPhone/Android dictation keyboard. Keyboard personal-vault search and capture-to-vault behavior for every dictation: unknown. | Official MCP supports searching, reading transcripts and creating text notes. Generated to-do lists documented; reliable timed reminders/calendar execution: unknown here. | [A14](https://help.voicenotes.com/en/articles/14336494-voicenotes-mcp) [A29](https://help.voicenotes.com/en/articles/11161004-how-to-use-voicenotes-on-mac) [A30](https://help.voicenotes.com/en/articles/15900719-how-to-set-up-and-use-dictation-on-iphone) [A31](https://voicenotes.com/whats-new/) |
| **Capacities** | iOS widgets, Shortcuts, Control Center for capture/search; Raycast integration offers global Mac search. Related-content notification policy: unknown. | Official MCP supports read/write, including tasks, objects and media. Version history provides recovery. Dedicated task management exists. | [A15](https://docs.capacities.io/reference/search) [A17](https://docs.capacities.io/reference/ai-chat-connectors) [A32](https://docs.capacities.io/reference/mobile) [A33](https://docs.capacities.io/reference/task-management) |
| **Obsidian** | Browser clipper plus vault-centric app; capture can be configured through templates. Cross-app search keyboard: unknown. | Local files are accessible to tools granted filesystem access. Official MCP, automatic reminders and calendar execution: unknown. Community plugins are outside this comparison. | [A21](https://obsidian.md/help/plugins/search) [A22](https://obsidian.md/clipper) |
| **Readwise / Reader** | Readwise Daily Review returns saved highlights through email/app. Browser/mobile/desktop and exports to writing tools. | Reader page documents official MCP; CLI can search, read, create and organize documents/highlights. Personal task/reminder/calendar execution: unknown. | [A23](https://readwise.io/read/) [A25](https://readwise.io/cli) |
| **Karakeep** | Browser extensions, mobile capture and offline reading; RSS import; rules. Context-triggered proactive recall: unknown. | Official MCP searches, reads, creates, updates and deletes bookmarks/lists/tags. This establishes headless data operations. Timed task/calendar behavior: unknown. | [A18](https://docs.karakeep.app/) [A34](https://docs.karakeep.app/integrations/mcp/) |
| **WhatsApp Message Yourself** | Self-chat stays in an existing messaging app; pinning makes it accessible. Proactive resurfacing: unknown. | Storing a reminder message is distinct from scheduling a notification. Execution or assistant access is not established by this source. | [A26](https://faq.whatsapp.com/1785465805163404/?cms_platform=android&helpref=platform_switcher&locale=id_ID) |
| **Raycast Notes + iOS keyboard** | Global create/search commands on desktop; keyboard accesses AI, snippets, quicklinks and recent items. First dictation redirects to app, then allows a five-minute background session. | Notes has checkboxes; reliable task notifications/calendar handling is unknown in these sources. General Raycast AI/MCP exists, but this does not prove Notes is exposed as a personal-memory MCP server. | [A27](https://manual.raycast.com/notes) [A28](https://manual.raycast.com/ios/keyboard) |

## What the competitors invalidate

1. **“People must manually organize existing second brains” is too broad.** mymind makes filing optional, Fabric markets the same maintenance failure, and Karakeep automatically tags content. A defensible requirement is zero compulsory classification in this product, followed by measured retrieval quality. [A01](https://mymind.com/how) [A10](https://fabric.so/features/organization) [A18](https://docs.karakeep.app/)
2. **“Search cannot help people remember what to search for” identifies a separate job.** Mem already responds to current note/meeting context, Recall connects current browsing to saved material, and Readwise runs review sessions. Compare trigger types and nuisance levels before selecting a resurfacing policy. [A04](https://get.mem.ai/features/heads-up) [A08](https://docs.recall.it/use-cases/workflow/ai-extension) [A23](https://readwise.io/read/)
3. **“The keyboard makes the category unique” is insufficient.** Raycast has a secondary iOS keyboard and Voicenotes has cross-app dictation. The proposed keyboard must prove a more specific job: recovering a remembered item and inserting its source content into the current work. [A28](https://manual.raycast.com/ios/keyboard) [A30](https://help.voicenotes.com/en/articles/15900719-how-to-set-up-and-use-dictation-on-iphone)
4. **“Headless means connect to any AI” is already served in part.** Capacities, Recall, Voicenotes and Karakeep publish MCP interfaces; Readwise documents MCP and a CLI. Reach depends on the client's supported protocol, authentication and scopes. A universal compatibility promise is unsupported. [A17](https://docs.capacities.io/reference/ai-chat-connectors) [A09](https://docs.recall.it/developer/mcp) [A14](https://help.voicenotes.com/en/articles/14336494-voicenotes-mcp) [A34](https://docs.karakeep.app/integrations/mcp/) [A25](https://readwise.io/cli)
5. **“Capture/search/chat plus reminders” has a close rival.** Mem's shortcut sends thoughts to an Agent that can find information, update lists and create commitments. A trial should establish whether users still face enough friction, incorrect actions, or weak retrieval to switch. [A03](https://get.mem.ai/features/push-to-remember) [A05](https://get.mem.ai/product/agent)

These points establish competitive overlap. They establish neither product-market fit for competitors nor that the user's dissatisfaction has already been solved.

## Open-source alternatives worth examining further

**Karakeep** offers an inspectable reference for unstructured capture, derived metadata, mixed retrieval and agent operations. Its official repository documents AGPL-3.0 licensing; its product focus is bookmarking. Reuse, deployment obligations and fitness require separate review. No stack recommendation follows from this finding. [A35](https://github.com/karakeep-app/karakeep)

**Reflect Open** demonstrates local Markdown as authoritative content with rebuildable indexes, optional semantic search and a CLI. Its repository says MIT and beta. The current product differs materially from older hosted Reflect descriptions. Keep Reflect Open and Reflect Classic separate in future comparisons. [A06](https://github.com/team-reflect/reflect-open) [A07](https://reflect.app/blog/reflect-open)

**Obsidian Web Clipper** is an official open-source capture component. It demonstrates browser capture into a user's vault; it does not establish that the whole Obsidian app is open source, or that a plugin assembly supplies this product's whole experience. [A22](https://obsidian.md/clipper)

## The framework the app should be compared against

Tiago Forte's CODE model includes four activities: capture meaningful material, organize around actionability, distill it into usable material, and express it through real output. Capture and search address only part of that workflow. His introductory guide recommends selective capture, flexible structures and opportunistic refinement; it also warns against elaborate hierarchies. [A36](https://fortelabs.com/blog/basboverview/)

His separate misconceptions article rejects the idea that a second brain requires a complete reorganization of one's digital life. It allows incremental adoption and even values capture for relieving mental load before reuse happens. The PRD should therefore describe the user's observed maintenance burden and buried material without treating mandatory complexity or universal abandonment as defining properties of second brains. [A37](https://fortelabs.com/blog/9-biggest-myths-and-misconceptions-about-basb/)

Product inference: preserve the instant relief of offloading a thought, and measure whether it subsequently assists action. An automatic summary is a derived aid; the user's preserved statement remains the evidence. Search relevance, resurfacing timing and reminder delivery need distinct success measures. These are proposed design implications, rather than claims proven by Forte's framework.

## Positioning and discovery hypotheses

### Candidate promise

**A personal memory you can save to and retrieve from wherever you are already working. Drop in the thought as it came. Find its original words, image, link or recording when you need them. Keep control over what becomes a commitment.**

This is a candidate for user discussion. “Headless” can explain the architecture internally; externally, demonstrate keyboard, share-sheet and shortcut behaviors. A history/recovery view may still be needed to inspect captures, edit mistakes, export, delete and understand pending sync. Having no compulsory dashboard is a useful hypothesis; having no inspectable record creates a trust problem.

### Jobs that deserve separate validation

| Job | Concrete test | What would challenge the hypothesis |
| --- | --- | --- |
| Offload a thought immediately | Save mixed text, links and an image from a current activity; measure time and corrections. | Existing self-chat/share-sheet is as fast and users see no later advantage. |
| Recover a known item from a vague cue | Search a personal corpus using exact names, partial memories and related concepts; inspect original evidence. | Mem/Fabric/Capacities/Karakeep achieve the same success with acceptable effort. |
| Reuse saved material in the current app | Retrieve and insert a snippet/link while composing a message, without losing the draft. | Keyboard switching consumes more effort than share/copy/paste; attachment workflows break. |
| Remember an explicit commitment | Capture “remind me tomorrow at 9” and inspect interpretation, delivery and completion state. | User mainly wants a searchable note; commitment inference creates correction work or anxiety. |
| Rediscover something without forming a query | Select a clear trigger and show relevant source material with dismiss/snooze controls. | Notifications are ignored, relevance is weak, or users prefer deliberate review. |
| Bring memory into chosen AI app | Let an external assistant search/read scoped content, then save a selected statement with provenance. | Users need a dedicated chat more often, or cannot understand what is saved/shared. |

### Decisions the research cannot make for the user

1. Is the first outcome mental relief, successful later recall, completed commitments, or synthesis? They imply different acceptance tests.
2. Does “headless” mean default surfaces live outside the app, or that there is no browsable archive at all?
3. Must every capture remain a single original item even if it contains several tasks and ideas? How should derived items refer back to it?
4. Is proactive resurfacing essential? Specify an actual trigger and permissible interruption instead of “right thing, right time.”
5. Does a statement such as “I should call Mum” create a commitment, suggest one, or remain prose until the user chooses?
6. Does the keyboard need to replace everyday typing or act as a secondary capture/search panel? Raycast's secondary-keyboard model is concrete counterevidence against assuming replacement is required. [A28](https://manual.raycast.com/ios/keyboard)
7. What happens offline, while permissions are denied, when transcription is wrong, or when a link cannot be fetched? Documentation review cannot supply the user's tolerance.

### Proposed comparison pilot

Use the same participant-owned examples and queries across this product concept and three close baselines: self-chat, Mem, and either Fabric or Capacities. Add Karakeep if ownership/self-hosting matters. Record capture steps, successful top-result retrieval, time to insert source material, correction burden, missed reminders and unwanted interruptions. Include captures from weeks earlier. This is proposed research; no pilot has been performed.

## Evidence register

All entries accessed 19 October 2026. Vendor pages establish documented claims and product framing. They are not independent customer-demand evidence. Prices were deliberately omitted.

| ID | First-party source | Evidence boundary |
| --- | --- | --- |
| A01 | [mymind: How it works](https://mymind.com/how) | Capture formats, automatic organization, OCR/color finding, companions, to-do use. |
| A02 | [mymind: Serendipity](https://mymind.helpscoutdocs.com/article/44-rediscovering-things-with-serendipity) | User-invoked rediscovery. |
| A03 | [Mem: Push-to-Remember](https://get.mem.ai/features/push-to-remember) | Global capture, floating Agent, save/find/update, task/reminder/project behavior; plan limitations. |
| A04 | [Mem: Heads Up](https://get.mem.ai/features/heads-up) | Note/meeting context and proactive retrieval; briefings/live features include Pro/beta qualifications. |
| A05 | [Mem Agent](https://get.mem.ai/product/agent) | Follow-ups using workspace/calendar context. |
| A06 | [Reflect Open official source repository](https://github.com/team-reflect/reflect-open) | Markdown files, local semantic search, source citations, CLI, beta, MIT. |
| A07 | [Reflect Open announcement](https://reflect.app/blog/reflect-open) | July 2026 new product, tasks/calendar/audio; Classic continues separately. |
| A08 | [Recall: AI extension workflow](https://docs.recall.it/use-cases/workflow/ai-extension) | Saved sources, notebooks, library chat, auto tags/connections, local augmented browsing. |
| A09 | [Recall: MCP server](https://docs.recall.it/developer/mcp) | Search/read/explore; explicitly read-only at access date. |
| A10 | [Fabric: Organization](https://fabric.so/features/organization) | Filing optional; vendor frames maintenance burden directly. |
| A11 | [Fabric: Smart organization](https://fabric.so/features/smart-organization) | Metadata/tags/relations/transcription. Smart fields explicitly marked coming soon, so excluded. |
| A12 | [Fabric: Search](https://fabric.so/features/search) | Natural language, keyword, media, visual search; recaps and snooze/tasks documented. |
| A13 | [Voicenotes: What can it do?](https://help.voicenotes.com/en/articles/15391505-what-can-voicenotes-do) | Voice/text library, processing, AI creation. |
| A14 | [Voicenotes: MCP](https://help.voicenotes.com/en/articles/14336494-voicenotes-mcp) | Semantic search, list/filter, transcript access, new text notes; OAuth. |
| A15 | [Capacities: Search and command palette](https://docs.capacities.io/reference/search) | Full-text, exact, semantic, Raycast global search. |
| A16 | [Capacities: Media analysis](https://docs.capacities.io/reference/media-analysis) | Image/link/PDF analysis; audio early-access qualification. |
| A17 | [Capacities: AI chat connectors](https://docs.capacities.io/reference/ai-chat-connectors) | MCP read/write and media, external assistant tasks, version recovery. |
| A18 | [Karakeep documentation](https://docs.karakeep.app/) | v0.34 documented capabilities, self-hosting/local models. |
| A19 | [Karakeep product](https://karakeep.app/) | Text/link/image/PDF capture, keyword/hybrid/semantic modes. |
| A20 | [Karakeep search language](https://docs.karakeep.app/using-karakeep/search-query-language/) | Full-text and metadata/Boolean filtering. |
| A21 | [Obsidian core Search](https://obsidian.md/help/plugins/search) | Terms, phrases, regex, task queries; scope excludes attachment bodies in stated content search. |
| A22 | [Obsidian Web Clipper](https://obsidian.md/clipper) | Official open-source clipper, highlights, template-driven capture. |
| A23 | [Readwise Reader](https://readwise.io/read/) | Capture types, Daily Review, export, MCP, multi-device availability. |
| A24 | [Reader search FAQ](https://docs.readwise.io/reader/docs/faqs/searching) | Full-text Library indexing, Feed exclusion, offline fallback. |
| A25 | [Readwise CLI](https://readwise.io/cli) | Hybrid retrieval, reading, creation, organization, export. |
| A26 | [WhatsApp: Message yourself](https://faq.whatsapp.com/1785465805163404/?cms_platform=android&helpref=platform_switcher&locale=id_ID) | First-party Indonesian help page readable; English URL failed in research tool. Self-chat, forwarding, pinning, encryption. Other behaviors left unknown. |
| A27 | [Raycast Notes](https://manual.raycast.com/notes) | Global create/search commands; title/content retrieval, Markdown, checkboxes. |
| A28 | [Raycast iOS keyboard](https://manual.raycast.com/ios/keyboard) | Secondary keyboard, AI/dictation/snippets/quicklinks/recents; redirect/background dictation behavior. |
| A29 | [Voicenotes Mac guide](https://help.voicenotes.com/en/articles/11161004-how-to-use-voicenotes-on-mac) | Recording/dictation global shortcuts. Specific defaults may change; no shortcut assumed in design. |
| A30 | [Voicenotes iPhone dictation setup](https://help.voicenotes.com/en/articles/15900719-how-to-set-up-and-use-dictation-on-iphone) | Keyboard and Action Button dictation, permissions. |
| A31 | [Voicenotes changelog](https://voicenotes.com/whats-new/) | July 2026 mobile keyboard and August Mac creation formats. |
| A32 | [Capacities mobile](https://docs.capacities.io/reference/mobile) | Widgets, Shortcuts, Control Center; feature/plan qualifications. |
| A33 | [Capacities task management](https://docs.capacities.io/reference/task-management) | Dedicated task features; no assumed equivalence to reminders/calendar writes. |
| A34 | [Karakeep MCP](https://docs.karakeep.app/integrations/mcp/) | Official search/read/create/update/delete tools. |
| A35 | [Karakeep source repository](https://github.com/karakeep-app/karakeep) | Official open-source project and license. |
| A36 | [Forte: Second Brain introductory guide](https://fortelabs.com/blog/basboverview/) | CODE, selective capture, actionability, distillation, output, friction cautions. |
| A37 | [Forte: Second Brain misconceptions](https://fortelabs.com/blog/9-biggest-myths-and-misconceptions-about-basb/) | Incremental adoption and rejection of complete digital-life overhaul. |

## Research limitations

- This covers twelve deliberately selected alternatives, rather than every available app or emerging vendor.
- Official marketing promises are not measurements of speed, search accuracy, reminder delivery or long-term retention.
- The comparison uses current pages where possible. Product variants, plans and early-access status can differ. Reflect's announcement and homepage differ in release descriptions; the repository still calls its current status beta, so the report preserves that qualification.
- Some pages mix shipping features with roadmap language. Fabric Smart fields were excluded because the page marks them coming soon; Recall MCP write access was excluded because it explicitly remains future work.
- No complete audit of competitors' privacy, encryption, training policies, export fidelity or deletion propagation was performed. “Local,” “private” and “encrypted” should not be treated as interchangeable.
- Nothing here proves the prevalence of maintenance fatigue, that most people abandon second brains, or willingness to pay. Those need independent user evidence and trials.
