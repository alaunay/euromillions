#!/usr/bin/env python3
"""Convert shellcheck's json1 output into SARIF 2.1.0.

GitHub code scanning accepts SARIF only. ShellCheck has no SARIF writer, so
this reads `shellcheck -f json1 FILE` and writes a minimal, valid document.

    shellcheck -f json1 script.sh > shellcheck.json
    python3 tools/shellcheck-sarif.py shellcheck.json shellcheck.sarif
"""

import json
import sys
from pathlib import Path

LEVELS = {
    "error": "error",
    "warning": "warning",
    "info": "note",
    "style": "note",
}


def rule(finding):
    code = finding["code"]
    return {
        "id": f"SC{code}",
        "name": f"SC{code}",
        "shortDescription": {"text": finding["message"].splitlines()[0]},
        "helpUri": f"https://www.shellcheck.net/wiki/SC{code}",
    }


def result(finding, rules):
    code = f"SC{finding['code']}"
    return {
        "ruleId": code,
        "ruleIndex": rules.index(code),
        "level": LEVELS.get(finding.get("level", "warning"), "warning"),
        "message": {"text": finding["message"]},
        "locations": [
            {
                "physicalLocation": {
                    "artifactLocation": {"uri": finding["file"]},
                    "region": {
                        "startLine": finding["line"],
                        "startColumn": finding["column"],
                        "endLine": finding.get("endLine", finding["line"]),
                        "endColumn": finding.get("endColumn", finding["column"]),
                    },
                }
            }
        ],
    }


def convert(findings):
    rule_ids = []

    for finding in findings:
        code = f"SC{finding['code']}"
        if code not in rule_ids:
            rule_ids.append(code)

    rules = [rule(f) for f in findings if f"SC{f['code']}" in rule_ids]
    seen = set()
    unique = []
    for entry in rules:
        if entry["id"] in seen:
            continue
        seen.add(entry["id"])
        unique.append(entry)

    return {
        "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
        "version": "2.1.0",
        "runs": [
            {
                "tool": {
                    "driver": {
                        "name": "ShellCheck",
                        "informationUri": "https://www.shellcheck.net",
                        "rules": unique,
                    }
                },
                "results": [result(finding, rule_ids) for finding in findings],
            }
        ],
    }


def main(argv):
    source = Path(argv[1]) if len(argv) > 1 else Path("shellcheck.json")
    target = Path(argv[2]) if len(argv) > 2 else Path("shellcheck.sarif")

    document = json.loads(source.read_text(encoding="utf-8"))

    # json1 wraps the list, json does not; accept both
    findings = document.get("comments") if isinstance(document, dict) else document

    if not isinstance(findings, list):
        print(f"{source}: expected a list of findings", file=sys.stderr)
        return 1

    target.write_text(json.dumps(convert(findings), indent=2) + "\n", encoding="utf-8")
    print(f"wrote {target}: {len(findings)} findings")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
