# 19: Native-feel keyboard and greyscale UI

Status: ready-for-human
Blocked by: founder judgement of key feel and memory headroom on an iPhone (TestFlight build from this branch)

The founder tested TestFlight build 10 on 2026-10-23. Functionality worked. Requests: remove "Next keyboard" (keep "Save note"); make the letter keys look and feel like Apple's keyboard using a mature open-source implementation; restyle the keyboard panel and companion screens as minimal, greyscale and lightly grained, without changing copy or behaviour; add stable accessibility identifiers for the coming UI tests; keep tests passing and leave sync/storage logic alone.

- [x] "Next keyboard" removed; Save note kept. The system globe (or KeyboardKit's globe on Home-button iPhones) switches keyboards.
- [x] Keys from a licence-compatible library: KeyboardKit 9.9.1 (MIT, exact SPM pin, keyboard target only), recorded in THIRD_PARTY_NOTICES.md.
- [x] Every key, word delete, double-space period and space-bar drag follows the typing destination (RoutedTextProxy).
- [x] Key sound through `UIDevice.playInputClick` (follows Keyboard Clicks); haptics through KeyboardKit's generator (follows System Haptics).
- [x] Panel and companion restyled in pure greys with dithered grain; no copy string changed.
- [x] Identifiers on every interactive control and status label; existing identifiers unchanged.
- [ ] native-ci green on the PR.
- [ ] Founder: key feel on device (callouts, accents, caps lock, repeat delete, click and haptic), dark mode, memory report in the companion.

## Comments

- 2026-10-24, Claude Opus 5.5 / Claude Code: KeyboardKit went closed-source binary at 10.0; 9.9.1 is the last MIT source release and covers geometry, callouts, accents, shift/caps lock, repeat delete, 123/#+= layers, space drag, dark mode and iOS 26 Liquid Glass styling. Pro-only gaps: emoji keyboard, autocomplete bar, non-English layouts. Details and verification are in DESIGN ("Native-feel keyboard and greyscale UI"). CI simulator screenshots (artifact `simulator-screenshots`) show the companion, vault and keyboard in light and dark.
- 2026-10-24, Claude Opus 5.5 / Claude Code: The Release benchmark's newest-first "pr" assertion failed twice on this PR and on `overnight-core`. A throwaway probe (branch deleted) printed 4,276 of 10,000 fixture captures sharing a timestamp with their neighbour, ordered by random ID on ties. The fixture now stamps notes one millisecond apart; storage ordering is unchanged.
