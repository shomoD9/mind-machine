#!/usr/bin/env python3
"""Fetch the pinned MIT MiniSearch comparison bundle without installing packages.
The macOS CI comparison calls this; production targets never load JavaScript.
"""
import base64
import hashlib
from pathlib import Path
import sys
import tarfile
import io
import urllib.request

folder = Path(sys.argv[1])
folder.mkdir(parents=True, exist_ok=True)
with urllib.request.urlopen("https://registry.npmjs.org/minisearch/-/minisearch-7.1.0.tgz", timeout=30) as response:
    data = response.read()
expected = "tv7c/uefWdEhcu6hvrfTihflgeEi2tN6VV7HJnCjK6VxM75QQJh4t9FwJCsA2EsRS8LCnu3W87CuGPWMocOLCA=="
assert base64.b64encode(hashlib.sha512(data).digest()).decode() == expected, "Pinned tarball integrity mismatch"
with tarfile.open(fileobj=io.BytesIO(data), mode="r:gz") as archive:
    for member, name in [("package/dist/umd/index.js", "index.js"), ("package/LICENSE.txt", "LICENSE.txt")]:
        (folder / name).write_bytes(archive.extractfile(member).read())
assert hashlib.sha256((folder / "index.js").read_bytes()).hexdigest() == "bd47ccf2b0028aaee23a301b018f238e0e511b6e8439fd9cdaf8e4242c46e149"
print("MiniSearch 7.1.0 integrity verified; benchmark-only MIT bundle")
