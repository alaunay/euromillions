#!/usr/bin/env python3
"""Generate a Markdown changelog section from the git history.

    python3 tools/changelog.py v0.0.1

The range runs from the previous v* tag to the given one, or from the
first commit when there is no previous tag. Commits are grouped by a
Conventional Commits prefix when they carry one, and listed under
"Changes" otherwise.
"""

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

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


GIT = shutil.which("git") or ""


def git(*args):
    if not GIT:
        raise RuntimeError("git is not installed")

    # The arguments are validated tags and fixed flags, never shell input
    return subprocess.run(  # noqa: S603
        [GIT, *args], check=True, capture_output=True, text=True
    ).stdout.strip()


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


TAG = re.compile(r"^v\d+\.\d+\.\d+$")


def build(version):
    tag = version if version.startswith("v") else f"v{version}"

    if not TAG.match(tag):
        raise ValueError(f"invalid tag: {version}")

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


INTRO = """# Changelog

Generated from the git history by `tools/changelog.py`; run it for a tag to
write the release notes.
"""


SECTION = re.compile(r"(?m)^## v\S.*$")


def merge(path, tag, text):
    """Insert or replace the section for tag, newest first."""
    if path.is_file():
        document = path.read_text(encoding="utf-8")
        starts = [match.start() for match in SECTION.finditer(document)]

        if starts:
            header = document[: starts[0]]
            sections = [
                document[start:end]
                for start, end in zip(starts, starts[1:] + [len(document)], strict=False)
            ]
        else:
            header, sections = document, []
    else:
        header, sections = INTRO, []

    sections = [block for block in sections if not block.startswith(f"## {tag} ")]
    sections.insert(0, text.rstrip() + "\n")

    return header.rstrip() + "\n\n" + "\n".join(sections).rstrip() + "\n"


def main(argv):
    parser = argparse.ArgumentParser(description="Build a changelog section")
    parser.add_argument("tag", help="tag to document, such as v1.2.3")
    parser.add_argument("--output", help="insert or replace the section in this file")
    arguments = parser.parse_args(argv[1:])

    try:
        text = build(arguments.tag)
    except ValueError as error:
        print(error, file=sys.stderr)
        return 2
    except subprocess.CalledProcessError as error:
        print(f"git failed: {error}", file=sys.stderr)
        return 1

    if arguments.output:
        path = Path(arguments.output)
        path.write_text(merge(path, arguments.tag, text), encoding="utf-8")
        print(f"wrote {path}: {arguments.tag}")
    else:
        sys.stdout.write(text)

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
