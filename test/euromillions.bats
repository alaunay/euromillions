#!/usr/bin/env bats
#
# Tests for euromillions.sh.
#
# Run with "bats test/euromillions.bats".

SCRIPT="${BATS_TEST_DIRNAME}/../euromillions.sh"

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
