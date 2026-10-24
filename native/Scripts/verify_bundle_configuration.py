#!/usr/bin/env python3
"""Read built bundle metadata in macOS CI to prove xcconfig expansion.
The iOS and Mac build jobs in native-ci.yml call this against real .app/.appex products, and the
testflight.yml jobs call it against the archived products with the build number they set (optional third argument).
"""
from pathlib import Path
import plistlib
import argparse

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("bundle", type=Path)
parser.add_argument("expected")
parser.add_argument("build_number", nargs="?")
parser.add_argument("--entitlements", type=Path, help="Verify requested capabilities against compiled vault identifiers")
args = parser.parse_args()
bundle = args.bundle
expected = args.expected
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
if args.build_number:
    assert values["CFBundleVersion"] == args.build_number, (values["CFBundleVersion"], args.build_number)
# Unsigned products have no provisioning signature. Verify that their requested
# source capabilities expand to the same identifiers the compiled app will use.
if args.entitlements:
    xml = args.entitlements.read_text()
    for key, value in {"VAULT_APP_GROUP": values["VaultAppGroup"],
                       "VAULT_ICLOUD_CONTAINER": values["VaultCloudContainer"],
                       "VAULT_KEYCHAIN_GROUP": values["VaultKeychainGroup"]}.items():
        xml = xml.replace("$(" + key + ")", value)
    assert "$(" not in xml, "Unexpanded requested entitlement"
    requested = plistlib.loads(xml.encode())
    assert requested["com.apple.security.application-groups"] == [values["VaultAppGroup"]]
    assert requested["com.apple.developer.icloud-container-identifiers"] == [values["VaultCloudContainer"]]
    assert requested["com.apple.developer.icloud-services"] == ["CloudKit"]
    assert requested["keychain-access-groups"] == [values["VaultKeychainGroup"]]
    if (bundle / "Contents").exists():
        assert requested["com.apple.security.app-sandbox"] is True
        assert requested["com.apple.security.network.client"] is True
    print(f"MM_ENTITLEMENTS {expected}: requested capabilities match compiled identifiers PASS")
print(f"MM_BUNDLE {expected}: resolved App Group, CloudKit and Keychain identifiers PASS")
