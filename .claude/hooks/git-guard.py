#!/usr/bin/env python3
"""PreToolUse Bash hook: block git and process commands that bit past sessions (/insights 2026-11-07).

Blocks: a push without an explicit branch, a force push without --force-with-lease, fetch --prune,
git clean -f (deletes untracked work such as records/), and pkill/killall (matched Claude's own shell).
Exit 2 blocks and feeds stderr to Claude. With --copilot (Copilot CLI preToolUse) it prints a deny decision as
JSON instead. Run with --selftest to check the rules.
"""

import json
import re
import shlex
import sys

SPLIT = re.compile(r"&&|\|\||[;|\n]")


def reason(segment):
    """Why this one simple command is blocked, or None."""
    try:
        words = shlex.split(segment)
    except ValueError:
        words = segment.split()
    while words and "=" in words[0] and not words[0].startswith("-"):  # drop FOO=bar prefixes
        words = words[1:]
    if not words:
        return None
    if words[0] in ("pkill", "killall"):
        return "pattern kills can match this session's own shells; kill exact PIDs instead"
    if words[0] != "git":
        return None
    args = words[1:]
    while args and args[0] in ("-C", "-c") and len(args) > 1:  # skip git -C dir / -c k=v
        args = args[2:]
    if not args:
        return None
    sub, rest = args[0], args[1:]
    flags = [a for a in rest if a.startswith("-")]
    positional = [a for a in rest if not a.startswith("-")]
    if sub == "push":
        if any(f in ("--force", "-f") or (re.fullmatch(r"-[a-z]*f[a-z]*", f)) for f in flags):
            return "force push needs --force-with-lease, and the user's go-ahead"
        if "--delete" in flags or "-d" in flags or any(p.startswith(":") for p in positional):
            return None  # deleting a named remote branch is explicit
        if len(positional) < 2:
            return "name the branch: git push origin <branch> (a bare push created an unwanted branch before)"
    if sub == "fetch" and ("--prune" in flags or "-p" in flags):
        return "fetch --prune deletes remote-tracking refs other sessions may use; ask the user first"
    if sub == "clean" and ("--force" in flags or any("f" in f for f in flags if not f.startswith("--"))):
        return "git clean deletes untracked files (research data like records/); ask the user first"
    return None


def check(command):
    for segment in SPLIT.split(command):
        why = reason(segment.strip())
        if why:
            return f"Blocked by ~/.claude/hooks/git-guard.py: `{segment.strip()}`: {why}"
    return None


def selftest():
    blocked = [
        "git push", "git push origin", "git push -u origin", "git push --force origin x",
        "git push -f origin x", "cd a && git push origin", "git fetch --prune", "git fetch -p origin",
        "git clean -fd", "git clean -xfd", "pkill -f pytest", "killall python", "git -C /r push origin",
    ]
    allowed = [
        "git push origin feat/x", "git push -u origin feat/x", "git push --force-with-lease origin feat/x",
        "git push origin --delete old", "git push origin HEAD", "git fetch origin", "git clean -n",
        "kill 1234", "echo git push", "git status", "uv run pytest -q", "git commit -m 'push it'",
    ]
    bad = [c for c in blocked if not check(c)] + [c for c in allowed if check(c)]
    assert not bad, f"wrong verdict for: {bad}"
    print("git-guard selftest ok")


if __name__ == "__main__":
    if sys.argv[1:] == ["--selftest"]:
        selftest()
        sys.exit(0)
    copilot = sys.argv[1:] == ["--copilot"]
    try:
        data = json.load(sys.stdin)
        args = data.get("tool_input", data.get("toolArgs"))  # Copilot's camelCase payload uses toolArgs
        if isinstance(args, str):
            args = json.loads(args)
        command = args["command"]
    except (ValueError, KeyError, TypeError, AttributeError):
        sys.exit(0)  # not a shell call we understand: let it through
    why = check(command)
    if why and copilot:
        print(json.dumps({"permissionDecision": "deny", "permissionDecisionReason": why}))
    elif why:
        print(why, file=sys.stderr)
        sys.exit(2)
