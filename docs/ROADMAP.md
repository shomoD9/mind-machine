# Experience roadmap

## More writing space without leaving the current app

**Confirmed:** the keyboard is the primary phone interface. Its notepad, Find and Chat live inside the keyboard workspace while another app stays open. The person controls how much of the phone that workspace occupies.

- **Minimised:** a single visible note line above the keys. Minimising alone preserves the active destination: note typing stays in the collapsed note. The later tap-to-focus clarification allows explicit host-field selection without changing keyboards.
- **Default:** a scrollable note viewport with several visible lines and formatting controls.
- **Expanded:** request a taller keyboard workspace and devote the added height to the note. Keep the keys anchored, preserve text, selection/caret and scroll context, and make returning to smaller sizes immediate.
- The same size control applies to Find and Chat, not just Capture. Exact point heights are prototype values to test, not platform guarantees. Drafts survive mode and size changes; minimising does not save, discard or insert anything.

Apple documents adjustable custom-keyboard height and input-view self-sizing. It does not establish a universal fullscreen keyboard size across devices, orientations and host apps. Build and measure the maximum usable extension height on actual supported devices before promising true fullscreen within another app. Do not use private APIs or silently launch the companion app to simulate that result. [Custom keyboard guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html), [self-sizing input views](https://developer.apple.com/documentation/uikit/uiinputview/allowsselfsizing).

**Mac:** the global hotkey opens a native panel, rather than an onscreen keyboard. Let the person resize it, collapse its writing area with the draft retained, and choose fullscreen. Implementing fullscreen changes the presentation of our own native window; it does not embed our UI in another application's window. [NSWindow](https://developer.apple.com/documentation/appkit/nswindow).

## Host composer and typing destination — 20 October clarification

The example host composer is positioned immediately above the **whole keyboard workspace**, including the note area. It follows that workspace upward/downward across pad sizes. Expanded mode retains room for the composer and reduces the visible conversation history. The earlier fixed composer coordinate was a mockup error, not intended product behavior. The real host app owns that composer and its layout, so compatibility must be tested rather than guaranteed for every app.

**Desired interaction:** tapping the host text box makes the same keys type into that field; tapping the notepad makes them type into the note. Capture still opens with Note selected. Resizing or minimising alone does not switch destinations, submit text, save, or discard either draft. A caret, active-field treatment, and visible Typing: Note/App status identify the destination. Find and Chat likewise preserve their private input when the host is selected.

The FigCraft prototype includes two focus states and a tappable destination indicator as a **proposed fallback**. Source review establishes host-proxy insertion and text/selection callbacks; it does not establish reliable notification of every unchanged-caret host tap. An internal text view's responder transition is another plausible route to test, not a documented universal solution. Keep tap-to-focus as the desired behavior and test actual native focus/proxy continuity before claiming it works. See [focus/platform research](../.scratch/scattered-ambitious-pitch/research/25-keyboard-focus-and-host-layout-2026-10-20.md).

## Use the person's preferred keyboard underneath our pad

**Human-requested future goal:** Capture/Find/Chat appear above the keyboard the person already uses, inheriting its typing behavior, languages and correction habits.

The current supported iPhone route replaces the active system keyboard with our extension. Input accessory views can add controls to text fields owned by our own app; that is not general authority to attach a pad to arbitrary third-party apps or keyboards. Keep preferred-keyboard inheritance as an engineering investigation, with no supported universal route selected. [Creating a custom keyboard](https://developer.apple.com/documentation/uikit/creating-a-custom-keyboard), [input and accessory views](https://developer.apple.com/library/archive/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/InputViews/InputViews.html).

For the first keyboard, familiar key placement, shift/delete, punctuation, keyboard switching and responsiveness are goals. Apple-equivalent autocorrection, dictation, swipe input, every language and exact system parity are not established capabilities. Define and test the supported behavior before launch.

## Existing deferred branches

- Resurfacing selection priorities remain deferred by the human.
- Calendar integration and calendar timeboxing remain deferred.
- Pricing and packaging are not selected.
