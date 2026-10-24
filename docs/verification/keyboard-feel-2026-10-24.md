# Keyboard feel audit — 24 October 2026

This audit compares the Mind Machine keyboard (`native/Apps/Keyboard`) with Apple's iOS 26 iPhone keyboard and lists the gaps. The keys come from KeyboardKit 9.9.1 (MIT, `a7e33ac`), hosted by `KeyplaneView` below the panel. Each gap's status is updated as it closes; the "Closing work" section records what changed and the evidence.

## Method

- **Geometry.** CI run [40095407732](https://github.com/shomoD9/mind-machine/actions/runs/40095407732) (`simulator-screenshots`, iPhone 17 Pro, iOS 26.2, 402 × 874 pt at 3×) happened to capture Apple's keyboard in the light pass and ours in the dark pass, on the same device. Key faces were located by scanning pixel rows 14 px below each row's top edge for key-face versus backdrop colour, then scanning columns for heights. Values below are in points (pixels ÷ 3).
- **Behaviour.** Read the KeyboardKit 9.9.1 source that ships in the build (gesture button, standard behaviour, action handler, callout context, feedback configuration, space-drag handler, device configuration, button colours) and our wrapper (`KeyboardViewController`, `KeyplaneView`, `RoutedTextProxy`, `InputClickFeedback`). Compared each against Apple's documented or observable behaviour on iOS 26.
- **Limits.** A simulator has no haptics and no Taptic timing; the keyboard daemon's own feel cannot be measured in CI. Items marked *device* need a phone.

## Geometry (iPhone 17 Pro, portrait, Liquid Glass)

| Measure | Apple | Mind Machine | Gap |
| --- | --- | --- | --- |
| Letter key face width | 32.2 | 32.2 | none |
| Letter key face height | 43.0 | 47.0 | ours 4 pt taller |
| Row pitch (top to top) | 54.0 | 56.0 | ours 2 pt taller per row, 8 pt over four rows |
| Vertical gap between keys | 11.0 | 9.0 | ours 2 pt tighter |
| Horizontal pitch (Q to W) | 39.5 | 40.2 | ours 0.7 pt wider |
| Horizontal gap between keys | 7.3 | 8.0 | ours 0.7 pt wider |
| Screen edge to Q / P | 7.3 | 4.0 | ours 3.3 pt closer to the edge |
| Shift / delete width | 43.7 / 44.0 | 44.0 / 44.0 | none |
| 123 / space / return width | 91.3 / 190.0 / 91.7 | 92.7 / 193.0 / 92.3 | follows from the edge margin |
| Corner radius (visual) | ≈ 4.3 at the scan line | ≈ 4.3 | none measurable |

KeyboardKit's iOS 26 adjustment (`rowHeight + 2`, insets − 0.5) applies only to screens narrower than 428 pt; the 440 pt iPhone 17 Pro Max uses a separate 56 pt row.

## Geometry (iPhone 17 Pro Max, portrait and landscape)

`KeyboardFeelTests.testCaptureGeometryAgainstAppleKeyboard` (CI run [40103948865](https://github.com/shomoD9/mind-machine/actions/runs/40103948865), iPhone 17 Pro Max, iOS 26.2) launched the test host twice per orientation: once showing this keyboard and once with `--apple-keyboard-reference`, which brings up Apple's keyboard on the same screen. It logged XCUITest key frames for both and saved screenshots, measured here at 3×.

| Measure | Apple | Mind Machine | Gap |
| --- | --- | --- | --- |
| Portrait key cell pitch | 43.33 | 44.0 | ours 0.67 pt wider |
| Portrait screen edge to Q face | 7.33 | 4.0 | ours 3.3 pt closer to the edge |
| Portrait letter face | 36.0 × 45.0 | 36.0 × 46.0 | ours 1 pt taller |
| Portrait gap between faces | 7.33 | 8.0 | ours 0.67 pt wider |
| Portrait row pitch | 56.0 | 56.0 | none |
| Portrait shift face width | 48.7 | 49.3 | follows from the edge margin |
| Landscape row pitch | 35.33 | 40.0 | ours 4.7 pt taller per row, 19 pt over four rows |
| Landscape letter face | 64.7 × 27.3 | 87.7 × 32.0 (full-width test host) | height: ours 4.7 pt taller |
| Landscape gap between faces | 7.33 | 8.0 | ours 0.67 pt wider |
| Landscape keyboard width | 722 (x 117–839, globe and dictation beside it) | 956 in the test host | not comparable, see below |

Two rules hold on both phones: Apple's gap between faces and its screen margin are both 7.33 pt, and portrait faces sit 5.5 pt inside a 54 or 56 pt row. KeyboardKit draws each face 1 pt inside its configured horizontal inset, so its configured 3 pt inset shows as an 8 pt gap.

In landscape Apple's keyboard occupies the middle 722 pt with the globe and dictation keys beside it. iOS does the same for third-party keyboards on Face ID iPhones, so the extension's width in landscape is set by the system; the test host embeds the controller across the full window and cannot reproduce that width. Row height and gaps are comparable and are matched; the landscape width needs a device check.

The baseline run also showed G2 directly: in landscape the destination row, status and Save button were squeezed out and the bottom key row ran off the screen (`testLandscapeShowsShorterKeysAndAWorkingPanel` failed on "keyboard-save must stay usable in landscape"). `testKeysWithoutAppleAlternatesShowNoAccentCallout` failed with `ț` (G5). Caps lock, the accented e and delete repeat passed before any change (G9, G6 repeat).

## Gaps

| # | Area | Apple | Mind Machine before this work | Status |
| --- | --- | --- | --- | --- |
| G1 | Key size and spacing | Values above | Keys 4 pt taller, 2 pt less vertical gap, 3.3 pt less side margin | closed (a2e54c6) |
| G2 | Landscape | Shorter keys; the keyboard leaves most of the screen to the app | KeyboardKit's landscape rows are 40 pt, but the panel keeps its portrait heights (editor 110 pt, results 110 pt) and requests 400–670 pt for the extension, more than a landscape iPhone's height. No test covers rotation. | closed (9748736, a2e54c6); landscape width needs a device |
| G3 | Return key colour | Blue for Go, Search, Send, Done, Join, Route, Next, Continue | KeyboardKit paints these blue, which breaks the greyscale style | closed (e2f7fbe) |
| G4 | Return key disabled when empty | Greyed and inert when the field sets `enablesReturnKeyAutomatically` and is empty (Messages, Safari address bar) | Always active; `RoutedTextProxy` does not forward the trait | closed (e2f7fbe) |
| G5 | Long-press alternates | Only a c e i l n o s u y z have alternates. iOS 17+ English (US) sets ([Gadget Hacks catalogue](https://ios.gadgethacks.com/how-to/every-hidden-special-character-your-iphones-keyboard-you-can-unlock-right-now-0384666/), [iGeeksBlog](https://www.igeeksblog.com/how-to-type-diacritical-marks-on-iphone-ipad/)): a à á â ä æ ã å ā ǎ ă ą; c ç ć č ċ; e è é ê ë ē ė ę ě ẽ; i ì į ī í ï î ı ĩ ǐ; l ł ľ ļ; n ń ñ ň ņ; o õ ō ø œ ó ò ö ô ő ǒ; s ß ś š ş ș; u ū ú ù ü û ų ů ű ũ ǔ; y ÿ ŷ ý; z ž ź ż | KeyboardKit's open-source English table also gives d g h k r t w alternates (ď ð ğ ġ ħ ķ ř ț ť þ ŵ), offers ŝ ṣ and lacks ě ẽ ı ş ų ů ű, and repeats `u` at the end of the u popup | closed (e2f7fbe); whether Apple shows the plain letter needs a device |
| G6 | Delete repeat and acceleration | First delete on touch-down, then repeat; after a few seconds of holding, whole words. Apple publishes no timings; user reports describe word deletion after "a few seconds" ([iDownloadBlog](https://www.idownloadblog.com/?p=357012)) and speed that grows with hold time ([AppleVis](https://applevis.com/podcasts/quick-tip-three-examples-where-double-tap-and-hold-can-make-your-use-ios-more-efficient)) | Touch-down delete, 0.5 s delay, then 10 characters per second; after 3 s of repeating (3.5 s of hold), whole words at the same 10 per second, so word deletion lurches from 10 characters to roughly 50 characters per second with no intermediate step | closed (e2f7fbe); timing needs a device |
| G7 | Shift held while typing | Holding shift and tapping letters types capitals; releasing shift returns to lowercase | Shift acts only on release, so a held shift does nothing | closed (e2f7fbe); needs two fingers on a device |
| G8 | Slide from shift or 123 | Touch shift (or 123), slide to a key, lift: types that key (capital, or digit/symbol) and returns to the previous layer | The gesture stays on shift/123; lifting over another key types nothing | closed (e2f7fbe, b057918) |
| G9 | Caps lock | Double-tap shift locks; icon changes to caps lock | Present: KeyboardKit double-tap (0.5 s between releases), caps-lock icon and fill | none (device for timing) |
| G10 | Key-pop callout | Pop-up above letter keys on touch | Present: KeyboardKit input callout; top-row pop-ups draw over the panel | none (device for timing) |
| G11 | Space-bar cursor drag | Touch and hold space, keys blank, drag moves the caret in two dimensions | Present: hold 0.5 s, labels fade, horizontal drag moves the caret through `RoutedTextProxy`. Vertical movement is not available: a keyboard extension can only move the caret by character offset | partial (platform limit) |
| G12 | Click sound | Distinct sounds for letters, delete and modifiers, controlled by Keyboard Feedback → Sound | One `playInputClick` sound for every key; it is the only public API that follows the Sound switch | partial (platform limit) |
| G13 | Haptics | Keyboard Feedback → Haptic (off by default), a light tap on touch-down | KeyboardKit's selection-changed tap on touch-down whenever System Haptics is on; third-party keyboards cannot read the Keyboard Feedback switch. Generators are not prepared ahead of the first tap | partial: generators prepared (ec78f46); strength and the Haptic switch are platform limits, device |
| G14 | Double-space period, autocapitalisation, 123/#+= layers, return to letters after space or apostrophe | Present | Present through KeyboardKit and `RoutedTextProxy` | none |
| G15 | Globe and dictation | System strip below the keys on Face ID iPhones | System strip; KeyboardKit's globe only on Home-button iPhones; no Next keyboard button | none |

## Closing work

All evidence is from [native-ci run 40107374846](https://github.com/shomoD9/mind-machine/actions/runs/40107374846) on PR #9 at `3445239` (iPhone 17 Pro Max simulator for UI tests, iPhone 17 Pro for the installed-extension screenshots, iOS 26.2): every job passed, `MindMachineKeyboardUITests` executed 13 tests with 0 failures (the 3 existing `KeyboardAcceptanceTests` and 10 `KeyboardFeelTests`).

| Gap | Change | Evidence |
| --- | --- | --- |
| G1 | `AppleGeometry.install()` (KeyplaneView.swift) replaces KeyboardKit's iPhone presets on iOS 26: 2.67 pt horizontal insets plus 3.67 pt padding around the keyplane (7.33 pt gaps and margins), 54/56 pt portrait rows with 5.5 pt visible insets, 35.33 pt landscape rows with 4 pt insets. KeyboardKit reads the same presets for callout placement, so key pops stay aligned. | iPhone 17 Pro, installed extension (`simulator-screenshots`, light): Q…P faces at x = 22, 140, 259 … 1088 px, 96–97 px wide, 129 px tall, 162 px row pitch; Apple's: x = 22, 140, 259 … 1088 px, 96–97 px, 129 px, 162 px. iPhone 17 Pro Max portrait: faces 107–108 px wide at x = 22, 152 … 1190 px against Apple's 22, 151 … 1191 px; 135 px tall at the face centre for both. Landscape faces 82 px tall for both. XCUITest cells: Q 43.33 × 56 pt from x = 3.67 (Apple 43 × 56 from 4.67); bottom row 108.3 / 216 / 108.3 pt (Apple 108 / 216.7). |
| G2 | Landscape panel (`applyPadSize`, `arrangeToolRow`): 32/44/88 pt note, destination and formatting beside the mode switcher, height request = keys + 104 pt + visible note and results; note and results below required priority. | `testLandscapeShowsShorterKeysAndAWorkingPanel` passed (failed in baseline run 40103948865 with Save squeezed out): keys shorter than portrait and inside the window at every Size, Save, Size and destination hittable, note at least 30 pt, typing works. |
| G3 | `KeyplaneView.buttonStyle`: action return keys use Greyscale.prominent / onProminent. | `testActionReturnKeyIsGrey` passed: Search key fill pixel-sampled grey (channel spread ≤ 6) and dark in light appearance; screenshot attached. |
| G4 | `KeyplaneState.returnKeyDisabled`, set by `refreshReturnKey()` from the destination's `enablesReturnKeyAutomatically` and `hasText`; the handler drops return gestures while it is set; faint label. | `testReturnKeyIsInertWhileAnEmptyHostFieldAsksForIt` passed: return in an empty field changed nothing; after typing X, return inserted a newline. |
| G5 | `KeyAlternates`: Apple's eleven letters and iOS 17+ sets, no callout on other letters. | `testKeysWithoutAppleAlternatesShowNoAccentCallout` passed (baseline typed `ț`); `testLongPressAndSlideTypesAnAccentedLetter` passed. |
| G6 | `KeyplaneBehavior.backspaceRange` and `KeyplaneActionHandler.shouldDelete`: whole words after 2.5 s, at most five per second. | `testHoldingDeleteRepeatsCharactersThenRemovesWholeWords` passed: a 1.4 s hold removed more than 3 and fewer than 40 characters; a 6 s hold removed more than 70 more and stopped on a word boundary; the private note stayed empty. |
| G7 | Shift capitals on touch-down; letters typed while shift is held stay capital; release returns to lowercase. Key host takes multiple touches. | Not testable in XCUITest (needs two independent touches). Double-tap caps lock, which shares the code path, passed `testDoubleTapShiftLocksCapitalsUntilShiftIsTappedAgain`. Device check. |
| G8 | Slide from shift or 123 types the key (or space) under the finger, using key frames published as a SwiftUI preference, then restores case or layer. | `testSlidingFromShiftTypesOneCapital` ("aK", then "aKl") and `testSlidingFrom123TypesOneDigitAndReturnsToLetters` ("a3", then "a3b") passed. |
| G13 | `InputClickFeedbackService` prepares the haptic generator after each tap. | Compiles and runs; strength and latency need a device. |

Unchanged: G9–G11 and G14–G15 were already present and keep working (caps lock and accent tests pass; space-bar drag untouched). G11's vertical caret movement and G12's single click sound are platform limits for third-party keyboards.

During the baseline round `KeyboardAcceptanceTests.testCaptureRecallInsertAndRelaunch` failed once while emptying the Recall query (the field looked empty in the failure screenshot); that run carried only test-host additions, the same test passed on main with identical product code, and it passed in run 40107374846. No test or product change was made for it.

### Needs a phone

- Landscape width: iOS sizes a third-party keyboard beside the globe and dictation keys; the test host cannot reproduce it.
- Delete pacing (2.5 s to words, five words a second), callout and long-press timing, double-tap window.
- Held shift with a second finger; roll-over typing with multiple touches enabled.
- Whether Apple's accent popup includes the plain letter (ours does, first) and the order of alternates on right-hand keys.
- Haptic strength (KeyboardKit's selection tap) and the single click sound against Apple's three.

## Simulator acceptance observation repair

The documentation checkpoint a98d02b’s [run 40110448639](https://github.com/shomoD9/mind-machine/actions/runs/40110448639) failed only `testCaptureRecallInsertAndRelaunch` while clearing the Recall query; all ten feel tests passed. Its xcresult runner log records the AX query starting at 16:21:31.648 with a 30-second transport deadline. At 16:21:35.864 the surrounding five-second `XCTNSPredicateExpectation` interrupted that query with `XCTFuture Code=1001`, “Interrupted by waiter.” The later diagnostic and captured screenshot/tree show an empty editor. The failure reported a canceled observation rather than a completed value comparison.

The keyboard suites now compare completed [XCUIElement snapshots](https://developer.apple.com/documentation/xcuiautomation/xcuielementsnapshotproviding/snapshot%28%29) synchronously. Five seconds still bounds polling for text to settle; each AX request keeps XCTest’s normal transport deadline and cannot be canceled by an enclosing predicate waiter. Exact strings remain mandatory, nil and snapshot errors fail, and no gesture is retried. Query replacement additionally asserts the exact prefix after every delete. All 13 journeys and their visual, gesture, search and persistence assertions remain. Hosted verification is pending on the repair commit.


### Empty text-view snapshot correction

The snapshot repair at `ac55a34` exposed a second incorrect test assumption in [run 40113103269](https://github.com/shomoD9/mind-machine/actions/runs/40113103269). Both failures compared `nil` with `Optional("")`: immediately after Save cleared Capture, and after host delete-repeat when the private note remained empty. The other eleven journeys passed. The failure trees contain the expected `keyboard-editor` TextView without a value attribute; nonempty editors expose their text normally. The Save failure screenshot shows an empty editor, its caret, the unchanged host draft and “Saved on this device”.

The runner trace at 16:55:43.240–43.247 records the value request completing in 7 ms, followed by an empty attribute dictionary with “(no error) for value using XC_kAXXCAttributeValue”. The placeholder request also completes without a value. This is a legitimate empty UITextView observation, separate from the earlier interrupted transport. Apple documents [value](https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes/value) as a raw optional attribute whose type depends on the element.

The shared assertion now interprets a nil raw value as empty text only after a successful snapshot of a TextView. Snapshot errors and missing elements still fail; nil on another element type, non-string values and all unequal strings still fail. The Capture journey additionally checks the initial empty editor before typing. The exact saved text, every Recall deletion, unrelated-query negative control, insertion, relaunch, host isolation and all feel checks remain required. No gesture is retried. Production code and UI are unchanged. Hosted verification is pending on this correction.
