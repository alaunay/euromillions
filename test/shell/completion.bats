#!/usr/bin/env bats
#
# Tests for completions/euromillions.bash.

setup() {
	ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
	SCRIPT="${ROOT}/euromillions.sh"

	source "${ROOT}/completions/euromillions.bash"
}

# Run the completion function and print one candidate per line
complete_words () {
	COMP_WORDS=("$@")
	COMP_CWORD=$((${#COMP_WORDS[@]} - 1))
	_euromillions
	printf '%s\n' "${COMPREPLY[@]}"
}

@test "completes the long options" {
	run complete_words "$SCRIPT" "--"
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 5 ]
	[ "${lines[0]}" = --lang ]
	[ "${lines[1]}" = --cron ]
	[ "${lines[2]}" = --threshold ]
	[ "${lines[3]}" = --no-color ]
	[ "${lines[4]}" = --help ]
}

@test "completes a short option from its prefix" {
	run complete_words "$SCRIPT" "-h"
	[ "$status" -eq 0 ]
	[ "$output" = -h ]
}

@test "completes every language code after --lang" {
	run complete_words "$SCRIPT" --lang ""
	[ "$status" -eq 0 ]
	[ "${#lines[@]}" -eq 2 ]
	[ "${lines[0]}" = en ]
	[ "${lines[1]}" = fr ]
}

@test "completes one language code from a prefix" {
	run complete_words "$SCRIPT" -l f
	[ "$status" -eq 0 ]
	[ "$output" = fr ]
}

@test "completes --lang= with the code prefix" {
	run complete_words "$SCRIPT" "--lang=f"
	[ "$status" -eq 0 ]
	[ "$output" = "--lang=fr" ]
}

@test "offers nothing for an unknown option" {
	run complete_words "$SCRIPT" "--nope"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}
