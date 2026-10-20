# Native MVP design

Open [native-mvp.figcraft](native-mvp.figcraft) in FigCraft. The canvas is the current design source. The earlier browser preview is superseded.

The human requested functional, clean industrial minimalism, entirely greyscale, with no brand-kit work. This pass concentrates on state and controls. It contains 23 top-level frames: six primary keyboard states, three pad-size states, two typing-destination states, eight secondary companion states, three Mac panels, and a component shelf. Five actual components are used by linked instances; five prototype flows connect the main states. The canvas has 1,265 editable nodes. The opening page is **01 · Keyboard first**, followed by **02 · Pad sizes**, **03 · Typing destination**, **04 · Mac hotkey**, **05 · Companion and setup**, and **06 · Components**.

![Keyboard Capture](<exports/Keyboard _ Capture.png>)

## Primary keyboard and sizing

The notepad is the everyday capture surface, inside the keyboard extension above the keys. Find opens the original within the keyboard; Insert is explicit. Maya in the earlier mock was a fictional contact in the host app, never the app name. Current screens use EXAMPLE HOST APP.

[Compare pad sizes](pad-sizes.png): Minimised, Default and Expanded show the same note/caret. The collapsed note still receives typing when Note is active; minimising alone does not switch to App. These are sizing targets, not measured iPhone height limits. The Size prototype hotspot cycles through the three examples; final control presentation still needs implementation. Mac window resizing/fullscreen and inheriting another keyboard are described in the [roadmap](../ROADMAP.md).

## Composer and focus correction

The host composer now follows the top of the complete keyboard workspace in every size, including Expanded. It stays visible in these representative mocks; actual host layout belongs to that app. [Compare destinations](typing-destination.png): tap the host field to select App or tap the note to select Note. The caret, active border and destination indicator change together. Size changes preserve the selected destination. These are designed states; native focus handling is not validated.

The tappable Typing indicator is a proposed safeguard for cases where host taps are not observable. The native experiment must check unchanged-caret taps and a private text view’s responder transitions before promising tap-only switching across all hosts. [Platform research](../../.scratch/scattered-ambitious-pitch/research/25-keyboard-focus-and-host-layout-2026-10-20.md).

## Files

- [Overview](overview.png) and [screen exports](exports): CLI-rendered review images.
- [Command generator](build_design.py): narrated source for the canvas.
- [Command stream](native-mvp.commands.json) and [manifest](native-mvp.manifest.json): reproducible engine commands and stable node identifiers.
- [SwiftUI export sample](PrimaryButton.generated.swift): actual `inspect.code` output for the main button, with a provenance header. It establishes a structural handoff path; it is not tested application behavior or production-ready code generation.

## Rebuild

The installed CLI is `/Users/shomo/Downloads/figcraft-cli-0.5.1-macos-universal/figcraft-cli` (version 0.5.1). It is not currently on PATH.

```sh
python3 docs/design/build_design.py
/Users/shomo/Downloads/figcraft-cli-0.5.1-macos-universal/figcraft-cli run docs/design/native-mvp.commands.json --out docs/design/native-mvp.figcraft
/Users/shomo/Downloads/figcraft-cli-0.5.1-macos-universal/figcraft-cli export docs/design/native-mvp.figcraft -o docs/design/exports --scale 1.5
```

All design-build commands succeeded. The native file was reopened by `info`, components enumerated, screens rendered, and keyboard/phone/Mac exports visually inspected. The full prototype has not been manually played through in the GUI: CUA access to FigCraft was unavailable. Headless file creation and rendering succeeded independently.

The installed version does not accept the newer documentation's symbolic `$step` references in every command. The generator therefore uses numeric IDs. Instance descendants cannot be resized individually in this version; compact and Mac button sizes have their own reusable components.

## Scope

These are design states with fictional data. Synced labels, search results, reminder outcomes, and conversation text are examples, not runtime results. The keyboard design makes vault input distinct from the host-app message. Implementation still needs selection handling, shift/delete behavior, language support, accessibility targets, and real-device tests. No resurfacing card is placed in the keyboard.

The companion screens support setup/settings and exceptional capture paths; they are not the primary phone workflow.

The private native pilot includes iPhone keyboard, Mac global hotkey and cross-device private sync. The user rejected a browser fallback. A private pilot limits audience/distribution; it does not remove those features.

## FigCraft versus Figma free

For this task, FigCraft passed a concrete create → component instance → save → reopen → render → inspect SwiftUI test. No switch is needed on current evidence. Figma's official direct canvas-writing documentation lists Professional, Education, Organization and Enterprise access; Starter has limited MCP read calls. This is a comparison of our available automation path, not a claim that FigCraft matches Figma in every workflow or that third-party Figma plugin routes cannot work.

Sources checked on 20 October 2026: [FigCraft CLI](https://github.com/storytold/figcraft/blob/main/docs/cli.md), [Figma canvas writing](https://developers.figma.com/docs/figma-mcp-server/write-to-canvas/), [Figma MCP FAQ](https://help.figma.com/hc/en-us/articles/39252411778583-Figma-MCP-server-FAQs).
