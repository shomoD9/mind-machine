# Platform feasibility: keyboard-accessible second brain

Research date: 19 October 2026, Asia/Kolkata. Official-source review plus read-only inspection of the installed Open Design app. No app implementation, simulator/device tests, App Review submission, daemon launch, installation, account connection, or external configuration changes were performed.

An iPhone custom keyboard can expose text capture and vault search inside permitted text fields. It cannot carry the entire multimodal promise by itself. A companion app, share extension, and optional system shortcuts are necessary product surfaces for the proposed experience. A Mac hotkey panel is plausible through native platform capabilities. Its exact behavior and permission requirements need an executable pilot.

## Source register

All web sources below were reviewed on 19 October 2026. “Current” means the live official documentation or policy, rather than an SDK behavior tested on a device. Some Apple pages exposed their full article in indexed results while the directly opened page returned a JavaScript shell; the Markdown fallback returned an unsupported-content-type error. These are documentation findings, not runtime verification.

| ID | Primary source | Status and relevance |
|---|---|---|
| P01 | [Apple: Configuring open access for a custom keyboard](https://developer.apple.com/documentation/uikit/configuring-open-access-for-a-custom-keyboard) | Current; network, app-group writes, Full Access, microphone restriction, user trust. |
| P02 | [Apple: Configuring a custom keyboard interface](https://developer.apple.com/documentation/uikit/configuring-a-custom-keyboard-interface) | Current; secure fields, phone pads, host opt-out, normal keyboard responsibilities. |
| P03 | [Apple: Handling text interactions in custom keyboards](https://developer.apple.com/documentation/uikit/handling-text-interactions-in-custom-keyboards) | Current; text proxy, insertion, deletion, nearby text context. |
| P04 | [Apple: App Review Guidelines, 4.4 and 4.4.1](https://developer.apple.com/app-store/review/guidelines/#extensions) | Current policy; keyboard purpose, degraded operation, activity collection. |
| P05 | [Apple: Virtual keyboards](https://developer.apple.com/design/human-interface-guidelines/virtual-keyboards) | Current HIG; installation, switching, where keyboards appear. |
| P06 | [Apple: Custom Keyboard, App Extension Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html) | Archived; Camera Roll/pasteboard capabilities, microphone prohibition, keyboard geometry. Historical corroboration, not sole authority for modern photo APIs. |
| P07 | [Apple: Understand How an App Extension Works](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionOverview.html) | Archived; extension lifecycle, camera/microphone exclusion with iMessage exception, unavailable APIs. |
| P08 | [Apple: Creating an App Extension](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionCreation.html) | Archived; termination, low memory, background task limitations. |
| P09 | [Apple: Share extensions](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Share.html) | Archived; share-sheet input and attachments, focused completion. |
| P10 | [Apple: Handling Common Scenarios](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html) | Archived; shared-container coordination and background URL transfers. |
| P11 | [Apple: Selecting Photos and Videos in iOS](https://developer.apple.com/documentation/photokit/selecting-photos-and-videos-in-ios) | Current sample documentation, associated with WWDC21; selected-media access, multiple selection, asynchronous asset loading. |
| P12 | [Apple: Accessing the event store](https://developer.apple.com/documentation/eventkit/accessing-the-event-store) | Current; calendar write-only/full access, reminder full access, EventKitUI alternative. |
| P13 | [Apple: Asking permission to use notifications](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications) | Current; authorization and changed settings. |
| P14 | [Apple: Scheduling a notification locally from your app](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app) | Current; system delivery when app is absent, cancellation, triggers. |
| P15 | [Apple: App Intents](https://developer.apple.com/documentation/appintents) | Current; expose app actions and entities through system experiences. |
| P16 | [Apple: App Shortcuts](https://developer.apple.com/design/human-interface-guidelines/app-shortcuts) | Current HIG, updated June 2026; Action button/Siri/Spotlight; distinguishes macOS App Intents support from App Shortcuts support. |
| P17 | [Apple: NSEvent.addGlobalMonitorForEvents](https://developer.apple.com/documentation/appkit/nsevent/addglobalmonitorforevents(matching:handler:)) | Current; global event observation, accessibility trust, own-app exception. |
| P18 | [Apple: NSPanel](https://developer.apple.com/documentation/appkit/nspanel) | Current; auxiliary/floating panel support. |
| P19 | [Apple Developer Forums: RegisterEventHotKey modifiers](https://developer.apple.com/forums/thread/763878) | Official forum; Apple Frameworks Engineer explains macOS Sequoia behavior. Thread also contains later contrary version-specific updates. Evidence that shortcuts need OS validation, not a stable modifier rule. |
| P20 | [MCP: Authorization](https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization) | Latest alias resolved to this version during review; OAuth, token audience, access scopes. |
| P21 | [MCP: Security Best Practices](https://modelcontextprotocol.io/docs/2026-07-28/tutorials/security/security_best_practices) | Latest alias resolved to this version; scope minimization, token passthrough, third-party authorization boundaries. |
| P22 | [MCP: Tools](https://modelcontextprotocol.io/specification/2026-07-28/server/tools) | Latest alias resolved to this version; model-controlled tools, visibility, human control, untrusted annotations. |
| P23 | Installed Open Design 0.25.0 package and bundled CLI | Local primary evidence; see exact files and read-only invocation below. |

## Capability matrix: iPhone

| Proposed promise | Official capability or constraint | Product implication |
|---|---|---|
| “Available wherever I type” | Secure fields and phone-pad/name-phone-pad fields switch to the system keyboard. Host apps can reject third-party keyboards entirely. [P02] | Say “inside supported text fields.” Provide capture/search entry points outside the keyboard. |
| “Always just there on my phone” | People enable the keyboard in Settings and switch between keyboards. It replaces the current text-input keyboard. [P05] | Installation and keyboard switching are real onboarding/habit costs. A keyboard does not create a universal overlay outside text input. |
| “Capture/search reaches my synchronized vault” | Default sandbox blocks network and shared-container writes; shared-container reads are permitted. User-enabled Full Access unlocks network and app-group sharing. [P01] | Separate basic operation, local availability, synchronization, and server search. Explain exactly why Full Access is requested. |
| “Works when Full Access is denied” | App Review 4.4.1 requires keyboard input, a next-keyboard control, functionality without network/Full Access, and limits activity collection to improving the keyboard. [P04] | A product that is only a cloud capture/search console in the keyboard has approval risk. Define a genuine basic keyboard/degraded experience. Policy compliance remains untested. |
| “Voice note recorded directly in this keyboard” | Current open-access docs list no microphone access and say open-access keyboards retain the preceding capabilities/restrictions. Archived keyboard docs explicitly exclude dictation. [P01, P06] | Exclude an in-keyboard microphone promise. Voice capture needs a companion recording surface or another explicitly supported flow. |
| “Use Apple dictation without leaving this keyboard” | No reviewed source establishes that a third-party keyboard can invoke system dictation while remaining the active keyboard. [P01, P06] | Treat switching to a system keyboard, invoking a shortcut, or opening a recorder as different interactions; test any proposed handoff before promising it. Speech transcription after capture is a separate capability. |
| “Take a photo directly in the keyboard” | Archived extension guide excludes camera access for non-iMessage extensions. It is not a modern keyboard-camera sample or current SDK proof. [P07] | Route camera capture to a native companion surface. Recheck current SDK availability before implementation; do not infer that Full Access grants camera access. |
| “Attach existing photos” | Archived keyboard guide lists Camera Roll access with permission under open access. Current Photos picker sample supports selecting multiple assets without general library authorization in an ordinary app. [P06, P11] | Existing-photo selection is more plausible than camera capture. Modern picker presentation inside the keyboard remains unverified. Promise selected-photo capture through companion/share surfaces first. |
| “As many pictures as possible” | Assets load asynchronously; large or off-device assets may take time. Extensions have lower memory budgets and may be terminated. [P11, P08] | Define generous explicit size/count limits and durable attachment progress. Avoid literal unlimited-media wording. |
| “Save the conversation or webpage I am looking at” | Keyboard proxy exposes text operations and context around insertion; it has no direct access to the host text object. [P03] | Do not promise whole-screen/chat/document reading. Use explicit selection, copy, or host-provided sharing. |
| “Put a search result into the current app” | Text proxy supports inserting/deleting text and moving the insertion point. [P03] | Text/link insertion is a supported direction. Arbitrary rich attachment insertion into every host is unverified; copying an image and asking the host to paste is a different UX. |
| “Attach images or links from another app with one capture action” | Share extension receives host-provided content/attachments through the sharing flow. The host decides what it supplies. [P09] | Share-sheet capture complements the keyboard. A link payload does not guarantee full page text or media; preserve what was actually supplied. |
| “Organizes indefinitely after I dismiss the keyboard” | Extensions are short-lived. Archived guidance permits background URL transfers but excludes general long-running tasks. [P07–P10] | Persist accepted capture before acknowledging it; finish indexing/synchronization through a component with an appropriate lifecycle. Background execution is not a perpetual keyboard process. |
| “The keyboard reminds me later” | Notifications need authorization; local requests are delivered by the system when the app is absent. [P13, P14] | Reminder delivery belongs to system scheduling/companion behavior. Distinguish saved content, scheduled notification, denied permission, and failed scheduling. |
| “A calendar event or reminder in a note becomes real” | Calendar writes can use write-only permission, which cannot read back even app-created events; reminder reads/writes require full reminder access. User-facing EventKitUI can create events without granting the app calendar access. [P12] | A saved intention and an external calendar/reminder effect require separate states. Show destination, interpreted time/timezone, and outcome. Direct EventKit use from the keyboard was not verified. |
| “Headless capture without visiting an app” | App Intents expose actions/entities to Siri, Spotlight, Shortcuts and other system surfaces; App Shortcuts can be attached to iPhone’s Action button. [P15, P16] | These are candidate fallback entry points for capture/search. Exposure, privacy and available presentation differ by surface. Support requires deliberate app work. |

The microphone constraint materially changes the iPhone blueprint: “keyboard as a frequent entry point” is feasible in principle; “keyboard contains every capture modality” is unsupported by the reviewed platform contract.

## Capability matrix: Mac and LLM clients

| Proposed promise | Evidence and constraint | Product implication |
|---|---|---|
| “A hotkey opens capture/search on Mac” | Native auxiliary/floating panels exist. Global event monitors can observe events in other apps; key monitoring requires accessibility trust and does not observe own-app events. [P17, P18] | A panel is plausible. Broad key monitoring and a narrowly registered hotkey are different mechanisms; do not claim Accessibility permission is inevitable for every hotkey approach. Choose/test a mechanism later. |
| “The shortcut works everywhere” | Official forum discussion records OS-specific hotkey modifier changes and later updates. [P19] | Test the supported OS range, keyboard layouts, collisions, full-screen spaces, and secure-input contexts. No exact shortcut or API is selected here. |
| “Results can be inserted into any Mac app” | A panel API and a global trigger do not establish permission to read another app or synthesize a paste into it. [P17, P18] | Copying is a useful baseline; insertion/context reading needs separate permission and compatibility research. |
| “Connect to any LLM app” | MCP standardizes tools and authorization; each host must support the needed transport/features. [P20, P22] | Replace “any” with named, verified integrations later. MCP availability alone does not establish host compatibility. |
| “Connect the vault without giving every tool unrestricted access” | MCP authorization binds tokens to the resource server; security guidance recommends incremental scopes and forbids token passthrough. [P20, P21] | Product-level proposal: separate search/read, append capture, modify/delete, export and external-action grants, with revocation. These are product decisions still to confirm, not scopes mandated verbatim by MCP. |
| “Let the LLM decide what to save or execute” | MCP tools may be model-controlled; the spec recommends visible tool exposure/invocation and human ability to deny operations. Tool annotations are untrusted unless from trusted servers. [P22] | Separate conversational inference from committed capture and external effects. Retrieved source text must remain data. Define user control and acknowledgments in the PRD. |

Sharing retrieved vault excerpts with an LLM provider is disclosure to that provider. A connector can enforce what it returns; the protocol alone does not decide the host’s retention, training or downstream handling. These need client-specific verification and product disclosure. This is a product inference about the integration boundary, not a universal provider-policy finding.

## Open Design: installed and callable; design workflow untested

Read-only evidence:

- `/Applications/Open Design.app/Contents/Resources/app/package.json` declares Open Design **0.25.0**.
- `/Applications/Open Design.app/Contents/Resources/open-design-config.json` points to the bundled daemon CLI.
- `/Applications/Open Design.app/Contents/Resources/app/prebundled/daemon/daemon-cli.mjs` loads `/Applications/Open Design.app/Contents/Resources/app/prebundled/daemon/chunks/cli-7SNYFKE6.mjs`.
- The chunk documents `od daemon start --headless --no-open` around line 10069, artifact creation around line 287, programmatic export around line 2704, and stdio MCP around line 3917.
- MCP help states that a packaged installation may start the signed desktop app headlessly when its daemon is stopped. Starting MCP is therefore a potential launch, rather than a purely read-only probe.

The following invocation was executed and exited **0**, printing CLI help without starting a daemon:

```sh
/Users/shomo/.nvm/versions/node/v22.12.0/bin/node \
  '/Applications/Open Design.app/Contents/Resources/app/prebundled/daemon/daemon-cli.mjs' \
  --help
```

Help confirms artifact creation and export to HTML/PDF/image/PPTX, a daemon, and a stdio MCP proxy. The bundled runtime targets Node 24 in its sidecar package; installed Node 22 successfully runs help, which does not prove full runtime compatibility.

**Do not invoke bare `od` in this environment:** the current executable lookup resolves `/usr/bin/od`, the Unix octal-dump utility. Use the explicit CLI entry/runtime path or establish the intended Open Design executable separately.

Conclusion: headless capability is shipped and CLI help is callable. A working daemon, project context, authentication, artifact import, render/export, and ability to choose output/state directories have **not** been tested. The CLI expects a daemon for project operations; starting it may create state outside the workspace. No setup or configuration mutation was attempted. The user can use Open Design via UI, or a later authorized runtime check can establish the headless workflow. ASCII/Mermaid blueprints remain usable immediately.

## Decisions this research leaves open

1. Is the keyboard a required default keyboard, or a deliberately switched-to capture/search keyboard? The habit and typing-quality requirements differ.
2. What remains useful without Full Access, network or a fresh synchronized index?
3. What is the fewest-step voice/camera fallback that still fits the “travels with me” promise?
4. Does capture of a task/event only retain the thought, or also create and maintain an executable object? What proves completion of that effect?
5. Which vault material may external LLM clients read, and which actions can they perform without another confirmation?
6. Does “headless” mean no organization interface in daily use, or no companion/admin/recovery surface at all? Platform constraints support the former interpretation.

These are vision decisions. The reviewed sources constrain their answers but do not settle them. Before implementation promises, device tests must validate shared-container capture durability, keyboard-local drafting/privacy, permissions revoked mid-flow, attachment limits, voice handoff, search latency under extension memory pressure, and cross-device consistency. No framework, database, search engine, model or cloud stack is selected by this report.

## Follow-up: local-first capture, organization, retrieval and paid sync

Reviewed 20 October 2026. These are product possibilities supported by five primary sources; no implementation or business-model decision is made.

| ID | Primary source | What it establishes |
|---|---|---|
| P24 | [Ink & Switch: Local-first software](https://www.inkandswitch.com/essay/local-first/) | Device copies can be primary, work offline, and synchronize later through secondary server copies. This is the original 2019 design essay, not a statement about a current app’s implementation. |
| P25 | [Obsidian: Sync security and privacy](https://help.obsidian.md/Obsidian+Sync/Security+and+privacy) | Existing encrypted-sync example: devices encrypt before transmission and decrypt on another device; default E2EE prevents the service reading note content. Local vault encryption is separate, and some synchronization metadata remains server-readable. |
| P26 | [SQLite: FTS5](https://www.sqlite.org/fts5.html) | Embedded full-text indexes support term/phrase/prefix/proximity/Boolean queries, ranking and snippets. This supplies evidence for device-local lexical retrieval; it does not establish semantic understanding. |
| P27 | [Apple: NLEmbedding](https://developer.apple.com/documentation/naturallanguage/nlembedding) | Word/sentence vectors, distance and nearest-neighbor operations can represent similarity; custom embeddings can use an efficient searchable on-disk form. It does not prove retrieval quality for this app’s content. |
| P28 | [Apple: Generating content and performing tasks with Foundation Models](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models) | An on-device model can perform tasks including tagging, classification and summarization. Availability depends on device/region and readiness; Apple directs developers to check availability and provide fallback. |

### Five independent promises

| Question | Product meaning |
|---|---|
| Where is my material saved? | A successful capture survives locally without contacting a service. Originals and attachments remain accessible when offline. [P24] |
| Where is my search index and organization produced? | Local indexes can support offline search. Rules and optional local inference can produce replaceable tags, entities or similarity representations. Lexical indexing, semantic embedding and generative organization are separate jobs. [P26–P28] |
| Where does model processing run? | On-device processing is possible on supported hardware, but suitability for mixed personal notes, languages, images, speech, battery use and keyboard-extension memory is untested. A local model need not be an always-running chatbot. [P28; product inference] |
| What can the sync service read? | Encrypted replication can transmit ciphertext to an intermediary and decrypt on authorized devices. Content encryption, metadata exposure and recovery policy must each be stated. [P25] |
| What does a chat provider receive? | A connected cloud chat client receives whatever authorized content the integration returns. That disclosure is independent of local storage and encrypted sync. A local chat client with local inference could keep this processing on-device, subject to the client’s actual behavior. [Inference from the integration boundary described above; client-specific verification required.] |

### How “local, with sync” works

```text
Capture on phone -> save phone copy -> continue offline
                           |
                    connection available
                           v
                 encrypt changes on phone
                           |
                  sync service holds ciphertext
                           |
                    authorized Mac downloads
                           v
                 decrypt -> save Mac copy
                           |
                   search Mac copy locally
```

This diagram combines the local-first role of replicas [P24] with an encrypted-sync example [P25]; it is a proposed behavior, not a selected protocol. The sync product must also handle simultaneous changes, deletions, missing attachments, device authorization and recovery. A synchronized deletion can propagate, so synchronization and recoverable backup need separate promises.

### Product boundary worth testing

**Free local capture and retrieval; paid synchronized copies** is coherent as a product hypothesis. Free local saving/search would remain usable offline and after a sync subscription ends. Paid sync could deliver copies and changes between authorized devices. Optional cloud inference would have its own explicit disclosure and commercial boundary. This is a monetization hypothesis, not evidence that customers will pay or that delivery is costless.

Organization can happen after capture without requiring the user to file anything: retain the original, index it, then add inferred metadata and similarity links when processing is available. Failure or delay of this enrichment should leave saving and baseline retrieval usable. This is a recommended product behavior for discussion, rather than a benchmarked quality claim.

The free promise still needs a crisp search definition: offline lexical retrieval is supported in principle [P26]; offline semantic retrieval depends on suitable local representations and evaluation [P27]; cloud-quality open-ended answers on every iPhone are unproven [P28]. A compatible local chat connector needs a functioning local retriever and verified client support; neither requires uploading the entire vault by definition. E2EE sync alone cannot promise private cloud AI, because authorized plaintext excerpts can leave a device through the chat integration.

## Follow-up: Chat as an iPhone keyboard mode

Reviewed 20 October 2026 against four official sources already registered: [keyboard layout, P02](https://developer.apple.com/documentation/uikit/configuring-a-custom-keyboard-interface), [text interaction, P03](https://developer.apple.com/documentation/uikit/handling-text-interactions-in-custom-keyboards), [App Review 4.4.1, P04](https://developer.apple.com/app-store/review/guidelines/#extensions), and the [archived keyboard guide, P06](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html). No device, scrollable transcript, private composer, model execution or App Review test was performed.

**Capture / Find / Chat** can be the product's keyboard modes. A compact conversation is plausible inside the custom keyboard view. A guaranteed one-tap expansion into the containing app is unsupported by this review.

| Concern | Documented boundary | Product consequence |
|---|---|---|
| Height and screen space | UIKit sets keyboard width; Auto Layout can adjust the primary view's height. The interface must adapt to available space. [P02] | An expanded keyboard layout is possible in principle. No exact height or full-screen takeover is promised. Test portrait/landscape and small screens. |
| Chat transcript and composer | Archived guidance allows views, controls and gestures inside the primary keyboard view and confines drawing to that view. [P06] | A scrollable transcript is an ordinary custom-view design candidate, rather than an explicitly documented Chat capability. Its scrolling, internal text composition, selection and typing focus require a device pilot. |
| Interaction with host text | The text proxy inserts/deletes strings, adjusts the cursor and exposes nearby/selected text. [P03] | Chat drafting should have its own explicit destination. “Send to chat” must not silently insert private prompts into the foreground app; inserting an answer there should be a separate user action. |
| Launch companion app | App Review 4.4.1 says keyboard extensions must not “Launch other apps besides Settings.” [P04] | Do not specify an “Open full chat” button that launches the companion from the keyboard. No containing-app exception or supported launch path was established. No workaround is proposed. |
| Remain a functioning keyboard | 4.4.1 requires input functionality, switching keyboards and useful operation without network/Full Access; it also prohibits repurposing keyboard buttons for unrelated behavior. [P04] | Present Chat with explicit mode controls while preserving keyboard duties. Rich UI feasibility does not establish review acceptance. |

Recommended product framing: **chat briefly within the keyboard; open the companion separately for longer conversations.** A saved conversation could be available there through shared app data, subject to permission, durable state and implementation validation. This describes continuity of data, not a proven navigation handoff. Temporary chat remains an accepted mode; retention, transcript clearing and whether anything can appear in the companion need their own explicit contract. Existing keyboard network, lifecycle, memory and host exclusions still apply. No implementation choice is made here.
