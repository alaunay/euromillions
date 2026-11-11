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

- [Install](#install)
- [Usage](#usage)
- [Configuration](#configuration)
- [Languages](#languages)
- [Requirements](#requirements)
- [Supported systems](#supported-systems)
- [Changelog](#changelog)
- [Disclaimer](#disclaimer)
- [Licence](#licence)

---

## Install

### From source

```console
$ git clone https://github.com/alaunay/euromillions.git
$ cd euromillions
$ ./euromillions.sh
Numbers: 4 8 13 36 46
Stars: 3 12
```

The script needs nothing built. See [Requirements](#requirements) for the
few tools it expects.

### Debian and Ubuntu

Packages are served by the shared
[packages](https://github.com/alaunay/packages) repository:

Verify the key fingerprint before trusting it:

```console
$ curl -fsSL https://alaunay.github.io/packages/keys/repo.asc | gpg --show-keys
```

The fingerprint must be `AA80 3A55 011F D4B6 4A04 A025 FB14 F7F4 D9F9 15F6`.

```console
$ curl -fsSL https://alaunay.github.io/packages/keys/repo.asc \
    | sudo gpg --dearmor -o /usr/share/keyrings/alaunay.gpg
$ echo "deb [signed-by=/usr/share/keyrings/alaunay.gpg] \
https://alaunay.github.io/packages/deb stable main" \
    | sudo tee /etc/apt/sources.list.d/alaunay.list
$ sudo apt update && sudo apt install euromillions
```

### CentOS and RHEL

```console
$ sudo curl -fsSL -o /etc/yum.repos.d/alaunay.repo \
    https://alaunay.github.io/packages/alaunay.repo
$ sudo dnf install euromillions
```

---

## Usage

```console
$ ./euromillions.sh [--cron | --threshold] [-l CODE | --lang CODE] [--no-color] [-h | --help]
```

| Option | Effect |
| --- | --- |
| `--cron` | Mail the next jackpot when it reaches the threshold, draw nothing |
| `--threshold` | Print the alert threshold and exit |
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

There is no configuration file. Every setting is an environment variable
or a command-line option, and the script reads the environment once at
start-up. Variables not listed here have no effect.

### Grid

The EuroMillions grid is the default:

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

### Jackpot alert

| Variable | Default | Meaning |
| --- | --- | --- |
| `ALERT_THRESHOLD` | `100000000` | mail only at or above this amount, in euro |
| `ALERT_TO` | unset | recipient; `--cron` exits 1 without it |
| `ALERT_MAILER` | auto | `sendmail`, `msmtp`, `mail`, or a path; auto-detected |
| `JACKPOT_URL` | FDJ endpoint | where to read the estimated jackpot |
| `CURL` | `curl` | HTTP client used to read the jackpot |

These variables apply to `--cron` and `--threshold`. A plain run ignores
them and never touches the network.

### Output and runtime

| Variable | Default | Meaning |
| --- | --- | --- |
| `EUROMILLIONS_LANG` | locale | output language, overridden by `--lang` |
| `EUROMILLIONS_COLOR` | `auto` | `auto`, `always`, or `never` |
| `EUROMILLIONS_DATADIR` | script directory | where `po/` and `locale/` live |
| `SHUF` | `shuf` | shuffle binary, `gshuf` on macOS and FreeBSD |
| `RANDOM_SOURCE` | `/dev/urandom` | entropy source for `shuf` |
| `NO_COLOR` | unset | any value disables colours |

---

## Jackpot alerts

Without `--cron`, the script only draws a grid: it opens no network
connection and prints no gain.

`--cron` asks the FDJ draw information endpoint for the estimated jackpot
of the next draw. It mails an alert when the jackpot reaches the
threshold, and does nothing otherwise:

```console
$ ALERT_TO=me@example.org ./euromillions.sh --cron
$ ALERT_THRESHOLD=10000000 ALERT_TO=me@example.org ./euromillions.sh --cron
$ mail -s 'Euromillions: next draw 17 M€' me@example.org
next draw: 17 M€
```

Amounts use SI prefixes and round to the unit: `17 M€`, `100 M€`,
`1 G€`. `--threshold` prints the configured value:

```console
$ ./euromillions.sh --threshold
100 M€
```

A cron entry every Wednesday at 11:00:

```cron
0 11 * * 3 ALERT_TO=me@example.org /usr/bin/euromillions --cron
```

Set `PATH` in the crontab when `sendmail` or `curl` lives outside cron's
default path. All variables are listed in
[Configuration](#configuration).

It needs `curl` and network access. The endpoint is FDJ's public draw
information service, not an official API; `JACKPOT_URL` overrides it.

The message goes through `sendmail -t` when the binary is `sendmail` or
`msmtp`, and through `mail -s` otherwise. Below the threshold, `--cron`
exits 0 and prints nothing. An unreachable endpoint, an invalid response,
a missing recipient, or a failed mailer exits 1 with a message on stderr,
so cron reports the failure.

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

Translation work, including adding a language, is described in
[CONTRIBUTING.md](CONTRIBUTING.md#translations).

---

## Requirements

- Bash 4 or later
- GNU coreutils, for `shuf` and `sort`
- gettext, for a language other than English, plus that language's locale
- curl, for the jackpot alert

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

---

## Changelog

[`CHANGELOG.md`](CHANGELOG.md) lists the changes of each tag. The release
workflow generates the release notes from the same source.

---

## Disclaimer

Not affiliated with EuroMillions or with any lottery operator. It
predicts nothing: every grid has the same odds, and the output is for
entertainment only.

---

## Licence

[GPL-3.0](LICENSE), or <https://www.gnu.org/licenses/gpl-3.0.html>.

Development, tests, packaging, and releases: see
[CONTRIBUTING.md](CONTRIBUTING.md).
