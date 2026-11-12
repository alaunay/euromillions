#!/usr/bin/env python3
"""Validate metadata.json against the subset of the module format used here.

The layout follows the OpenVox module metadata: a name, a version, the
sources, and an operating_system_support list. Exit status 1 on a problem.
"""

import json
import re
import sys
from pathlib import Path

REQUIRED = (
    "name",
    "version",
    "author",
    "summary",
    "license",
    "source",
    "dependencies",
    "operating_system_support",
)

NAME = re.compile(r"^[a-z0-9_]+-[a-z0-9_]+$")
VERSION = re.compile(r"^\d+\.\d+\.\d+([-.+][0-9A-Za-z.-]+)?$")
NUMBER = re.compile(r"^\d+(\.\d+)*$")


def fail(message):
    print(f"metadata.json: {message}", file=sys.stderr)
    return 1


def main():
    path = Path("metadata.json")

    try:
        metadata = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return fail(str(error))

    if not isinstance(metadata, dict):
        return fail("the document must be an object")

    for key in REQUIRED:
        if key not in metadata:
            return fail(f"missing key '{key}'")

    name = metadata["name"]
    if not isinstance(name, str) or not NAME.match(name):
        return fail("'name' must look like author-module")

    version = metadata["version"]
    if not isinstance(version, str) or not VERSION.match(version):
        return fail("'version' must be a semantic version")

    if not isinstance(metadata["dependencies"], list):
        return fail("'dependencies' must be a list")

    systems = metadata["operating_system_support"]

    if not isinstance(systems, list) or not systems:
        return fail("'operating_system_support' must be a non-empty list")

    seen = set()

    for entry in systems:
        if not isinstance(entry, dict):
            return fail("each operating system must be an object")

        system = entry.get("operating_system")

        if not isinstance(system, str) or not system:
            return fail("each operating system needs a name")

        if system in seen:
            return fail(f"'{system}' is listed twice")

        seen.add(system)

        for bound in ("min_version", "max_version"):
            if bound in entry and not NUMBER.match(str(entry[bound])):
                return fail(f"'{bound}' of '{system}' must be a number")

    print(f"metadata.json: ok, {len(seen)} systems")
    return 0


if __name__ == "__main__":
    sys.exit(main())
