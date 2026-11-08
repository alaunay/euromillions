# AGENTS.md

Guidance for agents working in this repository.

## Project

`euromillions.sh` draws 5 numbers from 1-50 and 2 stars from 1-12 with
`shuf`, sorts them, and prints them. There is no build step.

Run it with:

```
./euromillions.sh [--lang CODE]
```

The grid shape lives in the variables at the top of the script. Each one
reads its environment, with the EuroMillions value as the default.

Output strings are gettext msgids in `euromillions.sh`. Translations
live in `po/`, with `po/euromillions.pot` as the template. `CODE` comes
from `--lang`, then `EUROMILLIONS_LANG`, then the locale, then `en`. An
unknown code falls back to `en`, and a missing gettext binary prints the
msgids. When the resolved language has no working catalogue, the script
warns on stderr and continues in English.

Run `tools/build-locales.sh` after editing a `.po`; it compiles to
`locale/CODE/LC_MESSAGES/euromillions.mo`, which is ignored by git. CI
builds it too.

## Tests

The test suite needs [bats-core](https://github.com/bats-core/bats-core)
and [shellcheck](https://www.shellcheck.net/). Both are required, and CI
fails on a missing binary as well as on a finding:

```
bats test/euromillions.bats
shellcheck euromillions.sh .githooks/commit-msg tools/build-locales.sh
```

`RANDOM_SOURCE` overrides the entropy source that `shuf` reads. A fixed
file makes a draw reproducible, which the tests use. The default is
`/dev/urandom`.

The suite runs the shellcheck command as one of its cases.

GitHub Actions runs shellcheck and the suite on every push to `master`
and on every pull request, in `.github/workflows/tests.yml`.

## Demo

`assets/demo.svg`, the animation used by the README, comes from the
[terminal-svg-demo](https://github.com/alaunay/terminal-svg-demo)
repository, driven by `assets/demo.json`:

```
git clone https://github.com/alaunay/terminal-svg-demo.git
python3 terminal-svg-demo/make_demo.py assets/demo.json assets/demo.svg
```

It animates with SMIL, so it needs no player and no JavaScript. Update
`assets/demo.json` when the outputs or the palette change.

## Code conventions

- Bash only, bash 4 or later (`mapfile` is required).
- Indent with tabs.
- Keep `set -euo pipefail` at the top.
- Quote every expansion.
- Colour escapes come from `setup_colors` only. Never print a raw
  escape, and keep the output readable when colour is disabled.
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

### Enforcement

- `master` requires GPG-signed commits. The rule is remote, applies to
  administrators, and rejects an unsigned push. `commit.gpgsign` must be
  true and the signing key must be registered on GitHub.
- The commit email must be a verified UID of the signing key. This
  repository sets `user.email` to `asl@launay.org` for that reason.
  Never commit here with the `users.noreply.github.com` address: GitHub
  answers `bad_email` and rejects the push.
- The DCO app checks both trailers on pull requests, and only there. A
  direct push is not covered by the app.
- `.githooks/commit-msg` rejects a commit with a missing or malformed
  trailer, or a `Signed-off-by` address that differs from the committer.
  Enable it per clone with `git config core.hooksPath .githooks`.
- The hook is a guard against mistakes, not a barrier. `git commit
  --no-verify` bypasses it.

### Pull requests

`master` takes pull requests only. Push a branch, open a pull request, and
merge it once the `bats` check is green. Direct pushes are rejected, and
force pushes are disabled.

### Commit messages

- Subject line in the imperative mood, no trailing period.
- Body wrapped at 72 columns, explaining the problem and the reason for
  the change.
- One logical change per commit.
