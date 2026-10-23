#!/usr/bin/env python3
"""Give an unsigned xcodebuild archive ad-hoc signatures that carry each target's real entitlements.
testflight.yml calls this between `xcodebuild archive` (built with CODE_SIGNING_ALLOWED=NO, which drops entitlements)
and `xcodebuild -exportArchive`, which reads entitlements from the archive's signatures and replaces these ad-hoc
signatures with cloud-managed distribution signatures. tf-diagnose.yml calls it with --drop to find which entitlement
makes Xcode ask Apple for a provisioning profile it cannot get.

Usage: preserve_archive_entitlements.py ARCHIVE TEAM_ID [--drop groups|icloud|keychain|aps]...
"""
from pathlib import Path
import argparse
import plistlib
import subprocess
import tempfile

# Entitlement keys removed by each --drop name (diagnostic use only; a normal release drops nothing).
DROPPABLE = {
    'groups': ['com.apple.security.application-groups'],
    'icloud': ['com.apple.developer.icloud-container-identifiers', 'com.apple.developer.icloud-services'],
    'keychain': ['keychain-access-groups'],
    'aps': ['aps-environment', 'com.apple.developer.aps-environment'],
}

# (source folder under native/Apps, path of the bundle inside Products/Applications). The keyboard is signed first
# because codesign seals a containing app over the extensions inside it.
TARGETS = [('Keyboard', 'MindMachine.app/PlugIns/MindMachineKeyboard.appex'),
           ('iOS', 'MindMachine.app'), ('Mac', 'MindMachineMac.app')]


def expanded_entitlements(folder, info, team, drop):
    """Source entitlements with the build variables Xcode would expand, plus the identity keys a profile supplies."""
    variables = {'VAULT_APP_GROUP': info['VaultAppGroup'],
                 'VAULT_ICLOUD_CONTAINER': info['VaultCloudContainer'],
                 'VAULT_KEYCHAIN_GROUP': info['VaultKeychainGroup']}
    xml = (Path('native/Apps') / folder / 'Vault.entitlements').read_text()
    for key, value in variables.items():
        xml = xml.replace('$(' + key + ')', value)
    assert '$(' not in xml, 'Unexpanded archive entitlement'
    entitlements = plistlib.loads(xml.encode())
    identifier_key = 'com.apple.application-identifier' if folder == 'Mac' else 'application-identifier'
    entitlements[identifier_key] = team + '.' + info['CFBundleIdentifier']
    entitlements['com.apple.developer.team-identifier'] = team
    assert info['VaultKeychainGroup'].startswith(team + '.'), 'Keychain prefix must match signing team'
    for name in drop:
        for key in DROPPABLE[name]:
            entitlements.pop(key, None)
    return entitlements


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('archive')
    parser.add_argument('team')
    parser.add_argument('--drop', action='append', default=[], choices=sorted(DROPPABLE))
    args = parser.parse_args()
    products = Path(args.archive) / 'Products/Applications'
    for folder, relative in TARGETS:
        app = products / relative
        if not app.exists():
            continue
        info_path = app / ('Contents/Info.plist' if folder == 'Mac' else 'Info.plist')
        entitlements = expanded_entitlements(folder, plistlib.loads(info_path.read_bytes()), args.team, args.drop)
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'entitlements.plist'
            path.write_bytes(plistlib.dumps(entitlements))
            subprocess.run(['codesign', '--force', '--sign', '-', '--entitlements', str(path), str(app)], check=True)
        # `:-` prints the entitlements as bare XML; plain `-` can prefix a binary blob header that plistlib rejects.
        signed = subprocess.check_output(['codesign', '--display', '--entitlements', ':-', str(app)])
        assert plistlib.loads(signed) == entitlements, 'Archive signature lost entitlements'
        print(f'MM_ARCHIVE {folder}: signed requested entitlements PASS', flush=True)


main()
