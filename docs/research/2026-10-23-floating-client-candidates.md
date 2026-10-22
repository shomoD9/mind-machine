# Established donors for the Mac floating capture/recall surface

Research date: 23 October 2026. Scope: wider GitHub search across dictation apps, desktop AI assistants, launchers and floating-window libraries. No models were installed, no upstream app was run, and no production code changed. All feature statements below distinguish inspected source from product claims.

## Recommendation

**OpenWhispr is the strongest active permissively licensed full-app reference found for a draggable pill that grows into an assistant panel.** Its 9,761-star MIT repository contains actual dragging, focus, window resizing and multi-display handling. It uses Electron/React; adopting its complete application would replace our native client architecture and bring dictation, providers and account features we do not need.

**For a small Swift component, inspect/extract HuggingChat's Apache-2.0 `FloatingPanel.swift` first, and evaluate Pindrop's MIT orb/geometry code.** HuggingChat has 1,954 stars and Pindrop has 623; both are archived. They offer relevant AppKit code without requiring a new UI runtime. Active native VoiceInk has 6,900 stars and relevant panel code, but its GPLv3 license requires an explicit distribution/licensing choice before copying.

The complete always-present draggable anchor plus anchored editable expansion remains an adaptation. A temporary recording indicator alone does not meet the user's requirement. This comparison concerns UI mechanics only; the surrounding apps' audio, chat, search and sync features have no bearing on that fit.

## Form-factor component matrix

Only shell behavior matters in this comparison. Audio and AI functions are outside the reuse scope. “Source” means code inspection; no runtime test was performed.

| Donor | Persistent idle anchor | Drag | Persisted position | Expansion at anchor | Editable focus | Collapse / focus return |
| --- | --- | --- | --- | --- | --- | --- |
| HuggingChat FloatingPanel | Must adapt; pinned panel can remain | Source | Frame autosave configured; restart behavior untested | Resizable/snapping panel; collapsed anchor must adapt | Source, key-capable | Source closes on focus loss unless pinned; return behavior untested |
| Pindrop orb | Source has explicit idle indicator; application policy partly untraced | Source, raw event threshold | Source, AppStorage X/Y offsets | Source grows transcript around orb and clamps frame; editor adaptation needed | Recording orb is nonactivating; add editable expansion | Session show/hide exists; adapt for capture/recall |
| VoiceInk PersistentQuickPanel | Must adapt; persistent geometry does not mean permanent visibility | Source, background | Source, UserDefaults | Source keeps top edge while resizing; collapsed anchor must adapt | Source, key-capable | Source dismissal callbacks / resign-key behavior; return untested |
| OpenWhispr main pill | Startup/idle permanence unproven | Source | In-session ownership source; restart persistence unproven | Source restores pre-grow bounds; anchored resizing | Source sets focusability when expanded | Source switches focusability; macOS activation deliberately avoided |
| Handy recording overlay | Hidden by default; transient states | Arbitrary drag absent in inspected module | Top/bottom preference; no arbitrary coordinate persistence established | State resizing at screen edge | Nonfocusable display surface | Show/hide for recording lifecycle |

**Concrete extraction recommendation:** use HuggingChat's small AppKit `FloatingPanel.swift` as the initial panel donor, then evaluate Pindrop's MIT idle-orb dragging and persisted-offset geometry as a separate component. Preserve our own capture and recall content. An always-visible collapsed anchor is an explicit adaptation to test; neither file is being presented as the complete app.

## Verified repository snapshots

Exact counts came from GitHub's public API during this research; they describe repository adoption signals and can change. Stars provide no direct evidence of reliability or latency.

| Repository | Stars | License checked | Status / checked commit |
| --- | ---: | --- | --- |
| [OpenWhispr/openwhispr](https://github.com/OpenWhispr/openwhispr) | 9,761 | [MIT](https://github.com/OpenWhispr/openwhispr/blob/4c648dd5d83188395a304b0b343e2f57ded581e7/LICENSE) | Active; `4c648dd5d83188395a304b0b343e2f57ded581e7`, pushed 22 Oct 2026 |
| [cjpais/Handy](https://github.com/cjpais/Handy) | 34,365 | [MIT](https://github.com/cjpais/Handy/blob/5a9451e70aedc90648ce2befd9d7e0304746f9c1/LICENSE) | Active; `5a9451e70aedc90648ce2befd9d7e0304746f9c1`, pushed 22 Oct 2026 |
| [Beingpax/VoiceInk](https://github.com/Beingpax/VoiceInk) | 6,900 | [GPLv3 header and link](https://github.com/Beingpax/VoiceInk/blob/22e5ec5479b712797c3b338fcb875961e58800b6/LICENSE); API says NOASSERTION because file is abbreviated | Active; `22e5ec5479b712797c3b338fcb875961e58800b6`, pushed 21 Oct 2026 |
| [watzon/pindrop](https://github.com/watzon/pindrop) | 623 | [MIT](https://github.com/watzon/pindrop/blob/8044a15b896c2d0aacdd262649947f19d0ea6fae/LICENSE) | Archived 4 Oct 2026; `8044a15b896c2d0aacdd262649947f19d0ea6fae`; README says replaced by Sayso |
| [huggingface/chat-macOS](https://github.com/huggingface/chat-macOS) | 1,954 | [Apache-2.0](https://github.com/huggingface/chat-macOS/blob/7d13a41b5f8344ae9361ac252fd41905df59a0b0/LICENSE.md) | Archived; last push 3 Feb 2025; `7d13a41b5f8344ae9361ac252fd41905df59a0b0` |
| [chatboxai/chatbox](https://github.com/chatboxai/chatbox) | 42,108 | [GPL-3.0](https://github.com/chatboxai/chatbox/blob/0ac6385ae1ff5bf778777826da3c5edcd55b61b8/LICENSE) | Active; `0ac6385ae1ff5bf778777826da3c5edcd55b61b8`, pushed 24 Sep 2026 |
| [scenee/FloatingPanel](https://github.com/scenee/FloatingPanel) | 5,822 | [MIT](https://github.com/scenee/FloatingPanel/blob/de51f81e938d0a04a073582c69f13eaae10dc7cb/LICENSE) | Active; `de51f81e938d0a04a073582c69f13eaae10dc7cb` |

Metadata can be refreshed from each official repository's `/repos/{owner}/{name}` [GitHub API](https://docs.github.com/en/rest/repos/repos#get-a-repository). Pins were obtained from its commits API and recursive source tree. The previously suggested `Beingpawan/VoiceInk` address did not resolve in this check; the verified canonical repository is `Beingpax/VoiceInk`.

## OpenWhispr: strongest active MIT interaction donor

Actual source inspected:

- [`src/helpers/windowManager.js`](https://github.com/OpenWhispr/openwhispr/blob/4c648dd5d83188395a304b0b343e2f57ded581e7/src/helpers/windowManager.js): creates the main dictation window; tracks assistant panel state; makes it focusable for text input; avoids macOS app activation; restores the collapsed pre-expansion bounds; tracks manual dragging and cancels stale asynchronous placement.
- [`src/helpers/windowConfig.js`](https://github.com/OpenWhispr/openwhispr/blob/4c648dd5d83188395a304b0b343e2f57ded581e7/src/helpers/windowConfig.js): transparent frameless always-on-top overlay, initially hidden and nonfocusable. All-workspace/full-screen visibility is reapplied when lost. The relevant content is an Electron `BrowserWindow`, with a macOS panel configuration.
- [`src/helpers/dragManager.js`](https://github.com/OpenWhispr/openwhispr/blob/4c648dd5d83188395a304b0b343e2f57ded581e7/src/helpers/dragManager.js): cursor-offset dragging, ~16 ms tracking during drag, work-area clamping on the destination display.
- [`src/helpers/mainWindowPlacementCoordinator.js`](https://github.com/OpenWhispr/openwhispr/blob/4c648dd5d83188395a304b0b343e2f57ded581e7/src/helpers/mainWindowPlacementCoordinator.js): manual-position ownership and rejection of superseded placement requests. The inspected coordinator stores state in memory; restart persistence of an arbitrary dragged position is unproven.
- [`src/components/dictation/ExpandingPanelShell.tsx`](https://github.com/OpenWhispr/openwhispr/blob/4c648dd5d83188395a304b0b343e2f57ded581e7/src/components/dictation/ExpandingPanelShell.tsx): measured content expansion; [`VoicePill.tsx`](https://github.com/OpenWhispr/openwhispr/blob/4c648dd5d83188395a304b0b343e2f57ded581e7/src/components/dictation/VoicePill.tsx): compact pill UI.

**Visibility correction:** `AgentDictationPillOverlay.tsx` is a companion to an open assistant. `showAgentDictationPill()` returns unless `_assistantPanelOpen`; closing the assistant hides the companion. Its position is the opposite bottom edge of the main window's display. It is not proof of an always-visible anchored island. The main pill's complete startup/idle policy needs further runtime verification. [Companion source](https://github.com/OpenWhispr/openwhispr/blob/4c648dd5d83188395a304b0b343e2f57ded581e7/src/components/dictation/AgentDictationPillOverlay.tsx).

**Decision:** extract lifecycle/geometry ideas or isolate MIT modules if retaining Electron becomes a deliberate decision. For our existing AppKit application, use it as a source reference and implement equivalent native geometry against our vault interface. Do not port its account, telemetry, recording or remote-provider flows as a side effect.

## Handy: established MIT overlay, narrower interaction

[`src-tauri/src/overlay.rs`](https://github.com/cjpais/Handy/blob/5a9451e70aedc90648ce2befd9d7e0304746f9c1/src-tauri/src/overlay.rs) creates a macOS nonactivating panel through Tauri, at status level with all-Spaces/full-screen behavior. It starts hidden, uses top/bottom placement preferences and resizes for recording/streaming/transcribing/processing. [`RecordingOverlay.tsx`](https://github.com/cjpais/Handy/blob/5a9451e70aedc90648ce2befd9d7e0304746f9c1/src/overlay/RecordingOverlay.tsx) implements those visual states.

This is a recording-state surface. The inspected files provide no arbitrary draggable persistent anchor or capture/recall editor. **Decision: reference**, especially for native panel flags and multi-display placement; a wholesale Tauri migration is unjustified for this UI alone. Its greater star count does not make the recording overlay a better exact match than OpenWhispr's expanding panel.

## VoiceInk: active native panel donor with GPL choice

[`PersistentQuickPanel.swift`](https://github.com/Beingpax/VoiceInk/blob/22e5ec5479b712797c3b338fcb875961e58800b6/VoiceInk/App/Windows/PersistentQuickPanel.swift) is a small AppKit `NSPanel`: nonactivating, floating, key-capable, draggable by background, all Spaces/full-screen, saved origin in `UserDefaults`, visibility validation on restore, and top-edge-preserving animated resize. It can request dismissal on losing key status; “persistent” in its name does not establish a permanent idle dock.

The recording-specific [`MiniRecorderPanel.swift`](https://github.com/Beingpax/VoiceInk/blob/22e5ec5479b712797c3b338fcb875961e58800b6/VoiceInk/Features/Recording/Presentation/MiniRecorderPanel.swift) and [`MiniWindowManager.swift`](https://github.com/Beingpax/VoiceInk/blob/22e5ec5479b712797c3b338fcb875961e58800b6/VoiceInk/Features/Recording/Presentation/MiniWindowManager.swift) create and tear down recorder panels between dictations. They should not be described as a permanent anchor either.

**Decision: reference; copy only after an explicit GPL distribution decision or separate permission.** A source-visible paid app can be open source. It still has licensing obligations. This research does not establish any separate commercial license for embedding these files.

## HuggingChat: small native Apache-2.0 component

[`HuggingChat-Mac/Views/FloatingPanel.swift`](https://github.com/huggingface/chat-macOS/blob/7d13a41b5f8344ae9361ac252fd41905df59a0b0/HuggingChat-Mac/Views/FloatingPanel.swift) is AppKit code with a nonactivating/resizable panel, floating level, all-Spaces/full-screen behavior, draggable background, frame autosave name, explicit drag/snap handling and corner snapping. It allows keyboard focus. It closes on focus loss unless its pinned/focused state says otherwise.

**Decision: first small-module extraction candidate for the existing Swift client**, subject to a focused review and retained Apache notices. It supplies panel mechanics; our persistent collapsed affordance, bounded expansion and vault contents still need adaptation. Archival and old source mean modern macOS behavior must be checked. No performance or security conclusion follows from the repository's organization or stars.

## Pindrop: closest permissive native orb mechanics, archived

[`OrbFloatingIndicator.swift`](https://github.com/watzon/pindrop/blob/8044a15b896c2d0aacdd262649947f19d0ea6fae/Pindrop/UI/OrbFloatingIndicator.swift) provides `showIdleIndicator()`, a nonactivating all-Spaces/full-screen floating orb, raw window-event tap-versus-drag discrimination, drag offset storage, clamped placement and an expanded live transcript surface. This is genuine idle-indicator capability, though its application-wide enable/disable policy has not been fully traced.

[`SettingsStore.swift`](https://github.com/watzon/pindrop/blob/8044a15b896c2d0aacdd262649947f19d0ea6fae/Pindrop/Services/SettingsStore.swift) backs the X/Y offsets with `@AppStorage`, proving persisted geometry. [`FloatingIndicatorShared.swift`](https://github.com/watzon/pindrop/blob/8044a15b896c2d0aacdd262649947f19d0ea6fae/Pindrop/UI/FloatingIndicatorShared.swift) has shared pointer routing and a four-point drag threshold.

**Decision: selective MIT extraction candidate**, alongside HuggingChat; exclude audio pipelines, live transcription and recording state. It is more directly relevant to a draggable idle orb than a general launcher, but archival requires us to own maintenance. It provides no existing semantic note-vault UI.

## Assistants and libraries screened

**Chatbox**, 42,108 stars, is a broader GPL-3.0 desktop AI client. Its inspected source tree does not establish an always-visible draggable idle dock. It brings a separate application runtime and licensing decision. **Reference only**; no claim it matches our form factor. [Pinned tree](https://github.com/chatboxai/chatbox/tree/0ac6385ae1ff5bf778777826da3c5edcd55b61b8).

**scenee/FloatingPanel**, 5,822 stars and MIT, is an iOS in-app sheet/controller library. Its name does not make it a Mac system-wide overlay or an iPhone keyboard extension. **Exclude as the Mac shell donor.** [Pinned README](https://github.com/scenee/FloatingPanel/blob/de51f81e938d0a04a073582c69f13eaae10dc7cb/README.md).

## Adoption gate

Choose native Swift extraction first to preserve our existing client and avoid introducing another runtime for window chrome. A pilot must prove: persistent collapsed anchor; drag versus click; saved placement after restart; inward expansion near screen edges; focus handoff; draft preservation; multiple monitors, Spaces and full-screen apps; safe behavior after sleep/wake; and bounded CPU/RAM while idle. Measure those locally. Then connect capture and indexed recall through our shared service interface.

All candidates in this report were researched through official source, license files and GitHub API metadata. None was built or runtime-tested in this research. This broader search includes substantially adopted repositories; their popularity does not resolve the missing UI behaviors or establish code quality. The human explicitly permits building a small native component if reuse does not earn its place.
