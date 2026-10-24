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

KeyboardKit's iOS 26 adjustment (`rowHeight + 2`, insets − 0.5) applies only to screens narrower than 428 pt; the 440 pt iPhone 17 Pro Max uses a separate 56 pt row. Apple's geometry for the Pro Max and for landscape has not been measured yet. The new geometry test captures both keyboards on the CI device (iPhone 17 Pro Max) in both orientations.

## Gaps

| # | Area | Apple | Mind Machine before this work | Status |
| --- | --- | --- | --- | --- |
| G1 | Key size and spacing | Values above | Keys 4 pt taller, 2 pt less vertical gap, 3.3 pt less side margin | open |
| G2 | Landscape | Shorter keys; the keyboard leaves most of the screen to the app | KeyboardKit's landscape rows are 40 pt, but the panel keeps its portrait heights (editor 110 pt, results 110 pt) and requests 400–670 pt for the extension, more than a landscape iPhone's height. No test covers rotation. | open |
| G3 | Return key colour | Blue for Go, Search, Send, Done, Join, Route, Next, Continue | KeyboardKit paints these blue, which breaks the greyscale style | open |
| G4 | Return key disabled when empty | Greyed and inert when the field sets `enablesReturnKeyAutomatically` and is empty (Messages, Safari address bar) | Always active; `RoutedTextProxy` does not forward the trait | open |
| G5 | Long-press alternates | Only a c e i l n o s u y z have alternates. iOS 17+ English (US) sets ([Gadget Hacks catalogue](https://ios.gadgethacks.com/how-to/every-hidden-special-character-your-iphones-keyboard-you-can-unlock-right-now-0384666/), [iGeeksBlog](https://www.igeeksblog.com/how-to-type-diacritical-marks-on-iphone-ipad/)): a à á â ä æ ã å ā ǎ ă ą; c ç ć č ċ; e è é ê ë ē ė ę ě ẽ; i ì į ī í ï î ı ĩ ǐ; l ł ľ ļ; n ń ñ ň ņ; o õ ō ø œ ó ò ö ô ő ǒ; s ß ś š ş ș; u ū ú ù ü û ų ů ű ũ ǔ; y ÿ ŷ ý; z ž ź ż | KeyboardKit's open-source English table also gives d g h k r t w alternates (ď ð ğ ġ ħ ķ ř ț ť þ ŵ), offers ŝ ṣ and lacks ě ẽ ı ş ų ů ű, and repeats `u` at the end of the u popup | open |
| G6 | Delete repeat and acceleration | First delete on touch-down, then repeat; after a few seconds of holding, whole words. Apple publishes no timings; user reports describe word deletion after "a few seconds" ([iDownloadBlog](https://www.idownloadblog.com/?p=357012)) and speed that grows with hold time ([AppleVis](https://applevis.com/podcasts/quick-tip-three-examples-where-double-tap-and-hold-can-make-your-use-ios-more-efficient)) | Touch-down delete, 0.5 s delay, then 10 characters per second; after 3 s of repeating (3.5 s of hold), whole words at the same 10 per second, so word deletion lurches from 10 characters to roughly 50 characters per second with no intermediate step | open (timing needs device) |
| G7 | Shift held while typing | Holding shift and tapping letters types capitals; releasing shift returns to lowercase | Shift acts only on release, so a held shift does nothing | open |
| G8 | Slide from shift or 123 | Touch shift (or 123), slide to a key, lift: types that key (capital, or digit/symbol) and returns to the previous layer | The gesture stays on shift/123; lifting over another key types nothing | open |
| G9 | Caps lock | Double-tap shift locks; icon changes to caps lock | Present: KeyboardKit double-tap (0.5 s between releases), caps-lock icon and fill | none (device for timing) |
| G10 | Key-pop callout | Pop-up above letter keys on touch | Present: KeyboardKit input callout; top-row pop-ups draw over the panel | none (device for timing) |
| G11 | Space-bar cursor drag | Touch and hold space, keys blank, drag moves the caret in two dimensions | Present: hold 0.5 s, labels fade, horizontal drag moves the caret through `RoutedTextProxy`. Vertical movement is not available: a keyboard extension can only move the caret by character offset | partial (platform limit) |
| G12 | Click sound | Distinct sounds for letters, delete and modifiers, controlled by Keyboard Feedback → Sound | One `playInputClick` sound for every key; it is the only public API that follows the Sound switch | partial (platform limit) |
| G13 | Haptics | Keyboard Feedback → Haptic (off by default), a light tap on touch-down | KeyboardKit's selection-changed tap on touch-down whenever System Haptics is on; third-party keyboards cannot read the Keyboard Feedback switch. Generators are not prepared ahead of the first tap | partial (device) |
| G14 | Double-space period, autocapitalisation, 123/#+= layers, return to letters after space or apostrophe | Present | Present through KeyboardKit and `RoutedTextProxy` | none |
| G15 | Globe and dictation | System strip below the keys on Face ID iPhones | System strip; KeyboardKit's globe only on Home-button iPhones; no Next keyboard button | none |

## Closing work

Each closed gap lists its commit and evidence when it lands.
