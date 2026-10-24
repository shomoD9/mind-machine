#!/usr/bin/env python3
# Classifies PR metadata and paths without checking out or executing PR code. Called
# by pr-intake.yml from the base commit, by gate.py for schema constants, and CLI.
import argparse
import fnmatch
import hashlib
import json
import os
from pathlib import Path
import posixpath
import re
import subprocess

CODES = {"LANE_D_OUTSIDER", "SIZE_LIMIT", "ISSUE_REQUIRED", "INVALID_PATH", "FILES_INCOMPLETE"}
TRUSTED = {"OWNER", "MEMBER", "COLLABORATOR"}
SHA = r"[0-9a-f]{40}"


def api(endpoint, method="GET", payload=None, raw=False):
    """Only fixed API routes/validated identifiers reach gh; no shell is used."""
    command = ["gh", "api", "--method", method, endpoint]
    if payload is not None:
        command += ["--input", "-"]
    result = subprocess.run(command, input=json.dumps(payload).encode() if payload is not None else None,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
    return result.stdout if raw else json.loads(result.stdout)


def lane_for(path, config):
    # Canonicalize before matching so a/../.github cannot masquerade as lane B.
    normalized = posixpath.normpath(path)
    if not path or "\\" in path or normalized.startswith(("/", "../")) or normalized in {".", ".."}:
        raise ValueError("INVALID_PATH")
    matches = [rule["lane"] for rule in config["rules"]
               if any(fnmatch.fnmatchcase(normalized, pattern) for pattern in rule["paths"])]
    return max(matches, default=config["default_lane"])


def linked_issue(body, repository):
    # Require a local issue reference or this repository's explicit issue URL.
    local = r"\b(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?|refs?|related(?: to)?|issue)\s*:?\s*#[1-9]\d*\b"
    url = r"https://github\.com/" + re.escape(repository) + r"/issues/[1-9]\d*\b"
    return bool(re.search(local, body or "", re.I) or re.search(url, body or "", re.I))


def metadata_digest(pr):
    # Body edits can invalidate an issue verdict without changing the head SHA.
    values = {key: pr[key] for key in ("number", "body", "author_association", "user", "changed_files", "additions", "deletions")}
    values.update({key: pr[key]["sha"] for key in ("head", "base")})
    return hashlib.sha256(json.dumps(values, sort_keys=True).encode()).hexdigest()


def classify(pr, files, config, repository):
    """All matches contribute, including deleted paths and both sides of a rename."""
    lanes, reasons = [], set()
    for file in files:
        for path in [file["filename"], *([file["previous_filename"]] if "previous_filename" in file else [])]:
            try:
                lanes.append(lane_for(path, config))
            except ValueError:
                lanes.append("D")
                reasons.add("INVALID_PATH")
    # Sensitive capability/network edits are data-matched in API patches too;
    # this catches shared-code changes outside the keyboard directory. Missing
    # patches for Swift/plist changes fail into D rather than hiding an edit.
    for file in files:
        path = posixpath.normpath(file["filename"])
        # Documentation and test fixtures can quote these APIs without granting
        # shipping code a capability. Their path rules still apply above.
        if not path.endswith((".swift", ".plist")) or any(
                fnmatch.fnmatchcase(path, pattern) for pattern in config["non_shipping_paths"]):
            continue
        if "patch" not in file and file.get("additions", 1) + file.get("deletions", 1) > 0:
            lanes.append("D")
        for line in file.get("patch", "").splitlines():
            if line.startswith(("+", "-")) and not line.startswith(("+++", "---")):
                if any(re.search(pattern, line[1:], re.I) for pattern in config["sensitive_diff_patterns"]):
                    lanes.append("D")
    lane = max(lanes, default="B")
    size = {"files": pr["changed_files"], "lines": pr["additions"] + pr["deletions"]}
    trusted = pr["author_association"] in TRUSTED or (
        pr["user"]["type"] == "Bot" and pr["user"]["login"] in config["trusted_bots"])
    if size["files"] != len(files):
        reasons.add("FILES_INCOMPLETE")
    if size["lines"] > config["max_changed_lines"] or size["files"] > config["max_files"]:
        reasons.add("SIZE_LIMIT")
    if not trusted:
        if lane == "D":
            reasons.add("LANE_D_OUTSIDER")
        if not linked_issue(pr.get("body"), repository):
            reasons.add("ISSUE_REQUIRED")
    # PASS means intake only. No verdict is merge evidence in this phase.
    return {"schema_version": 1, "metadata_digest": metadata_digest(pr), "repository": repository, "pr_number": pr["number"],
            "head_sha": pr["head"]["sha"], "base_sha": pr["base"]["sha"],
            "lane": lane, "label": "lane-" + lane.lower(), "reasons": sorted(reasons),
            "size": size, "verdict": "REJECT" if reasons else ("PASS" if lane == "A" else "ROUTE")}


def read_pr(repository, number):
    pr = api(f"repos/{repository}/pulls/{number}")
    files = []
    # GitHub caps this endpoint at 3,000 files; incomplete lists fail closed.
    for page in range(1, 31):
        batch = api(f"repos/{repository}/pulls/{number}/files?per_page=100&page={page}")
        files.extend(batch)
        if len(batch) < 100:
            break
    after = api(f"repos/{repository}/pulls/{number}")
    for key in ("head", "base", "body", "changed_files", "additions", "deletions", "author_association"):
        before_value, after_value = pr[key], after[key]
        if key in {"head", "base"}:
            before_value, after_value = before_value["sha"], after_value["sha"]
        if before_value != after_value:
            raise ValueError("PR changed during intake; rerun")
    return pr, files


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY"), required=False)
    parser.add_argument("--pr", type=int, required=True)
    args = parser.parse_args()
    if not args.repo or not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", args.repo) or args.pr < 1:
        parser.error("valid --repo owner/name and positive --pr required")
    config = json.loads(Path(__file__).with_name("lanes.json").read_text())
    pr, files = read_pr(args.repo, args.pr)
    # In Actions, bind the API snapshot to the immutable triggering event.
    if os.environ.get("GITHUB_EVENT_PATH"):
        event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text())["pull_request"]
        if any(pr[key]["sha"] != event[key]["sha"] for key in ("base", "head")):
            raise ValueError("PR changed since event; rerun")
    print(json.dumps(classify(pr, files, config, args.repo), sort_keys=True))


if __name__ == "__main__":
    main()
