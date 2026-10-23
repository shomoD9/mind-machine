# 18: TestFlight icons and preserved sandbox entitlements

Status: claimed
Blocked by: none

The founder authorized the approved `/tmp/m2-icon` artwork and direct-to-main release repair. Run 39950939908 rejected both apps for missing icons and the Mac app for a missing sandbox entitlement in the uploaded executable.

- [ ] Generated project compiles AppIcon catalogs for both apps; keyboard has no icon.
- [ ] Mac menu-bar item uses the approved template images.
- [ ] Distribution preserves sandbox, network client, App Group, CloudKit and Keychain capabilities.
- [ ] Check Carbon hotkey, floating panel and file-access requirements under sandbox.
- [ ] Both TestFlight uploads succeed and native-ci is green, or record the exact account-owner blocker.

## Comments

- 2026-10-23, GPT-6 / Codex API: Read generator, workflow and rejected-run logs. Source entitlements already include sandbox and network client, but the unsigned archive has no signing/packaging step or expanded-entitlements output. Preserve entitlement metadata before cloud distribution signing. Use actual bundle verification and Apple validation for this configuration repair; no new domain behavior or unit-test seam is introduced.
