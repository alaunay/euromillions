#! /bin/bash

set -euo pipefail

COUNTNUMBERS=5
NUMBERSUP=50
NUMBERSDOWN=1
COUNTSTARS=2
STARSUP=12
STARSDOWN=1

# Draw and print count distinct values from lo to hi, sorted
draw () {
	local label=$1
	local count=$2
	local lo=$3
	local hi=$4
	local output
	local -a draws

	# Keep the pipeline status: process substitution would hide a failure
	if ! output=$(shuf --random-source=/dev/urandom -i "${lo}-${hi}" -n "${count}" | sort -n); then
		echo "draw failed: ${label}" >&2
		exit 1
	fi

	mapfile -t draws <<< "${output}"

	if (( ${#draws[@]} != count )); then
		echo "short draw: ${label} (${#draws[@]}/${count})" >&2
		exit 1
	fi

	echo "${label}: ${draws[*]}"
}

# Start functions
draw Numbers "${COUNTNUMBERS}" "${NUMBERSDOWN}" "${NUMBERSUP}"
draw Stars "${COUNTSTARS}" "${STARSDOWN}" "${STARSUP}"
