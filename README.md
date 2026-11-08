# euromillions

Bash script to draw random Euromillions numbers and stars.

## Requirements

- bash 4 or later
- GNU coreutils, for `shuf` and `sort`

`shuf` is part of GNU coreutils. It ships with Linux and is absent from
macOS, where coreutils must be installed separately.

## Usage

```
./euromillions.sh [-l CODE | --lang CODE] [-h | --help]
```

Draws 5 numbers from 1 to 50 and 2 stars from 1 to 12. The values are
distinct and printed in ascending order.

```
$ ./euromillions.sh
Numbers: 3 8 11 20 41
Stars: 7 8
```

`-h` prints the options and the list of available languages.

## Languages

Output is translated through catalogues in `lang/`, one file per
language. English (`en`) and French (`fr`) are provided.

```
$ ./euromillions.sh --lang fr
Numéros: 2 9 17 36 44
Étoiles: 3 11
```

The language is taken from, in order: `--lang`, `EUROMILLIONS_LANG`, the
locale (`fr_FR.UTF-8` selects French), then English. An unknown language
falls back to English.

To add a language, copy `lang/en.sh` to `lang/xx.sh`, translate the
values, and extend the test suite. `--help` lists the catalogues found
in `lang/`.

## Tests

The suite uses [bats](https://github.com/bats-core/bats-core):

```
bats test/euromillions.bats
```

GitHub Actions runs it on every push to `master` and on every pull
request, in `.github/workflows/tests.yml`.

## Limitations

- Only English and French are translated.
- The output is plain text on stdout. There is no structured or
  machine-readable format.

## Disclaimer

The script is not affiliated with EuroMillions or with any lottery
operator. It predicts nothing: every draw has the same odds, and the
output is for entertainment only.

## License

GPL-3.0, see [LICENSE](LICENSE) or
<https://www.gnu.org/licenses/gpl-3.0.html>.
