# AGENTS.md

Guidance for agents working in this repository.

## Project

`euromillions.sh` draws 5 numbers from 1-50 and 2 stars from 1-12 with
`shuf`, sorts them, and prints them. There is no build step and no test
suite.

Run it with:

```
./euromillions.sh
```

Configuration lives in the variables at the top of the script.

## Code conventions

- Bash only, bash 4 or later (`mapfile` is required).
- Indent with tabs.
- Keep `set -euo pipefail` at the top.
- Quote every expansion.
- A failing command must fail the script. Never hide a status behind a
  process substitution.
- Comments explain why, not what.

## Commit rules

### Co-authored-by is mandatory

Every commit that contains work produced with an agent must end with a
`Co-authored-by` trailer. This is a hard rule, not a preference.

Format, after a blank line at the end of the commit body:

```
Co-authored-by: Name <email>
```

Example for an agent running through opencode:

```
Co-authored-by: DeepSeek V4.1 Flash <noreply@opencode.ai>
```

Rules for the trailer:

- One `Co-authored-by` line per contributing agent.
- Use the agent's real name and a real address. Never invent an address,
  never use a placeholder, never use `noreply@example.com`.
- The trailer names the agent that produced the change, not the human
  who requested it.
- A commit without the trailer is incomplete and must be amended before
  push.

### Signed-off-by is mandatory

Every commit must carry a `Signed-off-by` trailer. This certifies the
Developer Certificate of Origin: the contributor has the right to
submit the code under the project licence. It is a hard rule, like the
`Co-authored-by` trailer.

Format, at the end of the commit message, after the `Co-authored-by`
trailer:

```
Signed-off-by: Name <email>
```

Rules for the trailer:

- The name and the email must match the commit committer identity. A
  mismatch invalidates the sign-off.
- Use `git commit -s` (or `git commit --trailer "Signed-off-by: ..."`)
  so git writes the line. Never type it by hand with a different
  identity.
- Amend the commit if the trailer is missing. Do not add it in a
  follow-up commit.

### Trailers summary

A complete agent-assisted commit ends with, in this order:

```
Co-authored-by: Name <email>
Signed-off-by: Name <email>
```

### Commit messages

- Subject line in the imperative mood, no trailing period.
- Body wrapped at 72 columns, explaining the problem and the reason for
  the change.
- One logical change per commit.
