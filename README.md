<div align="center">

# euromillions

**Five numbers, two stars, straight from your terminal.**

<br>

[![tests](https://github.com/alaunay/euromillions/actions/workflows/tests.yml/badge.svg)](https://github.com/alaunay/euromillions/actions/workflows/tests.yml)
[![license](https://img.shields.io/github/license/alaunay/euromillions?style=flat-square)](LICENSE)
[![bash 4+](https://img.shields.io/badge/bash-4%2B-1f425f?style=flat-square&logo=gnubash&logoColor=white)](#requirements)

<br>
<br>

<img src="assets/demo.svg" alt="Animated terminal session: ./euromillions.sh prints Numbers and Stars, then the same draw in French" width="720">

<br>

</div>

A small Bash script that draws a Euromillions grid: five distinct numbers
from 1 to 50 and two distinct stars from 1 to 12, sorted. No network, no
config file, no build step.

---

## Quick start

```console
$ git clone https://github.com/alaunay/euromillions.git
$ cd euromillions
$ ./euromillions.sh
Numbers: 4 8 13 36 46
Stars: 3 12
```

---

## Usage

```console
$ ./euromillions.sh [-l CODE | --lang CODE] [--no-color] [-h | --help]
```

| Option | Effect |
| --- | --- |
| `-l, --lang CODE` | Set the output language, overriding the locale |
| `--no-color` | Never use colours |
| `-h, --help` | Show the options and the available languages, in the selected language |

Draws are independent, uniform, and read from `/dev/urandom`. Every run
gives a new grid.

Labels are muted, numbers use the EuroMillions blue and stars the
EuroMillions gold, as on the FDJ grid.

Colours are used only when the output goes to a terminal. `NO_COLOR`
disables them, `--no-color` forces them off, and `EUROMILLIONS_COLOR`
accepts `auto`, `always`, or `never` for scripts and pipes.

The palette is 24-bit when `COLORTERM` says `truecolor` or `24bit`, and
falls back to 256-colour codes otherwise, so the hues match the demo.

---

## Configuration

The grid shape comes from the environment, with the EuroMillions values
as defaults:

| Variable | Default | Meaning |
| --- | --- | --- |
| `COUNTNUMBERS` | `5` | numbers per draw |
| `NUMBERSDOWN` | `1` | lowest number |
| `NUMBERSUP` | `50` | highest number |
| `COUNTSTARS` | `2` | stars per draw |
| `STARSDOWN` | `1` | lowest star |
| `STARSUP` | `12` | highest star |

```console
$ COUNTNUMBERS=3 NUMBERSUP=10 ./euromillions.sh
Numbers: 2 6 9
Stars: 4 11
```

---

## Languages

| Code | Language |
| --- | --- |
| `en` | English |
| `fr` | Français |

```console
$ ./euromillions.sh --lang fr
Numéros: 17 19 20 27 48
Étoiles: 5 12
```

The language is resolved in this order: `--lang`, `EUROMILLIONS_LANG`,
the locale (`fr_FR.UTF-8` selects French), then English. An unknown code
falls back to English.

Translations are GNU gettext catalogues:

| Path | Role |
| --- | --- |
| `po/euromillions.pot` | template, regenerated from the msgids |
| `po/<code>.po` | one translator file per language |
| `locale/<code>/LC_MESSAGES/euromillions.mo` | compiled form, built and git-ignored |

The msgids are the English strings, so English needs no catalogue. Build
the others before a non-English run: `tools/build-locales.sh`.

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

`--help` lists the `.po` files found in `po/`. After changing a msgid in
`euromillions.sh`, update the template with:

```console
$ xgettext --language=Shell --keyword=_ --output=po/euromillions.pot euromillions.sh
```

then merge it into each catalogue with `msgmerge -U po/fr.po po/euromillions.pot`.

gettext only loads a translation when a locale is active. The script
replaces a `C` locale with the language's own (`fr_FR.UTF-8` for French),
so the locale must be generated on the system: `sudo locale-gen fr_FR.UTF-8`
on Debian, or `localedef`. When it is missing, the script warns and keeps
English:

```console
$ ./euromillions.sh --lang fr
no translation for fr, using English
Numbers: 4 9 42 45 46
Stars: 1 7
```

---

## Requirements

- Bash 4 or later
- GNU coreutils, for `shuf` and `sort`
- gettext, for a language other than English, plus that language's locale

`shuf` ships with Linux. macOS and FreeBSD provide it through GNU
coreutils, under the name `gshuf`:

```console
$ brew install bash coreutils gettext        # macOS, then use bash 4 or later
$ pkg install bash coreutils gettext         # FreeBSD
$ SHUF=gshuf ./euromillions.sh
```

Without `gettext`, or without the language's catalogue, the output stays
English and a warning names the language. The test suite runs on Linux,
macOS, and FreeBSD in CI.

---

## Supported systems

`metadata.json` follows the OpenVox module metadata format and lists the
supported systems:

| System | Minimum |
| --- | --- |
| Debian | 12 |
| Ubuntu | 24.04 |
| Red Hat Enterprise Linux | 9 |
| CentOS Stream | 9 |
| FreeBSD | 14 |
| macOS (Darwin) | 14 |

`tools/check-metadata.py` validates the file, and CI runs it.

## Tests

The suite needs `bats` and `shellcheck`:

```console
$ bats test test/shell
$ shellcheck euromillions.sh .githooks/commit-msg tools/build-locales.sh
```

The bats suite runs the shellcheck command as one of its cases, so a
missing binary fails the case rather than skipping it. Any finding, at
any severity, is a failure.

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

---

## Demo

The animation at the top is declarative SVG, not a recording and not a
GIF, so every browser plays it inline without a media player.

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

---

## Disclaimer

Not affiliated with EuroMillions or with any lottery operator. It
predicts nothing: every grid has the same odds, and the output is for
entertainment only.

---

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

## Changelog

[`CHANGELOG.md`](CHANGELOG.md) is generated from the git history:

```console
$ python3 tools/changelog.py v0.0.1
```

The release workflow runs the same command for the new tag and uses the
output as the release notes. Commits carrying a Conventional Commits
prefix are grouped; the rest land under "Changes".

## Code scanning

GitHub code scanning shows the shellcheck findings as alerts. ShellCheck has
no SARIF writer, so `tools/shellcheck-sarif.py` converts its JSON output,
and `.github/workflows/tests.yml` uploads the result on every push and pull
request. The alerts are informative; shellcheck still fails the test job on
a finding.

## Releases

Cut a tag to publish the packages:

```console
$ git tag v1.0.0
$ git push origin v1.0.0
```

`.github/workflows/release.yml` builds the `.deb` and the `.rpm`, then
attaches both to the GitHub release. The repository carries `0.0.0` as
the unreleased placeholder; the workflow takes the version from the tag
and injects it into `debian/changelog` and the spec before building.

## Contributing

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

---

## License

[GPL-3.0](LICENSE), or <https://www.gnu.org/licenses/gpl-3.0.html>.
