#!/usr/bin/env python3
"""Print the proto-hive's finished work as a Markdown table, from its record (the PROGRESS.md section).

Usage: proto-hive-progress.py EXPORT.jsonl [REGISTRY.json]

EXPORT.jsonl is `hive export` of the proto-hive record (tools/proto-hive-progress.sh fetches it).
With REGISTRY.json (proto-hive/deploy/registry.json), each task's last code pin is looked up on GitHub
with `gh` to link the pull request that carries it.
"""
import json
import re
import subprocess
import sys


def github_repo(registry, name):
    for url in registry.get("repositories", {}).get(name, {}).get("fetch_urls", []):
        m = re.match(r"https://github\.com/([^/]+/[^/.]+)", url)
        if m:
            return m.group(1)
    return None


def find_pr(repo, sha):
    try:
        out = subprocess.run(
            ["gh", "pr", "list", "--repo", repo, "--state", "all", "--search", sha,
             "--json", "number,state,url", "--limit", "1"],
            capture_output=True, text=True, timeout=30, check=True).stdout
        prs = json.loads(out)
    except (subprocess.SubprocessError, json.JSONDecodeError):
        return None
    return prs[0] if prs else None


def main():
    events = [json.loads(line) for line in open(sys.argv[1])]
    registry = json.load(open(sys.argv[2])) if len(sys.argv) > 2 else {}

    tasks = {}
    for e in events:
        tid = e.get("task")
        if not tid:
            continue
        t = tasks.setdefault(tid, {"reviews": 0})
        if e["type"] == "task.created":
            t.update(title=e["data"].get("title", ""), project=e["data"].get("project", ""),
                     created=e["recorded_at"][:10])
        elif e["type"] in ("task.assigned", "task.reassigned"):
            t["worker"] = e["data"].get("to", "").removeprefix("worker.")
        elif e["type"] == "task.result_posted":
            code = [r["pin"] for r in e["refs"] if r.get("rel") == "code"]
            if code:
                t["code"] = code[0]
        elif e["type"] == "review.recorded":
            t["reviews"] += 1
            t["verdict"] = e["data"].get("verdict")
        elif e["type"] == "task.closed":
            t["closed"] = e["recorded_at"][:10]

    done = sorted((t for t in tasks.values() if "closed" in t), key=lambda t: t["closed"])
    open_ = [(tid, t) for tid, t in tasks.items() if "closed" not in t and "title" in t]

    print(f"{len(done)} tasks closed after an independent review; {len(open_)} open. "
          f"Record position {events[-1]['position']} ({events[-1]['recorded_at'][:16]}Z).\n")
    print("| Closed | Project | Task | Bot | Reviews | Code |")
    print("|---|---|---|---|---|---|")
    for t in done:
        code = "—"
        if "code" in t:
            repo = github_repo(registry, t["code"]["repository"])
            sha = t["code"]["commit_oid"].removeprefix("sha1:")
            pr = find_pr(repo, sha) if repo else None
            code = (f"[#{pr['number']}]({pr['url']}) {pr['state'].lower()}" if pr
                    else f"`{t['code']['repository']}@{sha[:7]}`")
        print(f"| {t['closed']} | {t['project']} | {t['title']} | {t.get('worker', '')} "
              f"| {t['reviews']} | {code} |")
    if open_:
        print("\nOpen: " + "; ".join(f"{t['title']} ({t.get('worker', 'unassigned')})" for _, t in open_))


if __name__ == "__main__":
    main()
