#!/usr/bin/env bats
#
# Tests for euromillions.sh.
#
# Run with "bats test/euromillions.bats".

SCRIPT="${BATS_TEST_DIRNAME}/../euromillions.sh"

# Pin the locale: the default output must be English whatever the host
export LC_ALL=C
export LANG=C

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
	printf 'deterministic entropy for the test run' > "${BATS_TEST_TMPDIR}/source"

	run env RANDOM_SOURCE="${BATS_TEST_TMPDIR}/source" "$SCRIPT"
	[ "$status" -eq 0 ]
	first=$output

	run env RANDOM_SOURCE="${BATS_TEST_TMPDIR}/source" "$SCRIPT"
	[ "$status" -eq 0 ]
	[ "$output" = "$first" ]
}

@test "draws different values for two different random sources" {
	printf 'first source' > "${BATS_TEST_TMPDIR}/source-one"
	printf 'second source' > "${BATS_TEST_TMPDIR}/source-two"

	run env RANDOM_SOURCE="${BATS_TEST_TMPDIR}/source-one" "$SCRIPT"
	first=$output

	run env RANDOM_SOURCE="${BATS_TEST_TMPDIR}/source-two" "$SCRIPT"
	[ "$output" != "$first" ]
}

@test "fails and reports the label when shuf is unavailable" {
	run env PATH=/nonexistent /bin/bash "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"draw failed: Numbers"* ]]
}

@test "fails when the entropy source does not exist" {
	run env RANDOM_SOURCE="${BATS_TEST_TMPDIR}/missing" "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"draw failed: Numbers"* ]]
}

@test "prints french labels with --lang fr" {
	run "$SCRIPT" --lang fr
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 2 ]
	[[ "${lines[0]}" =~ ^Numéros:\ [0-9]+(\ [0-9]+)*$ ]]
	[[ "${lines[1]}" =~ ^Étoiles:\ [0-9]+(\ [0-9]+)*$ ]]
	assert_draw "$(printf '%s\n' "$output" | sed -n 's/^Numéros: //p')" 5 1 50
	assert_draw "$(printf '%s\n' "$output" | sed -n 's/^Étoiles: //p')" 2 1 12
}

@test "accepts the --lang=CODE form" {
	run "$SCRIPT" --lang=fr
	[ "$status" -eq 0 ]
	[[ "$output" == Numéros:* ]]
}

@test "reads the language from EUROMILLIONS_LANG" {
	run env EUROMILLIONS_LANG=fr "$SCRIPT"
	[ "$status" -eq 0 ]
	[[ "$output" == Numéros:* ]]
}

@test "detects the language from the locale" {
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
	[[ "$output" == Numbers:* ]]
}

@test "translates the error messages" {
	run env PATH=/nonexistent EUROMILLIONS_LANG=fr /bin/bash "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"tirage impossible: Numéros"* ]]
}

@test "lists the languages in --help" {
	run "$SCRIPT" --help
	[ "$status" -eq 0 ]
	[[ "$output" == *"Languages: en fr"* ]]
}

@test "translates the help with a --lang that follows -h" {
	run "$SCRIPT" -h -l fr
	[ "$status" -eq 0 ]
	[[ "$output" == *"Utilisation :"* ]]
	[[ "$output" == *"Langues : en fr"* ]]
}

@test "translates the help with a --lang that precedes -h" {
	run "$SCRIPT" --lang fr --help
	[ "$status" -eq 0 ]
	[[ "$output" == *"Utilisation :"* ]]
}

@test "translates the argument errors" {
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
	run env PATH=/nonexistent EUROMILLIONS_COLOR=always /bin/bash "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *$'\e[1;38;5;203mdraw failed: Numbers'* ]]
}

@test "rejects an invalid colour mode" {
	run env EUROMILLIONS_COLOR=sometimes "$SCRIPT"
	[ "$status" -eq 2 ]
	[[ "$output" == *"invalid EUROMILLIONS_COLOR: sometimes"* ]]
}

@test "passes shellcheck" {
	command -v shellcheck >/dev/null || skip "shellcheck is not installed"
	root=$(cd -- "${BATS_TEST_DIRNAME}/.." && pwd)
	run shellcheck "$root/euromillions.sh" "$root/.githooks/commit-msg" "$root"/lang/*.sh
	[ "$status" -eq 0 ]
}
