#!/usr/bin/env bats
#
# Tests for euromillions.sh.
#
# Run with "bats test/euromillions.bats".

SCRIPT="${BATS_TEST_DIRNAME}/../euromillions.sh"

# Ubuntu 22.04 ships an older bats without BATS_TEST_TMPDIR
TEST_TMPDIR=${BATS_TEST_TMPDIR:-$(mktemp -d)}

# The tests must run the script with bash 4 or later, not the system bash
BASH_BIN=${BASH_BIN:-$(command -v bash)}
ROOT=$(cd -- "${BATS_TEST_DIRNAME}/.." && pwd)

# Pin the locale: the default output must be English whatever the host
export LC_ALL=C
export LANG=C

setup_file () {
	# French cases need the compiled catalogue
	"${ROOT}/tools/build-locales.sh" >/dev/null 2>&1 || true
}

# Skip when msgfmt was unavailable and the catalogue is missing
require_translation () {
	[ -f "${ROOT}/locale/fr/LC_MESSAGES/euromillions.mo" ] ||
		skip "the french catalogue is not built"
}

numbers_line () {
	printf '%s\n' "$output" | sed -n 's/^Numbers: //p'
}

stars_line () {
	printf '%s\n' "$output" | sed -n 's/^Stars: //p'
}

# Fail unless the line holds count values, all within lo-hi, ascending
assert_draw () {
	local line=$1
	local count=$2
	local lo=$3
	local hi=$4
	local -a values

	mapfile -t values < <(tr ' ' '\n' <<< "$line")

	[ "${#values[@]}" -eq "$count" ]

	local value
	for value in "${values[@]}"; do
		[ "$value" -ge "$lo" ]
		[ "$value" -le "$hi" ]
	done

	[ "$(printf '%s\n' "${values[@]}" | sort -n | tr '\n' ' ')" = "${line} " ]
}

@test "prints a numbers line and a stars line" {
	run "$SCRIPT"
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 2 ]
	[[ "${lines[0]}" =~ ^Numbers:\ [0-9]+(\ [0-9]+)*$ ]]
	[[ "${lines[1]}" =~ ^Stars:\ [0-9]+(\ [0-9]+)*$ ]]
}

@test "draws five numbers from 1 to 50, ascending and distinct" {
	run "$SCRIPT"
	[ "$status" -eq 0 ]
	assert_draw "$(numbers_line)" 5 1 50
}

@test "draws two stars from 1 to 12, ascending and distinct" {
	run "$SCRIPT"
	[ "$status" -eq 0 ]
	assert_draw "$(stars_line)" 2 1 12
}

@test "repeats the same draw for the same random source" {
	printf 'deterministic entropy for the test run' > "${TEST_TMPDIR}/source"

	run env RANDOM_SOURCE="${TEST_TMPDIR}/source" "$SCRIPT"
	[ "$status" -eq 0 ]
	first=$output

	run env RANDOM_SOURCE="${TEST_TMPDIR}/source" "$SCRIPT"
	[ "$status" -eq 0 ]
	[ "$output" = "$first" ]
}

@test "draws different values for two different random sources" {
	printf 'first source' > "${TEST_TMPDIR}/source-one"
	printf 'second source' > "${TEST_TMPDIR}/source-two"

	run env RANDOM_SOURCE="${TEST_TMPDIR}/source-one" "$SCRIPT"
	first=$output

	run env RANDOM_SOURCE="${TEST_TMPDIR}/source-two" "$SCRIPT"
	[ "$output" != "$first" ]
}

@test "fails and reports the label when shuf is unavailable" {
	run env PATH=/nonexistent "${BASH_BIN}" "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"draw failed: Numbers"* ]]
}

@test "fails when the entropy source does not exist" {
	run env RANDOM_SOURCE="${TEST_TMPDIR}/missing" "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"draw failed: Numbers"* ]]
}

@test "prints french labels with --lang fr" {
	require_translation
	run "$SCRIPT" --lang fr
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 2 ]
	[[ "${lines[0]}" =~ ^Numéros:\ [0-9]+(\ [0-9]+)*$ ]]
	[[ "${lines[1]}" =~ ^Étoiles:\ [0-9]+(\ [0-9]+)*$ ]]
	assert_draw "$(printf '%s\n' "$output" | sed -n 's/^Numéros: //p')" 5 1 50
	assert_draw "$(printf '%s\n' "$output" | sed -n 's/^Étoiles: //p')" 2 1 12
}

@test "accepts the --lang=CODE form" {
	require_translation
	run "$SCRIPT" --lang=fr
	[ "$status" -eq 0 ]
	[[ "$output" == Numéros:* ]]
}

@test "reads the language from EUROMILLIONS_LANG" {
	require_translation
	run env EUROMILLIONS_LANG=fr "$SCRIPT"
	[ "$status" -eq 0 ]
	[[ "$output" == Numéros:* ]]
}

@test "detects the language from the locale" {
	require_translation
	run env -u LC_ALL -u EUROMILLIONS_LANG LANG=fr_FR.UTF-8 "$SCRIPT"
	[ "$status" -eq 0 ]
	[[ "$output" == Numéros:* ]]
}

@test "prefers --lang over the environment" {
	run env EUROMILLIONS_LANG=fr "$SCRIPT" --lang en
	[ "$status" -eq 0 ]
	[[ "$output" == Numbers:* ]]
}

@test "falls back to english for an unknown language" {
	run "$SCRIPT" --lang de
	[ "$status" -eq 0 ]
	[[ "$output" == *"no translation for de"* ]]
	[[ "$output" == *"Numbers:"* ]]
}

@test "translates the error messages" {
	require_translation
	run env RANDOM_SOURCE="${TEST_TMPDIR}/missing" EUROMILLIONS_LANG=fr "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"tirage impossible: Numéros"* ]]
}

@test "lists every option in the usage line" {
	run "$SCRIPT" --help
	[ "$status" -eq 0 ]
	[[ "${lines[0]}" == *"[--lang CODE]"* ]]
	[[ "${lines[0]}" == *"[--no-color]"* ]]
	[[ "${lines[0]}" == *"[-h | --help]"* ]]
}

@test "lists the languages in --help" {
	run "$SCRIPT" --help
	[ "$status" -eq 0 ]
	[[ "$output" == *"Languages: en fr"* ]]
}

@test "translates the help with a --lang that follows -h" {
	require_translation
	run "$SCRIPT" -h -l fr
	[ "$status" -eq 0 ]
	[[ "$output" == *"Utilisation :"* ]]
	[[ "$output" == *"Langues : en fr"* ]]
}

@test "translates the help with a --lang that precedes -h" {
	require_translation
	run "$SCRIPT" --lang fr --help
	[ "$status" -eq 0 ]
	[[ "$output" == *"Utilisation :"* ]]
}

@test "translates the argument errors" {
	require_translation
	run "$SCRIPT" --lang fr --nope
	[ "$status" -eq 2 ]
	[[ "$output" == *"argument inconnu : --nope"* ]]
}

@test "rejects --lang without a code" {
	run "$SCRIPT" --lang
	[ "$status" -eq 2 ]
	[[ "$output" == *"needs a language code"* ]]
}

@test "rejects an unknown argument" {
	run "$SCRIPT" --nope
	[ "$status" -eq 2 ]
	[[ "$output" == *"unknown argument: --nope"* ]]
}

@test "writes plain output on a pipe by default" {
	run "$SCRIPT"
	[ "$status" -eq 0 ]
	[[ "$output" != *$'\e['* ]]
}

@test "emits 256-colour escapes when forced" {
	run env -u COLORTERM EUROMILLIONS_COLOR=always "$SCRIPT"
	[ "$status" -eq 0 ]
	[[ "$output" == *$'\e[38;5;247mNumbers:'* ]]
	[[ "$output" == *$'\e[1;38;5;69m'* ]]
	[[ "$output" == *$'\e[1;38;5;220m'* ]]
}

@test "honours EUROMILLIONS_COLOR=never" {
	run env EUROMILLIONS_COLOR=never "$SCRIPT"
	[ "$status" -eq 0 ]
	[[ "$output" != *$'\e['* ]]
}

@test "lets --no-color win over the environment" {
	run env EUROMILLIONS_COLOR=always "$SCRIPT" --no-color
	[ "$status" -eq 0 ]
	[[ "$output" != *$'\e['* ]]
}

@test "prefers truecolor escapes when COLORTERM allows them" {
	run env COLORTERM=truecolor EUROMILLIONS_COLOR=always "$SCRIPT"
	[ "$status" -eq 0 ]
	[[ "$output" == *$'\e[1;38;2;77;107;255m'* ]]
	[[ "$output" == *$'\e[1;38;2;238;187;5m'* ]]
}

@test "colours the error messages" {
	run env PATH=/nonexistent EUROMILLIONS_COLOR=always "${BASH_BIN}" "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *$'\e[1;38;5;203mdraw failed: Numbers'* ]]
}

@test "rejects an invalid colour mode" {
	run env EUROMILLIONS_COLOR=sometimes "$SCRIPT"
	[ "$status" -eq 2 ]
	[[ "$output" == *"invalid EUROMILLIONS_COLOR: sometimes"* ]]
}

@test "reads the grid shape from the environment" {
	run env COUNTNUMBERS=3 NUMBERSDOWN=2 NUMBERSUP=10 \
		COUNTSTARS=1 STARSDOWN=0 STARSUP=4 "$SCRIPT"
	[ "$status" -eq 0 ]
	assert_draw "$(numbers_line)" 3 2 10
	assert_draw "$(stars_line)" 1 0 4
}

@test "warns when the requested language has no catalogue" {
	cp "$SCRIPT" "${TEST_TMPDIR}/euromillions.sh"
	run "${BASH_BIN}" "${TEST_TMPDIR}/euromillions.sh" --lang fr
	[ "$status" -eq 0 ]
	[[ "$output" == *"no translation for fr, using English"* ]]
	[[ "$output" == *"Numbers:"* ]]
}

@test "stays quiet when the catalogue works" {
	require_translation
	run env EUROMILLIONS_LANG=fr "$SCRIPT"
	[ "$status" -eq 0 ]
	[[ "$output" != *"no translation"* ]]
	[[ "$output" == *"Numéros:"* ]]
}

@test "finds the data under share when packaged" {
	mkdir -p "${TEST_TMPDIR}/bin" "${TEST_TMPDIR}/share/euromillions/po"
	cp "$SCRIPT" "${TEST_TMPDIR}/bin/euromillions.sh"
	cp "${ROOT}"/po/*.po "${TEST_TMPDIR}/share/euromillions/po/"

	run "${BASH_BIN}" "${TEST_TMPDIR}/bin/euromillions.sh" --help
	[ "$status" -eq 0 ]
	[[ "$output" == *"Languages: en fr"* ]]
}

@test "honours EUROMILLIONS_DATADIR" {
	require_translation
	run env EUROMILLIONS_DATADIR="$ROOT" "$SCRIPT" --lang fr
	[ "$status" -eq 0 ]
	[[ "$output" == *"Numéros:"* ]]
}

@test "honours SHUF for a system without GNU shuf" {
	run env SHUF=/nonexistent "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"draw failed: Numbers"* ]]
}

# A mailer that records its arguments and message
make_mailer () {
	cat > "$BATS_TEST_TMPDIR/mailer" <<'EOF'
#!/bin/sh
{
	echo "ARGS: $*"
	cat
} > "$BATS_TEST_TMPDIR/mail.out"
EOF
	chmod +x "$BATS_TEST_TMPDIR/mailer"
	rm -f "$BATS_TEST_TMPDIR/mail.out"
}

@test "mails the jackpot on Friday by default" {
	make_mailer
	run env ALERT_TODAY=5 ALERT_TO=me@example.org \
		ALERT_MAILER="$BATS_TEST_TMPDIR/mailer" JACKPOT=150000000 "$SCRIPT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"possible gain next time: 150000000"* ]]
	[ -f "$BATS_TEST_TMPDIR/mail.out" ]
	grep -q 'possible gain next time: 150000000' "$BATS_TEST_TMPDIR/mail.out"
}

@test "stays quiet on Tuesday by default" {
	make_mailer
	run env ALERT_TODAY=2 ALERT_TO=me@example.org \
		ALERT_MAILER="$BATS_TEST_TMPDIR/mailer" JACKPOT=150000000 "$SCRIPT"
	[ "$status" -eq 0 ]
	[ ! -f "$BATS_TEST_TMPDIR/mail.out" ]
	[[ "$output" != *"possible gain"* ]]
}

@test "mails on Tuesday when both days are configured" {
	make_mailer
	run env ALERT_DAYS=tue,fri ALERT_TODAY=2 ALERT_TO=me@example.org \
		ALERT_MAILER="$BATS_TEST_TMPDIR/mailer" JACKPOT=150000000 "$SCRIPT"
	[ "$status" -eq 0 ]
	[ -f "$BATS_TEST_TMPDIR/mail.out" ]
}

@test "does not mail below the threshold" {
	make_mailer
	run env ALERT_TODAY=5 ALERT_TO=me@example.org \
		ALERT_MAILER="$BATS_TEST_TMPDIR/mailer" JACKPOT=99999999 "$SCRIPT"
	[ "$status" -eq 0 ]
	[ ! -f "$BATS_TEST_TMPDIR/mail.out" ]
}

@test "mails at exactly the threshold" {
	make_mailer
	run env ALERT_TODAY=5 ALERT_TO=me@example.org \
		ALERT_MAILER="$BATS_TEST_TMPDIR/mailer" JACKPOT=100000000 "$SCRIPT"
	[ "$status" -eq 0 ]
	[ -f "$BATS_TEST_TMPDIR/mail.out" ]
}

@test "reads the jackpot from the option" {
	make_mailer
	run env ALERT_TODAY=5 ALERT_TO=me@example.org \
		ALERT_MAILER="$BATS_TEST_TMPDIR/mailer" "$SCRIPT" --jackpot=150000000
	[ "$status" -eq 0 ]
	[ -f "$BATS_TEST_TMPDIR/mail.out" ]
}

@test "warns when no recipient is set" {
	run env ALERT_TODAY=5 JACKPOT=150000000 "$SCRIPT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"ALERT_TO is not set"* ]]
}

@test "rejects an invalid alert day" {
	run env ALERT_DAYS=mon JACKPOT=150000000 "$SCRIPT"
	[ "$status" -eq 2 ]
	[[ "$output" == *"ALERT_DAYS"* ]]
}

@test "rejects an invalid jackpot" {
	run "$SCRIPT" --jackpot=abc
	[ "$status" -eq 2 ]
	[[ "$output" == *"jackpot"* ]]
}

@test "passes shellcheck" {
	if ! command -v shellcheck >/dev/null; then
		printf 'shellcheck is required\n' >&2
		false
	fi
	root=$(cd -- "${BATS_TEST_DIRNAME}/.." && pwd)
	run shellcheck "$root/euromillions.sh" "$root/.githooks/commit-msg" "$root/tools/build-locales.sh"
	[ "$status" -eq 0 ]
}
