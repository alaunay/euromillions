<div align="center">

# euromillions

**Five numbers, two stars, straight from your terminal.**

[![tests](https://github.com/alaunay/euromillions/actions/workflows/tests.yml/badge.svg)](https://github.com/alaunay/euromillions/actions/workflows/tests.yml)
[![license](https://img.shields.io/github/license/alaunay/euromillions?style=flat-square)](LICENSE)
[![bash 4+](https://img.shields.io/badge/bash-4%2B-1f425f?style=flat-square&logo=gnubash&logoColor=white)](#requirements)

<img src="assets/demo.svg" alt="Animated terminal session: ./euromillions.sh prints Numbers and Stars, then the same draw in French" width="720">

</div>

A small Bash script that draws a Euromillions grid: five distinct numbers
from 1 to 50 and two distinct stars from 1 to 12, sorted. No network, no
config file, no build step.

## Quick start

```console
$ git clone https://github.com/alaunay/euromillions.git
$ cd euromillions
$ ./euromillions.sh
Numbers: 4 8 13 36 46
Stars: 3 12
```

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
gives a new grid. Labels are muted, numbers in the EuroMillions blue and stars in the
EuroMillions gold, as on the FDJ grid.

Colours are used only when the output goes to a terminal. `NO_COLOR`
disables them, `--no-color` forces them off, and `EUROMILLIONS_COLOR`
accepts `auto`, `always`, or `never` for scripts and pipes.

The palette is 24-bit when `COLORTERM` says `truecolor` or `24bit`, and
falls back to 256-colour codes otherwise, so the hues match the demo.

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

Translations live in `lang/`, one file per language:

```console
$ cp lang/en.sh lang/de.sh
$ EUROMILLIONS_LANG=de ./euromillions.sh   # after translating the values
```

`--help` lists whatever catalogues `lang/` contains. Extend the test
suite when you add one.

## Requirements

- Bash 4 or later
- GNU coreutils, for `shuf` and `sort`
- gettext, for a language other than English, plus that language's locale

`shuf` ships with Linux. It is absent from macOS, where coreutils must be
installed separately. Without `gettext`, or without the language's
catalogue, the output stays English and a warning names the language.

## Tests

```console
$ bats test/euromillions.bats
```

The suite covers the output shape, the ranges, the order, the language
resolution, and the failure paths. GitHub Actions runs it on every push
to `master` and on every pull request, in
[`.github/workflows/tests.yml`](.github/workflows/tests.yml).

The animation above is declarative SVG, not a recording and not a GIF,
so every browser plays it inline without a media player:

```console
$ python3 tools/make-demo.py
```

`RANDOM_SOURCE` points `shuf` at another entropy file, which makes a draw
reproducible.

## Disclaimer

Not affiliated with EuroMillions or with any lottery operator. It
predicts nothing: every grid has the same odds, and the output is for
entertainment only.

## License

[GPL-3.0](LICENSE), or <https://www.gnu.org/licenses/gpl-3.0.html>.
