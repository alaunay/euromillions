#! /bin/bash

set -euo pipefail

source_path=${BASH_SOURCE[0]}
if command -v readlink >/dev/null 2>&1; then
	source_path=$(readlink -f -- "$source_path")
fi

SCRIPT_DIR=${source_path%/*}
if [ "$SCRIPT_DIR" = "$source_path" ]; then
	SCRIPT_DIR=.
fi
SCRIPT_DIR=$(cd -- "$SCRIPT_DIR" && pwd)

COUNTNUMBERS=5
NUMBERSUP=50
NUMBERSDOWN=1
COUNTSTARS=2
STARSUP=12
STARSDOWN=1

# Entropy source for shuf, overridable to get a reproducible draw
RANDOM_SOURCE=${RANDOM_SOURCE:-/dev/urandom}

# Build the language list from the available catalogue files
languages () {
	local file code list=

	for file in "${SCRIPT_DIR}"/lang/*.sh; do
		code=${file##*/}
		list+="${code%.sh} "
	done

	printf '%s\n' "${list% }"
}

usage () {
	cat <<EOF
Usage: ${0##*/} [--lang CODE]

Draw ${COUNTNUMBERS} numbers from ${NUMBERSDOWN} to ${NUMBERSUP} and ${COUNTSTARS} stars from ${STARSDOWN} to ${STARSUP}.

Options:
  -l, --lang CODE  output language, overriding the locale
  -h, --help       show this help

Languages: $(languages)
EOF
}

# Language from EUROMILLIONS_LANG, then the locale, then English
detect_language () {
	local code=${EUROMILLIONS_LANG:-${LC_ALL:-${LANG:-}}}
	code=${code%%.*}
	code=${code%%_*}
	printf '%s' "${code:-en}"
}

# Load the catalogue for code, falling back to English
load_language () {
	local code=$1
	local file="${SCRIPT_DIR}/lang/${code}.sh"

	if [ ! -r "$file" ]; then
		file="${SCRIPT_DIR}/lang/en.sh"
	fi

	if [ ! -r "$file" ]; then
		echo "no language catalogue in ${SCRIPT_DIR}/lang" >&2
		exit 1
	fi

	# shellcheck source=/dev/null
	. "$file"
}

# Draw and print count distinct values from lo to hi, sorted
draw () {
	local label=$1
	local count=$2
	local lo=$3
	local hi=$4
	local output
	local -a draws

	# Keep the pipeline status: process substitution would hide a failure
	if ! output=$(shuf --random-source="${RANDOM_SOURCE}" -i "${lo}-${hi}" -n "${count}" | sort -n); then
		echo "${MSG_DRAW_FAILED}: ${label}" >&2
		exit 1
	fi

	mapfile -t draws <<< "${output}"

	if (( ${#draws[@]} != count )); then
		echo "${MSG_SHORT_DRAW}: ${label} (${#draws[@]}/${count})" >&2
		exit 1
	fi

	echo "${label}: ${draws[*]}"
}

language=$(detect_language)

while (( $# )); do
	case $1 in
		-l|--lang)
			if (( $# < 2 )); then
				echo "option $1 needs a language code" >&2
				exit 2
			fi
			language=$2
			shift 2
			;;
		--lang=*)
			language=${1#*=}
			shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			echo "unknown argument: $1" >&2
			usage >&2
			exit 2
			;;
	esac
done

load_language "$language"

# Start functions
draw "${MSG_NUMBERS}" "${COUNTNUMBERS}" "${NUMBERSDOWN}" "${NUMBERSUP}"
draw "${MSG_STARS}" "${COUNTSTARS}" "${STARSDOWN}" "${STARSUP}"
