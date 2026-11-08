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
$ ./euromillions.sh [-l CODE | --lang CODE] [-h | --help]
```

| Option | Effect |
| --- | --- |
| `-l, --lang CODE` | Set the output language, overriding the locale |
| `-h, --help` | Show the options and the available languages |

Draws are independent, uniform, and read from `/dev/urandom`. Every run
gives a new grid.

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

`shuf` ships with Linux. It is absent from macOS, where coreutils must be
installed separately.

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
