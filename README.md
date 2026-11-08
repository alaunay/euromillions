# euromillions

Shell script to draw random Euromillions numbers and stars.

## Usage

```
./euromillions.sh [--lang CODE]
```

Draws 5 numbers from 1 to 50 and 2 stars from 1 to 12, sorted.

```
$ ./euromillions.sh
Numbers: 3 8 11 20 41
Stars: 7 8
```

## Languages

Output is available in English (`en`) and French (`fr`).

```
$ ./euromillions.sh --lang fr
Numéros: 2 9 17 36 44
Étoiles: 3 11
```

The language is taken from, in order: `--lang`, `EUROMILLIONS_LANG`, the
locale (`fr_FR.UTF-8` selects French), then English. An unknown language
falls back to English.

Adding a language means copying `lang/en.sh` to `lang/xx.sh` and
translating the values.

## Tests

The suite uses [bats](https://github.com/bats-core/bats-core):

```
bats test/euromillions.bats
```

GitHub Actions runs it on every push to `master` and on every pull
request.

## Possible ameliorations

- more languages
