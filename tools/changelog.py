#!/usr/bin/env python3
"""Generate a Markdown changelog section from the git history.

    python3 tools/changelog.py v0.0.1

The range runs from the previous v* tag to the given one, or from the
first commit when there is no previous tag. Commits are grouped by a
Conventional Commits prefix when they carry one, and listed under
"Changes" otherwise.
"""

import re
import subprocess
import sys

SECTIONS = {
    "feat": "Added",
    "fix": "Fixed",
    "docs": "Documentation",
    "test": "Tests",
    "ci": "Build",
    "build": "Build",
    "perf": "Changed",
    "refactor": "Changed",
    "style": "Changed",
    "chore": "Chores",
    "revert": "Reverted",
}

ORDER = [
    "Added",
    "Changed",
    "Fixed",
    "Reverted",
    "Documentation",
    "Tests",
    "Build",
    "Chores",
    "Changes",
]

PREFIX = re.compile(r"^(?P<kind>[a-z]+)(?:\([^)]*\))?!?:\s*(?P<text>.+)$")


def git(*args):
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True).stdout.strip()


def previous_tag(version):
    try:
        return git("describe", "--tags", "--abbrev=0", "--match", "v*", f"{version}^")
    except subprocess.CalledProcessError:
        return None


def commits(version):
    previous = previous_tag(version)
    revision = f"{previous}..{version}" if previous else version
    lines = git("log", "--no-merges", "--pretty=%s", revision).splitlines()
    return [line for line in lines if line]


def section(subject):
    match = PREFIX.match(subject)

    if not match:
        return "Changes", subject

    kind = match.group("kind")
    text = match.group("text").strip()
    title = text[:1].upper() + text[1:] if text else text

    return SECTIONS.get(kind, "Changes"), f"{title} ({kind})" if kind not in SECTIONS else title


def build(version):
    tag = version if version.startswith("v") else f"v{version}"
    day = git("log", "-1", "--format=%as", tag)
    grouped = {}

    for subject in commits(tag):
        group, text = section(subject)
        grouped.setdefault(group, []).append(text)

    out = [f"## {tag} - {day}", ""]

    for group in ORDER:
        entries = grouped.get(group)
        if not entries:
            continue
        out.append(f"### {group}")
        out.append("")
        out.extend(f"- {entry}" for entry in entries)
        out.append("")

    if len(out) == 2:
        out.extend(["No changes.", ""])

    return "\n".join(out)


def main(argv):
    if len(argv) < 2:
        print("usage: changelog.py vX.Y.Z", file=sys.stderr)
        return 2

    try:
        text = build(argv[1])
    except subprocess.CalledProcessError as error:
        print(f"git failed: {error}", file=sys.stderr)
        return 1

    sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
