# Reusable macOS floating overlay components

Verified 2026-10-23. Scope: the UI component only—persistent collapsed desktop anchor, dragging, expansion into an editable panel and restored position. Source inspection only; no app was installed or executed, and no product/backend dependency was adopted. GitHub stars below were read from the public repository API during this research; they indicate adoption, not verified quality.

## Result

**Wisp's native island and panel controllers are the closest permissively licensed extraction candidate found.** Extract their UI geometry and lifecycle code behind our existing workspace interface. They need one substantive change: opening the editor from the island's actual position. Wisp currently gives its island and editor separate stored positions.

No substantially adopted native Swift package examined supplied the entire requested interaction unchanged. Boring Notch has greater adoption but deliberately fixes its panel to the notch and refuses key focus. The `tauri-nspanel` library supplies real reusable window infrastructure if we choose Tauri, although it leaves collapsed/expanded state and placement to our UI. None of these findings requires adopting the source application's chat, screen capture, inference or telemetry.

## Behavior matrix

| UI source | Runtime/license; adoption | Persistent collapsed anchor | Editable expansion | Drag position across relaunch | Fit |
|---|---|---|---|---|---|
| Wisp island + panel controllers | Swift/AppKit/SwiftUI; MIT; **168 stars** | Yes: desktop island, optional fixed notch | Separate keyable panel; collapsed composer and expanded conversation sizes | Island anchor and panel frame are stored separately | Closest native extraction; join the geometry |
| Boring Notch window + view model | Swift/AppKit/SwiftUI; GPL-3.0; **11,109 stars** | Yes: notch surface | Existing `BoringNotchWindow` cannot become key | Source window is explicitly not movable | Established state/animation reference; unsuitable unchanged |
| `tauri-nspanel` | Rust/Objective-C/Tauri webview; MIT/Apache-2.0; **427 stars shown by GitHub** | Application must implement | Configurable keyable NSPanel | Application must implement | Reusable primitive; adds a runtime to our Swift client |
| Cherry Studio QuickAssistant window infrastructure | Electron/TypeScript; AGPL-3.0; **52,887 stars** | No persistent collapsed anchor established | Yes: hotkey assistant and pinning | Window bounds are remembered | Useful window lifecycle reference; incomplete dock behavior |
| Docky window controllers | Swift/AppKit; GPL-3.0; **1,377 stars** | App dock, with widget surfaces | No matching note-editor expansion established | Arbitrary dragged-anchor persistence unverified | Actual dock implementation; extra window-management machinery |

Sources: [Wisp](https://github.com/ycl-2004/Wisp), [Boring Notch](https://github.com/TheBoredTeam/boring.notch), [tauri-nspanel](https://github.com/ahkohd/tauri-nspanel), [Cherry Studio](https://github.com/CherryHQ/cherry-studio), [Docky](https://github.com/josejuanqm/docky).

## Wisp: extract these components, preserve our application

Inspected commit: `1e86359aa1dd69e31fed260f61e8f5a16fd7a79c` (2026-09-16). MIT license: retain its notice for copied code. Source files were read at that revision in a temporary research directory.

- [`Wisp/UI/IslandController.swift`](https://github.com/ycl-2004/Wisp/blob/1e86359aa1dd69e31fed260f61e8f5a16fd7a79c/Wisp/UI/IslandController.swift): NSPanel lifetime, display-change relayout, dragged anchor, reset/migration. `dragChanged()` reads the cursor position; `dragEnded()` stores `AppSettings.shared.islandAnchor`. Missing displays fall back to a valid default anchor.
- [`Wisp/UI/IslandLayout.swift`](https://github.com/ycl-2004/Wisp/blob/1e86359aa1dd69e31fed260f61e8f5a16fd7a79c/Wisp/UI/IslandLayout.swift) and [`IslandModel.swift`](https://github.com/ycl-2004/Wisp/blob/1e86359aa1dd69e31fed260f61e8f5a16fd7a79c/Wisp/UI/IslandModel.swift): compact/hover/generating geometry and UI state. Replace generating-specific state with our selected mode and expansion state.
- [`Wisp/UI/PanelController.swift`](https://github.com/ycl-2004/Wisp/blob/1e86359aa1dd69e31fed260f61e8f5a16fd7a79c/Wisp/UI/PanelController.swift): borderless nonactivating keyable panel, all-Spaces/fullscreen auxiliary behavior, collapsed/expanded heights, frame restoration, drag/resize persistence. Frame saves are debounced after move/resize. It explicitly returns `canBecomeKey = true`.
- Supporting code to inspect during extraction: [`ScreenGeometry.swift`](https://github.com/ycl-2004/Wisp/blob/1e86359aa1dd69e31fed260f61e8f5a16fd7a79c/Wisp/Support/ScreenGeometry.swift), [`AppSettings.swift`](https://github.com/ycl-2004/Wisp/blob/1e86359aa1dd69e31fed260f61e8f5a16fd7a79c/Wisp/Support/AppSettings.swift), `IslandView.swift`, `PanelResize.swift`. File existence was verified; this research did not fully audit every supporting implementation.

**Gap:** `PanelController.show()` hides the island, records the previous application and invokes Wisp's screenshot/model flow before presenting its own editor. `position()` restores its own origin or a default panel frame. Replace those product calls with presentation of our Capture/Find contents, and pass the island's anchor into one shared placement function. Keep screen-capture code out of the extracted component. [Panel presentation source](https://github.com/ycl-2004/Wisp/blob/1e86359aa1dd69e31fed260f61e8f5a16fd7a79c/Wisp/UI/PanelController.swift#L29).

Proposed isolated interface: show collapsed anchor; expand with supplied content/focus action; collapse without losing drafts; move anchor; restore/clamp geometry. This is an extraction proposal requiring build/UI validation, not an implemented component or a maturity claim.

## Established sources: the exact reusable boundary

**Boring Notch**, commit `23e7705a4ffcb5d97a54fb1d4135e180084a566d` (2026-10-18): [`boringNotch/components/Notch/BoringNotchWindow.swift`](https://github.com/TheBoredTeam/boring.notch/blob/23e7705a4ffcb5d97a54fb1d4135e180084a566d/boringNotch/components/Notch/BoringNotchWindow.swift) is only about 50 lines and illustrates floating level, transparency and Spaces flags. It sets `isMovable = false`, `canBecomeKey = false` and `canBecomeMain = false`. Relevant expansion/state files are `ContentView.swift` and `models/BoringViewModel.swift`; their existence was verified. This is a fixed-notch implementation. Copying GPL code entails the corresponding license obligations; no copying has occurred.

**tauri-nspanel**: maintained `v2.1` branch advertises a `PanelBuilder`, window conversion, enter/exit/mouse movement handling and keyable panels. It names Handy among downstream users. This is an actual windowing library rather than an entire assistant fork. Source begins at [`src/`](https://github.com/ahkohd/tauri-nspanel/tree/v2.1/src). We did not pin its current commit or test it. It supplies the platform primitive; our app still owns persistent anchor geometry, editor focus, dragging and transitions. [API and examples](https://github.com/ahkohd/tauri-nspanel/tree/v2.1).

**Cherry Studio**, commit `41c240712e28ff03d17115e522a5394e605fe374` (2026-10-22): [`src/main/services/QuickAssistantService.ts`](https://github.com/CherryHQ/cherry-studio/blob/41c240712e28ff03d17115e522a5394e605fe374/src/main/services/QuickAssistantService.ts), `src/main/core/window/WindowManager.ts`, `windowBoundsTracker.ts` and `windowRegistry.ts` separate assistant policy from window creation/restored bounds. Inspected assistant code handles pin/blur hide and cursor-display repositioning. It repositions to the cursor's **display**, not the host text caret. A permanent collapsed desktop anchor was not established. Electron and AGPL obligations make transplanting this into Swift a larger decision than extracting native controllers.

**Docky**, commit `44bf925639e079c5edf8284fd8edc2c157349ee5` (2026-09-30): source paths include `Docky/Views/MainWindow/MainWindow.swift`, `MainWindowController.swift`, `WidgetExpansionWindowController.swift`. Its README identifies private SkyLight/CoreGraphics/Accessibility SPI and says it cannot be distributed through the Mac App Store. The app is an example of a real desktop dock; it does not establish our editable anchored pad interaction. [Runtime and distribution constraints](https://github.com/josejuanqm/docky/tree/44bf925639e079c5edf8284fd8edc2c157349ee5).

## Boundaries and next proof

`scenee/FloatingPanel` is a UIKit sheet/container, despite its name; its controller imports UIKit and subclasses UIViewController. It cannot directly become a global macOS desktop dock. [Source](https://github.com/scenee/FloatingPanel/blob/master/Sources/Controller.swift).

Droppy's repository returned HTTP 451 during direct inspection. Its public product documentation describes notch/island interactions, but this research does not establish accessible current source/license suitable for reuse. No attempt was made to bypass that restriction.

A native extraction pilot should demonstrate: visible collapsed anchor across apps; drag to any screen edge; relaunch restores a clamped position; click expands an editable pad from that same anchor; typing and selection work; Escape collapses while preserving the draft; expansion grows into available space; the host regains focus; fullscreen/Spaces/display changes remain usable. Accessibility-based near-caret placement is an additional behavior to validate independently. No screen capture or reading host text is needed merely to implement the dock/pad component.
