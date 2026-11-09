# Contributing

Development notes for `euromillions`. The user-facing documentation is in
[README.md](README.md).

- [Tests](#tests)
- [Translations](#translations)
- [Demo](#demo)
- [Packaging](#packaging)
- [Releases](#releases)
- [Code scanning](#code-scanning)
- [Pull requests](#pull-requests)
- [Changelog](#changelog)

## Tests

The suite needs `bats` and `shellcheck`:

```console
$ bats test test/shell
$ shellcheck euromillions.sh .githooks/commit-msg tools/build-locales.sh
```

The bats suite runs the shellcheck command as one of its cases, so a
missing binary fails the case rather than skipping it. Any finding, at any
severity, is a failure.

`test/shell/` also covers the two other shell scripts: the catalogue
builder, exercised in a sandbox, and the commit hook, exercised in a
throwaway repository.

The cases cover the output shape, the ranges, the order, the language
resolution, and the failure paths. GitHub Actions installs both tools,
generates the French locale, builds the catalogues, then runs shellcheck
and the suite on every push to `master` and on every pull request, in
[`.github/workflows/tests.yml`](.github/workflows/tests.yml).

`RANDOM_SOURCE` points `shuf` at another entropy file, which makes a draw
reproducible.

## Translations

Translations are GNU gettext catalogues:

| Path | Role |
| --- | --- |
| `po/euromillions.pot` | template, regenerated from the msgids |
| `po/<code>.po` | one translator file per language |
| `locale/<code>/LC_MESSAGES/euromillions.mo` | compiled form, built and git-ignored |

Add a language:

```console
$ cp po/euromillions.pot po/de.po
$ $EDITOR po/de.po        # fill the msgstr lines, set Language: de
$ tools/build-locales.sh
$ ./euromillions.sh --lang de
```

`tools/build-locales.sh` runs `msgfmt --check`, which fails on a
translation whose `%s` placeholders do not match the source. Poedit,
Weblate, and any PO editor can edit the same files.

After changing a msgid in `euromillions.sh`, update the template and merge
it into each catalogue:

```console
$ xgettext --language=Shell --keyword=_ --output=po/euromillions.pot euromillions.sh
$ msgmerge -U po/fr.po po/euromillions.pot
```

gettext only loads a translation when a locale is active. The script
replaces a `C` locale with the language's own (`fr_FR.UTF-8` for French),
so the locale must be generated on the system: `sudo locale-gen fr_FR.UTF-8`
on Debian, or `localedef`. When it is missing, the script warns and keeps
English.

## Demo

The animation at the top of the README is declarative SVG, not a recording
and not a GIF, so every browser plays it inline without a media player.

The generator lives in its own repository,
[terminal-svg-demo](https://github.com/alaunay/terminal-svg-demo). It is
not needed to run the script, only to refresh the image. `assets/demo.json`
holds the content: commands, outputs, and colours.

```console
$ pipx install git+https://github.com/alaunay/terminal-svg-demo.git
$ terminal-svg-demo assets/demo.json assets/demo.svg
```

`assets/demo.json` names its colours in comments: EuroMillions blue
`#4d6bff` for numbers, EuroMillions gold `#eebb05` for stars, neon green
`#39ff14` for the prompt, near-white `#e6edf3` for the command, cool grey
`#9aa4b2` for the labels. The coloured comment lines need terminal-svg-demo
1.1.0 or later.

The generator needs Python 3.10 or later and no third-party package. Update
`assets/demo.json` when the outputs or the palette change.

## Packaging

Both distributions build from the repository:

```console
$ dpkg-buildpackage -b -us -uc                  # Debian, needs debhelper
$ mkdir -p rpmbuild/SOURCES
$ git archive --format=tar.gz --prefix=euromillions-1.0.0/ \
    --output=rpmbuild/SOURCES/euromillions-1.0.0.tar.gz HEAD
$ rpmbuild -bb packaging/rpm/euromillions.spec --define "_topdir $PWD/rpmbuild"
```

The packages install `euromillions` in `/usr/bin` and its catalogues in
`/usr/share/euromillions`. CI builds both and attaches them to the run.

## Releases

Cut a tag to publish the packages:

```console
$ git tag v1.0.0
$ git push origin v1.0.0
```

`.github/workflows/release.yml` builds the `.deb` and the `.rpm`, attaches
both to the GitHub release, and dispatches the shared packages repository.
The repository carries `0.0.0` as the unreleased placeholder; the workflow
takes the version from the tag and injects it into `debian/changelog` and
the spec before building. The dispatch needs `PACKAGES_TOKEN`, a token with
write access to `alaunay/packages`; without it the daily run of that
repository picks the release up.

## Code scanning

GitHub code scanning shows the shellcheck findings as alerts. ShellCheck has
no SARIF writer, so `tools/shellcheck-sarif.py` converts its JSON output,
and `.github/workflows/tests.yml` uploads the result on every push and pull
request. The alerts are informative; shellcheck still fails the test job on
a finding.

## Pull requests

`master` only takes pull requests, and every pull request must:

- be GPG-signed, or GitHub rejects the push;
- carry `Co-authored-by` and `Signed-off-by` trailers, which the DCO check
  enforces on the pull request;
- pass the `bats` check, which runs shellcheck, generates the French
  locale, builds the catalogues, and runs the suite.

```console
$ git switch -c my-change
$ ...edit, commit, test...
$ git push -u origin my-change
$ gh pr create --fill
$ gh pr merge --squash --delete-branch
```

## Changelog

[`CHANGELOG.md`](CHANGELOG.md) is generated from the git history:

```console
$ python3 tools/changelog.py v0.0.1 --output CHANGELOG.md
```

The release workflow runs the same command for the new tag and uses the
output as the release notes. Commits carrying a Conventional Commits
prefix are grouped; the rest land under "Changes".
