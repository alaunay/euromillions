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

# auto, always, or never; see use_color
COLOR_MODE=${EUROMILLIONS_COLOR:-auto}

# Colour is off on a pipe, with NO_COLOR set, or on a dumb terminal
use_color () {
	local fd=$1

	case "$COLOR_MODE" in
		always) return 0 ;;
		never) return 1 ;;
		auto) ;;
		*)
			echo "invalid EUROMILLIONS_COLOR: ${COLOR_MODE}" >&2
			exit 2
			;;
	esac

	[ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != dumb ] && [ -t "$fd" ]
}

truecolor () {
	case "${COLORTERM:-}" in
		truecolor|24bit) return 0 ;;
	esac
	return 1
}

# Palette, each entry named by its nearest standard colour:
#   labels  grey   24-bit 154;164;178, 256-colour 247
#   numbers blue   24-bit  77;107;255, 256-colour  69 (EuroMillions navy, brightened)
#   stars   gold   24-bit 238;187;  5, 256-colour 220 (EuroMillions gold)
#   errors  red    24-bit 255; 77; 77, 256-colour 203
# The leading 1 asks for bold, which most themes render as a brighter shade.
setup_colors () {
	RESET=
	LABEL_COLOR=
	NUMBERS_COLOR=
	STARS_COLOR=
	ERROR_COLOR=
	ERROR_RESET=

	if use_color 1; then
		RESET=$'\033[0m'
		if truecolor; then
			LABEL_COLOR=$'\033[38;2;154;164;178m'   # grey
			NUMBERS_COLOR=$'\033[1;38;2;77;107;255m' # bold blue
			STARS_COLOR=$'\033[1;38;2;238;187;5m'    # bold gold
		else
			LABEL_COLOR=$'\033[38;5;247m'   # grey
			NUMBERS_COLOR=$'\033[1;38;5;69m'  # bold blue
			STARS_COLOR=$'\033[1;38;5;220m'   # bold gold
		fi
	fi

	if use_color 2; then
		ERROR_RESET=$'\033[0m'
		if truecolor; then
			ERROR_COLOR=$'\033[1;38;2;255;77;77m' # bold red
		else
			ERROR_COLOR=$'\033[1;38;5;203m' # bold red
		fi
	fi
}

# Build the language list from the available catalogue files
languages () {
	local file code list=

	for file in "${SCRIPT_DIR}"/lang/*.sh; do
		code=${file##*/}
		list+="${code%.sh} "
	done

	printf '%s\n' "${list% }"
}

# Fill the %s placeholders of a message, in order
format_message () {
	local message=$1
	shift
	local arg

	for arg in "$@"; do
		message=${message/\%s/${arg}}
	done

	printf '%s' "${message}"
}

usage () {
	printf '%s %s [--lang CODE] [--no-color]\n\n' "${MSG_USAGE}" "${0##*/}"
	printf '%s\n\n' "$(format_message "${MSG_DRAW_SUMMARY}" \
		"${COUNTNUMBERS}" "${NUMBERSDOWN}" "${NUMBERSUP}" \
		"${COUNTSTARS}" "${STARSDOWN}" "${STARSUP}")"
	printf '%s\n' "${MSG_OPTIONS}" "${MSG_OPT_LANG}" "${MSG_OPT_NO_COLOR}" "${MSG_OPT_HELP}"
	printf '\n%s %s\n' "${MSG_LANGUAGES}" "$(languages)"
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
		printf '%sno language catalogue in %s/lang%s\n' \
			"${ERROR_COLOR}" "${SCRIPT_DIR}" "${ERROR_RESET}" >&2
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
	local value_color=$5
	local output
	local -a draws

	# Keep the pipeline status: process substitution would hide a failure
	if ! output=$(shuf --random-source="${RANDOM_SOURCE}" -i "${lo}-${hi}" -n "${count}" | sort -n); then
		printf '%s%s: %s%s\n' "${ERROR_COLOR}" "${MSG_DRAW_FAILED}" "${label}" "${ERROR_RESET}" >&2
		exit 1
	fi

	mapfile -t draws <<< "${output}"

	if (( ${#draws[@]} != count )); then
		printf '%s%s: %s (%s/%s)%s\n' "${ERROR_COLOR}" "${MSG_SHORT_DRAW}" "${label}" \
			"${#draws[@]}" "${count}" "${ERROR_RESET}" >&2
		exit 1
	fi

	printf '%s%s:%s %s%s%s\n' "${LABEL_COLOR}" "${label}" "${RESET}" \
		"${value_color}" "${draws[*]}" "${RESET}"
}

language=$(detect_language)
show_help=0
error_kind=
error_arg=

# Parse everything first: --help must honour a --lang that follows it
while (( $# )); do
	case $1 in
		-l|--lang)
			if (( $# < 2 )); then
				error_kind=needs_code
				error_arg=$1
				break
			fi
			language=$2
			shift 2
			;;
		--lang=*)
			language=${1#*=}
			shift
			;;
		--no-color)
			COLOR_MODE=never
			shift
			;;
		-h|--help)
			show_help=1
			shift
			;;
		*)
			error_kind=unknown
			error_arg=$1
			break
			;;
	esac
done

setup_colors
load_language "$language"

if [ "$error_kind" = needs_code ]; then
	printf '%s%s%s\n' "${ERROR_COLOR}" \
		"$(format_message "${MSG_LANG_NEEDS_CODE}" "${error_arg}")" "${ERROR_RESET}" >&2
	usage >&2
	exit 2
fi

if [ "$error_kind" = unknown ]; then
	printf '%s%s%s\n' "${ERROR_COLOR}" \
		"$(format_message "${MSG_UNKNOWN_ARG}" "${error_arg}")" "${ERROR_RESET}" >&2
	usage >&2
	exit 2
fi

if (( show_help )); then
	usage
	exit 0
fi

# Start functions
draw "${MSG_NUMBERS}" "${COUNTNUMBERS}" "${NUMBERSDOWN}" "${NUMBERSUP}" "${NUMBERS_COLOR}"
draw "${MSG_STARS}" "${COUNTSTARS}" "${STARSDOWN}" "${STARSUP}" "${STARS_COLOR}"
