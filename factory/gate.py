#!/usr/bin/env python3
# Trusted workflow_run consumer, called only by pr-gate.yml at github.sha.
# Reads one bounded JSON artifact; never extracts files or executes PR content.
import io
import json
import os
from pathlib import Path
import re
import zipfile

from intake import api, CODES, SHA, metadata_digest

FIELDS = {"schema_version", "metadata_digest", "repository", "pr_number", "head_sha", "base_sha", "lane", "label", "reasons", "size", "verdict", "run_id", "run_attempt"}
ADVICE = {
    "LANE_D_OUTSIDER": "Ask a maintainer to make CI, dependency, build or keyboard-capability changes in a trusted branch.",
    "SIZE_LIMIT": "Split the change to at most 1,000 added/deleted lines and 100 files (see factory/lanes.json for current caps).",
    "ISSUE_REQUIRED": "Link a repository issue in the body with Refs #123 or its full issue URL, then open a new PR.",
    "INVALID_PATH": "Remove paths that escape the repository or use backslashes.",
    "FILES_INCOMPLETE": "Reduce the file count and open a new PR so every changed path can be checked."
}


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate JSON key")
        result[key] = value
    return result


def validate(data):
    """Closed schema: unexpected fields, coercions and inconsistent verdicts fail."""
    if type(data) is not dict or set(data) != FIELDS:
        raise ValueError("invalid result fields")
    if type(data["schema_version"]) is not int or data["schema_version"] != 1:
        raise ValueError("unknown schema")
    for key in ("pr_number", "run_id", "run_attempt"):
        if type(data[key]) is not int or not 0 < data[key] < 2**63:
            raise ValueError("invalid identifier")
    if not isinstance(data["repository"], str) or not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", data["repository"]):
        raise ValueError("invalid repository")
    if any(not isinstance(data[key], str) or not re.fullmatch(SHA, data[key]) for key in ("head_sha", "base_sha")):
        raise ValueError("invalid commit")
    if not isinstance(data["metadata_digest"], str) or not re.fullmatch(r"[0-9a-f]{64}", data["metadata_digest"]):
        raise ValueError("invalid metadata digest")
    if type(data["lane"]) is not str or data["lane"] not in ("A", "B", "C", "D"):
        raise ValueError("invalid lane")
    if data["label"] != "lane-" + data["lane"].lower():
        raise ValueError("invalid label")
    reasons = data["reasons"]
    if type(reasons) is not list or any(type(code) is not str or code not in CODES for code in reasons):
        raise ValueError("invalid reason code")
    if reasons != sorted(set(reasons)):
        raise ValueError("duplicate/unsorted reasons")
    size = data["size"]
    if type(size) is not dict or set(size) != {"files", "lines"} or any(type(n) is not int or not 0 <= n < 2**63 for n in size.values()):
        raise ValueError("invalid size")
    expected = "REJECT" if reasons else ("PASS" if data["lane"] == "A" else "ROUTE")
    if data["verdict"] != expected:
        raise ValueError("inconsistent verdict")
    return data


def read_artifact(blob):
    if len(blob) > 65536:
        raise ValueError("artifact too large")
    with zipfile.ZipFile(io.BytesIO(blob)) as archive:
        entries = archive.infolist()
        if len(entries) != 1 or entries[0].filename != "intake.json" or entries[0].file_size > 16384:
            raise ValueError("expected only bounded intake.json")
        return validate(json.loads(archive.read(entries[0]), object_pairs_hook=unique_object))


def bind_result(data, run, pr, repository):
    # PR identifiers from artifacts never independently authorize a write. The
    # head/repository/branch binding also works when fork run.pull_requests is empty.
    if (data["repository"] != repository or run["repository"]["full_name"] != repository
            or run["event"] != "pull_request" or run["conclusion"] != "success"
            or run["path"] != ".github/workflows/pr-intake.yml"
            or data["run_id"] != run["id"] or data["run_attempt"] != run["run_attempt"]
            or data["metadata_digest"] != metadata_digest(pr)
            or data["pr_number"] != pr["number"] or pr["state"] != "open"
            or data["head_sha"] != run["head_sha"] or data["head_sha"] != pr["head"]["sha"]
            or data["base_sha"] != pr["base"]["sha"] or pr["base"]["repo"]["full_name"] != repository
            or pr["head"]["repo"]["full_name"] != run["head_repository"]["full_name"]
            or pr["head"]["ref"] != run["head_branch"]
            or (run["pull_requests"] and pr["number"] not in [p["number"] for p in run["pull_requests"]])):
        raise ValueError("unbound or stale result; rerun intake")


def main():
    event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text())
    repository = os.environ["GITHUB_REPOSITORY"]
    run_id = event["workflow_run"]["id"]
    run = api(f"repos/{repository}/actions/runs/{int(run_id)}")
    artifacts = api(f"repos/{repository}/actions/runs/{int(run_id)}/artifacts?per_page=100")["artifacts"]
    matches = [a for a in artifacts if a["name"] == "pr-intake" and not a["expired"]]
    if len(matches) != 1 or matches[0]["size_in_bytes"] > 65536:
        raise ValueError("missing, ambiguous or oversized artifact")
    data = read_artifact(api(f"repos/{repository}/actions/artifacts/{int(matches[0]['id'])}/zip", raw=True))
    pr = api(f"repos/{repository}/pulls/{data['pr_number']}")
    bind_result(data, run, pr, repository)
    # A PR can edit its pull_request workflow. Only accept results when the
    # producer at both head and base is byte-identical to the trusted workflow.
    # Changes to factory scripts remain safe: this workflow checks out base.sha.
    trusted = Path(".github/workflows/pr-intake.yml").read_bytes()
    import base64
    for commit in (data["head_sha"], data["base_sha"]):
        source = api(f"repos/{repository}/contents/.github/workflows/pr-intake.yml?ref={commit}")
        if base64.b64decode(source["content"]) != trusted:
            raise ValueError("producer workflow changed; maintainer review required")

    # Create the selected label if needed, then replace only the lane labels.
    labels = api(f"repos/{repository}/labels?per_page=100")
    if data["label"] not in [label["name"] for label in labels]:
        api(f"repos/{repository}/labels", "POST", {"name": data["label"], "color": "ededed"})
    api(f"repos/{repository}/issues/{pr['number']}/labels", "POST", {"labels": [data["label"]]})
    for label in pr["labels"]:
        if label["name"] in {"lane-a", "lane-b", "lane-c", "lane-d"} and label["name"] != data["label"]:
            api(f"repos/{repository}/issues/{pr['number']}/labels/{label['name']}", "DELETE", raw=True)
    if data["verdict"] == "REJECT":
        # Comment text is entirely maintainer-owned; no PR text is echoed.
        body = "Factory intake rejected this PR.\n\n" + "\n".join(
            f"- `{code}`: {ADVICE[code]}" for code in data["reasons"])
        body += "\n\nSee docs/FACTORY.md. No code was run and no AI tokens were used."
        api(f"repos/{repository}/issues/{pr['number']}/comments", "POST", {"body": body})
        api(f"repos/{repository}/pulls/{pr['number']}", "PATCH", {"state": "closed"})
    print(f"PR #{pr['number']}: {data['label']} {data['verdict']}")


if __name__ == "__main__":
    main()
