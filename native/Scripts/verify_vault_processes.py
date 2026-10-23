#!/usr/bin/env python3
"""Prove acknowledged saves survive SIGKILL and independent concurrent writers.
macOS native CI calls this against the Release VaultIntegrityProbe executable.
"""
import json
from pathlib import Path
import subprocess
import sys
import tempfile

probe = str(Path(sys.argv[1]).resolve())
with tempfile.TemporaryDirectory(prefix="mm-durability-") as folder:
    vault = str(Path(folder) / "vault.json")
    writer = subprocess.Popen([probe, "write", vault, "killed", "100000"], stdout=subprocess.PIPE, text=True)
    acknowledged = {writer.stdout.readline().strip() for _ in range(40)}
    assert "" not in acknowledged, "Writer exited before acknowledging forty durable saves"
    writer.kill()
    writer.wait(timeout=10)
    assert writer.returncode < 0, "Writer was not killed by a signal"
    after_kill = set(json.loads(subprocess.check_output([probe, "read", vault], text=True)))
    assert acknowledged <= after_kill, f"Acknowledged captures lost: {acknowledged - after_kill}"
    writers = [subprocess.Popen([probe, "write", vault, name, "100"], stdout=subprocess.PIPE, text=True) for name in ["phone", "mac"]]
    for process in writers:
        process.communicate(timeout=60)
        assert process.returncode == 0, "Concurrent writer failed"
    reopened = json.loads(subprocess.check_output([probe, "read", vault], text=True))
    for name in ["phone", "mac"]:
        assert {f"{name}-{i}" for i in range(100)} <= set(reopened), f"Lost {name} originals"
    assert len(reopened) == len(set(reopened)), "Duplicate or overwritten captures"
    print(f"MM_DURABILITY acknowledged_before_sigkill={len(acknowledged)} recovered={len(after_kill)} concurrent_new_notes=200 PASS")
