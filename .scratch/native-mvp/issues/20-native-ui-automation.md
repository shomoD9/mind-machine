# 20: Automate keyboard and pill acceptance

Status: resolved
Blocked by: none

The founder requested XCUITest coverage on branch keyboard-ui, verified on GitHub macOS CI because this workspace has no Xcode. The approved seams are the keyboard workspace in a host field and the Mac pill UI, using real local persistence with sync disabled.

- [x] iPhone Capture acknowledgement, host isolation, prefix/typo Recall, explicit insertion and persisted relaunch.
- [x] Mode/size draft preservation and real keyplane letters, shift, delete, numbers and return.
- [x] Mac pill opens and Capture/Recall round-trip, complementing PillSelfTest.
- [x] Required CI jobs pass; result and remaining device checks recorded.

## Comments

- 2026-10-24, GPT-6 / Codex API: [CI 40063894121](https://github.com/shomoD9/mind-machine/actions/runs/40063894121) passed all five jobs: iPhone UI 3/3, Mac UI 1/1, sandbox pill 51/51 and existing package/build checks. Reviewed the diff against the founder's manual checks and project standards: exact originals and host isolation observed through UI, test-only storage/proxy hooks isolated, no copy/visual changes, generated project reproducible, narrative headers present. The old polling sampler missed collapse frames on two attempts; actual resize notifications now capture widths with unchanged assertions. [Verification and remaining device gates](../../../docs/verification/native-ui-2026-10-24.md) distinguish embedded-controller coverage from OS keyboard registration, signed storage/sync, physical memory and typing feel. Parent device acceptance remains open.

- 2026-10-24, GPT-6 / Codex API: Read project/domain/tracker guidance and ADR 0001. `/tmp/mm-kbui-result.md` was absent. Chose a separate deterministic host target compiling the production keyboard sources: simulator keyboard preferences have produced system-keyboard screenshots on this branch. Test-only storage/proxy adapters must stay outside distribution targets.
