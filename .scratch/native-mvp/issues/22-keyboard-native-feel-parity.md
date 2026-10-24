# 22: Keyboard native look and feel parity

Status: ready-for-human
Blocked by: founder judgement of feel on an iPhone (TestFlight build from this branch)

Make the iPhone keyboard extension look and feel like Apple's iOS keyboard: key sizes, spacing, corner radii, key-pop callouts, long-press alternates, shift and caps lock, delete repeat with acceleration, space-bar cursor drag, click sound and haptics, return-key behaviour and landscape. Keep the greyscale, dithered panel; no Next keyboard button; no user-facing copy change. Reuse KeyboardKit 9.9.1 (MIT) and credit it.

- [x] Audit of gaps against Apple's keyboard in `docs/verification/keyboard-feel-2026-10-24.md`.
- [x] Each closable gap closed in a small commit, with evidence in the audit.
- [x] Existing `KeyboardAcceptanceTests` pass; new XCUITests cover testable new behaviour.
- [x] native-ci green on the PR "Keyboard: native iOS look and feel". Not merged.
- [ ] Founder: feel on a phone (timings, haptics, sound, accents, landscape).

## Comments

- 2026-10-24, Claude Opus 5.5 / Claude Code: [PR #9](https://github.com/shomoD9/mind-machine/pull/9), unmerged. G1–G8 closed, G13 partly; G9–G11, G14–G15 were already present; G11's vertical drag and G12's per-key sounds are platform limits. [native-ci 40107374846](https://github.com/shomoD9/mind-machine/actions/runs/40107374846): all jobs green, keyboard UI 13/13. Device checks are listed at the end of the audit.
