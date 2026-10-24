#!/usr/bin/env python3
# Small source guard for GitHub workflow trust rules; called by checks.sh and
# test_intake.py. actionlint supplies full YAML/Actions syntax validation.
from pathlib import Path
import re
import sys


def violations(source):
    # This repo needs no pull_request_target jobs. Forbid the event entirely so
    # aliases/expressions cannot hide a PR-head checkout under a write token.
    lines = [line.split("#", 1)[0].rstrip() for line in source.splitlines()]
    errors = []
    if not any(re.fullmatch(r"permissions:\s*(?:\{.*\})?", line) for line in lines):
        errors.append("missing top-level permissions")
    if any(re.search(r"\bpull_request_target\b", line) for line in lines):
        errors.append("pull_request_target forbidden: use read-only pull_request plus workflow_run")
    for line in lines:
        # Also inspect quoted keys and inline mappings, so changing YAML style
        # cannot turn a floating action into an invisible one.
        matches = re.finditer(r"(?:^|[\s{,])['\"]?uses['\"]?\s*:\s*('(?:[^']*)'|\"(?:[^\"]*)\"|[^,\s}\]]*)", line)
        for match in matches:
            action = match[1].strip("\"'")
            if not pinned(action):
                errors.append(f"unpinned action: {action}")
    return errors


def pinned(action):
    # Local actions are repository code. Remote actions and reusable workflows
    # must use an exact Git commit; Docker actions require a content digest.
    return (action.startswith("./")
            or bool(re.fullmatch(r"[^\s@]+@[0-9a-f]{40}", action))
            or bool(re.fullmatch(r"docker://[^\s]+@sha256:[0-9a-f]{64}", action)))


def main():
    root = Path(__file__).resolve().parents[1]
    errors = [f"{path.relative_to(root)}: {error}" for path in sorted((root / ".github/workflows").iterdir())
              if path.suffix in {".yml", ".yaml"} for error in violations(path.read_text())]
    print("\n".join(errors) if errors else "Workflow trust rules PASS")
    return bool(errors)


if __name__ == "__main__":
    sys.exit(main())
