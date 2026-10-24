#!/usr/bin/env python3
# Confirms Apple's processing result for an exact app/build/platform after testflight.yml uploads it.
# Called by each release matrix job; uses its temporary signing key and never logs bearer tokens.
import argparse
import base64
import json
import os
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request


def encoded(value):
    return base64.urlsafe_b64encode(value).rstrip(b'=').decode('ascii')


def token(key_path):
    now = int(time.time())
    header = {'alg': 'ES256', 'kid': os.environ['ASC_KEY_ID'], 'typ': 'JWT'}
    claims = {'iss': os.environ['ASC_ISSUER_ID'], 'iat': now, 'exp': now + 600,
              'aud': 'appstoreconnect-v1'}
    message = '.'.join(encoded(json.dumps(part).encode()) for part in (header, claims))
    # OpenSSL signs with the existing P-256 key. JWT carries two fixed-width integers,
    # whereas OpenSSL returns an ASN.1 sequence; remove only the integer sign padding.
    der = subprocess.run(['openssl', 'dgst', '-sha256', '-sign', key_path],
                         input=message.encode(), capture_output=True, check=True).stdout
    if der[0] != 0x30 or der[1] != len(der) - 2:
        raise ValueError('Expected a P-256 ASN.1 signature')
    offset, parts = 2, []
    for _ in range(2):
        if der[offset] != 0x02:
            raise ValueError('Expected an ASN.1 signature integer')
        size = der[offset + 1]
        value = der[offset + 2:offset + 2 + size].lstrip(b'\0')
        if not 0 < len(value) <= 32:
            raise ValueError('Expected a P-256 signature integer')
        parts.append(value.rjust(32, b'\0'))
        offset += 2 + size
    if offset != len(der):
        raise ValueError('Unexpected trailing signature bytes')
    return message + '.' + encoded(b''.join(parts))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app_id')
    parser.add_argument('build_number')
    parser.add_argument('platform', choices=['IOS', 'MAC_OS'])
    parser.add_argument('key_path')
    parser.add_argument('--timeout', type=int, default=1200)
    args = parser.parse_args()
    query = urllib.parse.urlencode({'filter[app]': args.app_id,
                                   'filter[version]': args.build_number,
                                   'include': 'preReleaseVersion', 'limit': '200'})
    url = 'https://api.appstoreconnect.apple.com/v1/builds?' + query
    deadline = time.monotonic() + args.timeout
    # The upload can precede API visibility. Re-read Apple's record until the exact
    # platform becomes VALID; an invalid build or permanent authentication error fails.
    while True:
        request = urllib.request.Request(url, headers={'Authorization': 'Bearer ' + token(args.key_path)})
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                payload = json.load(response)
        except urllib.error.HTTPError as error:
            if error.code != 429 and error.code < 500:
                raise RuntimeError(f'App Store Connect returned HTTP {error.code}') from None
            print(f'App Store Connect temporarily returned HTTP {error.code}', flush=True)
            payload = {}
        platforms = {item['id']: item['attributes']['platform']
                     for item in payload.get('included', []) if item['type'] == 'preReleaseVersions'}
        for build in payload.get('data', []):
            release = build['relationships']['preReleaseVersion']['data']['id']
            if platforms.get(release) != args.platform or build['attributes']['version'] != args.build_number:
                continue
            state = build['attributes']['processingState']
            result = {'app': args.app_id, 'build': args.build_number, 'platform': args.platform,
                      'id': build['id'], 'processingState': state}
            print(json.dumps(result), flush=True)
            if state == 'VALID':
                summary = os.environ.get('GITHUB_STEP_SUMMARY')
                if summary:
                    with open(summary, 'a') as output:
                        output.write(f"\nApp {args.app_id}, {args.platform}, build {args.build_number}: **VALID** (build ID {build['id']}).\n")
                return
            if state in ('FAILED', 'INVALID'):
                raise RuntimeError(f'Apple rejected build processing: {state}')
        if time.monotonic() >= deadline:
            raise TimeoutError(f'Build {args.build_number} for {args.platform} did not reach VALID')
        print(f'Waiting for {args.platform} build {args.build_number} processing', flush=True)
        time.sleep(min(30, max(0, deadline - time.monotonic())))


if __name__ == '__main__':
    main()
