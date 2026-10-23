#!/usr/bin/env python3
"""Read built bundle metadata in macOS CI to prove xcconfig expansion.
The iOS and Mac build jobs in native-ci.yml call this against real .app/.appex products, and the
testflight.yml jobs call it against the archived products with the build number they set (optional third argument).
"""
from pathlib import Path
import plistlib
import sys

bundle = Path(sys.argv[1])
expected = sys.argv[2]
info = bundle / "Info.plist"
if not info.exists():
    info = bundle / "Contents" / "Info.plist"
values = plistlib.loads(info.read_bytes())
assert values["CFBundleIdentifier"] == expected, (info, values["CFBundleIdentifier"])
assert values["VaultAppGroup"] == "group.com.statemachine.mindmachine"
assert values["VaultCloudContainer"] == "iCloud.com.statemachine.mindmachine"
key_group = values["VaultKeychainGroup"]
assert "$(" not in key_group and key_group.endswith("com.statemachine.mindmachine"), key_group
# Export compliance is declared in the plist so App Store Connect does not prompt after each upload.
assert values.get("ITSAppUsesNonExemptEncryption") is False, "ITSAppUsesNonExemptEncryption must be NO"
# Inspect compiled resources, since a source catalog alone does not put an icon into the shipped app.
# The keyboard extension intentionally has no app icon.
if values["CFBundlePackageType"] == "APPL":
    resources = bundle / "Contents" / "Resources" if (bundle / "Contents").exists() else bundle
    assert (resources / "Assets.car").is_file(), "Compiled app asset catalog missing"
    if (bundle / "Contents").exists():
        assert values.get("CFBundleIconName", values.get("CFBundleIconFile", "").removesuffix(".icns")) == "AppIcon", "Compiled AppIcon metadata missing"
        assert (resources / (values["CFBundleIconFile"].removesuffix(".icns") + ".icns")).is_file(), "Mac ICNS missing"
        assert (resources / "menubar-template.svg").is_file(), "Menu-bar source artwork missing"
    else:
        for key in ["CFBundleIcons", "CFBundleIcons~ipad"]:
            icon = values[key]["CFBundlePrimaryIcon"]
            assert icon["CFBundleIconName"] == "AppIcon", (key, icon)
            assert icon["CFBundleIconFiles"], (key, "No compiled icon files")
if len(sys.argv) > 3:
    assert values["CFBundleVersion"] == sys.argv[3], (values["CFBundleVersion"], sys.argv[3])
print(f"MM_BUNDLE {expected}: resolved App Group, CloudKit and Keychain identifiers PASS")
