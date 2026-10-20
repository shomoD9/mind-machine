# UniiChat: identity, continuous conversation and memory

Research date: 20 October 2026. Source inspection is pinned to official commit `0500bf6a8ea4bf0ce047488562022b1b6532cc30`, committed 19 October 2026 at 16:45:05 UTC. This report records documentation and static source inspection. It does not establish production reliability, successful installation, App Store availability or measured recall accuracy.

**The intended project is Victor Taelin's UniiChat: one continuing conversation, retained by default, with a summary tree that lets the agent reopen original messages.** The creator's X announcement links the same repository and hosted product. The official source is Apache-2.0 licensed. This is a relevant reference for the user's clarified requirement that ordinary conversation remains available without selecting individual messages to save. [U01](https://x.com/VictorTaelin/status/2112231355987935506) [U02](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/README.md) [U03](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/LICENSE)

## Identity verified

| Evidence | Finding | Limit |
| --- | --- | --- |
| Creator X source-release post | [@VictorTaelin: source is out](https://x.com/VictorTaelin/status/2112231355987935506) links the official source and UniiChat.com. Creator reports using it as his only agent for a month and warns ports may get caching/log behavior wrong. | Creator promotion and personal experience. Coordinating agent verified the post in Chrome; visible timestamp was **last edited 10:46 PM, 19 October 2026**, rather than independently verified original publication time. |
| Earlier creator announcement | [Original announcement/video](https://x.com/VictorTaelin/status/2108200878553588091) is linked directly from the official README. | It precedes the source-release post. Do not describe both as the same announcement. |
| Official repository | [VictorTaelin/uniichat](https://github.com/VictorTaelin/uniichat) links [UniiChat.com](https://uniichat.com/) and contains memory, server, web, terminal and iOS source. | Public code can differ from the production service. |
| License | Apache License 2.0; README attributes copyright to Higher Order Company. | This establishes source licensing; production terms and model-service charges are separate. |
| Independent port | [jonaslsaa/pi-optchat](https://github.com/jonaslsaa/pi-optchat) explicitly calls itself an independent Pi implementation of Taelin's design. | Its MIT license, storage, import and deletion behaviors cannot be attributed to official UniiChat. |

The unrelated `amidabuddha/unichat-mcp-server`, same-name chat apps and third-party OptChat/OptMem implementations were excluded as evidence of official UniiChat behavior. Search spelling alone does not establish identity.

## What the official implementation establishes

| Question | Verified behavior | Unknown or qualification |
| --- | --- | --- |
| One continuous chat? | README specifies one ongoing agent conversation and no New Chat button. [U02](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/README.md) | Whether one conversation is preferable across all personal/work contexts requires testing. |
| Does ordinary conversation persist? | Messages enter the main log; summaries live separately in the tree. Role, text, dates and image references are retained. [U04](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/Memory.ts#L348) | Successful persistence still depends on storage and operations. No crash-recovery tests were run. |
| Does every turn receive the full transcript? | The model receives a bounded view built from summary nodes, with coarser coverage of older material; configured high watermark is 128,000 UTF-8 bytes. [U04](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/Memory.ts#L134) | This is a byte budget. It does not mean unlimited tokens or that every old message is read verbatim on every turn. |
| Can it recover originals? | `zoom(id,n)` expands a summary; at `n=1` it retrieves the message and images. `date` retrieves its time. [U05](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/Tools.ts#L175) | Recovery depends on selecting the relevant branch. Full storage alone does not prove successful recall. |
| Is this a semantic-search implementation? | Inspected memory tool definitions expose zoom and date. Prompt instructs the agent to navigate history through zoom and explicitly prohibits manually grepping/searching memories. [U05](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/Tools.ts#L175) [U06](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/prompt.txt#L39) | Vector search, hybrid personal-vault search and user-facing exact-match search were not established. General web search is a different capability. |
| Self-hosted or hosted? | Hosted service exists; own server can use own API keys. Server owns history; web tabs/terminal show live views. [U02](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/README.md) | Own server and remote model inference can coexist. Self-hosting does not establish entirely on-device processing. |
| Cross-device sync? | Server broadcasts chat updates to connected views; native iOS source uses that server. [U07](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/Server.ts#L1055) [U08](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/ios/Shared/Site.swift) | Source establishes a shared server history. Offline replica synchronization and conflict resolution were not established. |
| Export? | Authenticated `/export` returns JSON; dump includes account, messages, summaries, agent logs and image bytes. [U07](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/Server.ts#L1507) [U04](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/Memory.ts#L1071) | Export/reimport round-trip fidelity was not tested. |
| Delete? | Account-deletion handler requires the account name, ends the chat and removes that user's server directory. [U07](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/Server.ts#L1454) | Per-message deletion/redaction was not found in inspected chat routes. Hosted backups, provider retention and deletion propagation were not audited. |
| iPhone/iPad? | Source includes an iOS 17+ app using a web view, dictation permissions, notifications and share extension. [U09](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/ios/App/Unii.swift) [U10](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/ios/project.yml) | Public App Store/TestFlight distribution was not verified. Source existing is separate from consumer availability. |
| Keyboard? | iOS project defines app and share-extension targets. Share source accepts text, URLs and images as one message with an optional note. [U10](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/ios/project.yml#L56) [U11](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/ios/Share/Share.swift) | Custom iOS keyboard capture/search was not established. Share extension specifies at most one web URL and twenty images in its activation rule. |
| Mac? | Browser and terminal clients; opt-in Mac computer-use functionality described. [U02](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/README.md) | Dedicated native Mac capture/search hotkey palette was not established. |
| External LLM memory connector? | Tools implementation uses a secret local MCP endpoint for its own calls. [U05](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/Tools.ts#L245) | This alone does not establish a supported user-facing memory connector for arbitrary AI apps. |

The README's retention claim is supported by storage/zoom code, while its perfect-memory framing remains an unmeasured product claim. Its own compactor prompt recognizes that omitted details may become undiscoverable through summaries. Original preservation and discoverability need separate acceptance tests. [U04](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/Memory.ts) [U06](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/prompt.txt#L57)

## Retaining a transcript and treating a statement as a user fact

The inspected prompt defines authorship kinds for user messages, agent replies, tool calls/results, subagent reports, imported AI replies and previous memories. Its compactor instructions prioritize the user's words, require attribution for quoted material and prohibit adding information absent from the input. This is evidence that default retention can coexist with provenance-aware derived memory. It provides no empirical guarantee against attribution mistakes. [U06](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/prompt.txt#L12)

For this product, the user's clarified interaction can be expressed without save prompts:

| Conversation content | What remains available automatically | What retrieval must preserve |
| --- | --- | --- |
| “I am considering moving to Pune.” | The whole exchange, including later discussion. | Considering is tentative; it must not become a settled move. |
| A pasted passage: “I hate remote work.” | Passage and surrounding explanation. | The passage's author and quotation status; the text alone does not establish the user's preference. |
| Assistant: “Perhaps uncertainty is bothering you.” | The assistant's reply and the user's response. | It is an assistant hypothesis unless the user endorses it. |
| User later: “I decided to stay in Bengaluru.” | Both earlier deliberation and newer decision. | Current answer uses the later decision; historical queries can still recover the deliberation. |
| “Remind me tomorrow at 9.” | Request, interpretation and resulting action history. | Storage of the request and actual reminder creation/delivery are separately verifiable. |

These examples are proposed product semantics. They were not tested against UniiChat. They require neither a per-message Save decision nor a stream of inferred-save receipts. A user can inspect sources or correct an interpretation when needed, while ordinary conversation continues uninterrupted.

## Product implications for the current vision

1. **Keep the whole conversation by default.** The user has selected this behavior. A separate save decision for each useful message would contradict it. Chat becomes a capture surface even during exploratory conversation.
2. **Preserve original exchanges alongside derived summaries and retrieval structures.** In answers, retain speaker, quote status, timing, uncertainty and correction history. A source reference can be available on request or through the result itself; it need not interrupt capture.
3. **Define “remembers everything” as storage plus evaluated recovery.** Test finding a small detail weeks later, a quote that differs from the user's belief, a superseded decision, and information missed by an intermediate summary. Do not count storage success as retrieval success.
4. **Evaluate this alongside keyboard capture/search.** UniiChat informs the continuing-chat/memory model. It does not settle this app's keyboard experience, attachment capture, cross-app result insertion or search quality.
5. **Keep reminders as actual commitments with observable state.** Storing every discussion should remain easy; an inferred possibility must retain its tentative status. The policy for creating external actions still needs a decision.
6. **Specify deletion at both original and derived levels.** If a user removes something, summaries/indexes and future retrieval need corresponding behavior. Default retention can include explicit deletion controls without per-message admission prompts.

No implementation stack or adoption decision is made here. No source was installed or executed, no paid models were called and no user conversations were uploaded.

## Source register

| ID | Primary source | Use |
| --- | --- | --- |
| U01 | [Taelin source-release post](https://x.com/VictorTaelin/status/2112231355987935506) | Creator identity and release attribution. Chrome verification supplied by coordinating agent; web fetch returned 403. |
| U02 | [Official README at inspected commit](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/README.md) | Single chat, surfaces, server ownership, self-hosting/API-key model. |
| U03 | [Official LICENSE](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/LICENSE) | Apache-2.0. |
| U04 | [Memory.ts](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/Memory.ts) | Original log, tree, byte budgets, zoom data and export contents. |
| U05 | [Tools.ts](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/Tools.ts) | Memory tools and internal MCP boundary. |
| U06 | [prompt.txt](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/prompt.txt) | Role attribution, quotation handling, compaction and navigation instructions. |
| U07 | [Server.ts](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/Server.ts) | Shared live history, export and account deletion handlers. |
| U08 | [iOS Site.swift](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/ios/Shared/Site.swift) | Authenticated server requests and reachability errors. |
| U09 | [iOS Unii.swift](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/ios/App/Unii.swift) | Web-view app, mic, push and export integration. |
| U10 | [iOS project.yml](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/ios/project.yml) | Targets, deployment version, share activation limits. |
| U11 | [iOS Share.swift](https://github.com/VictorTaelin/uniichat/blob/0500bf6a8ea4bf0ce047488562022b1b6532cc30/ios/Share/Share.swift) | Share capture composition and posting. |
| U12 | [Earlier creator video post](https://x.com/VictorTaelin/status/2108200878553588091) | README-linked original announcement; separate from source release. |
| U13 | [Independent pi-optchat README](https://github.com/jonaslsaa/pi-optchat) | Disambiguation only; no port behavior attributed to official project. |

Source files were read from public GitHub endpoints at the stated commit; cited line numbers follow that snapshot. The hosted site and current branch may change. Source-derived product behavior is bounded by what was inspected, with unknowns retained explicitly.
