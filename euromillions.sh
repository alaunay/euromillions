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

# Data lives beside the script in a checkout, and under /usr/share when
# the distribution package installs it
DATA_DIR=${EUROMILLIONS_DATADIR:-}
if [ -z "$DATA_DIR" ] && [ -d "${SCRIPT_DIR}/../share/euromillions/po" ]; then
	DATA_DIR=$(cd -- "${SCRIPT_DIR}/../share/euromillions" && pwd)
fi
DATA_DIR=${DATA_DIR:-$SCRIPT_DIR}

# Grid shape, overridable from the environment
COUNTNUMBERS=${COUNTNUMBERS:-5}
NUMBERSUP=${NUMBERSUP:-50}
NUMBERSDOWN=${NUMBERSDOWN:-1}
COUNTSTARS=${COUNTSTARS:-2}
STARSUP=${STARSUP:-12}
STARSDOWN=${STARSDOWN:-1}

# Entropy source for shuf, overridable to get a reproducible draw
RANDOM_SOURCE=${RANDOM_SOURCE:-/dev/urandom}

# auto, always, or never; see use_color
COLOR_MODE=${EUROMILLIONS_COLOR:-auto}

# gettext binary, empty when the package is absent; see _
GETTEXT=$(command -v gettext || true)

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

# Translate a message. The msgid is the English text, so a missing
# gettext binary still prints English.
_ () {
	if [ -n "${GETTEXT}" ]; then
		"${GETTEXT}" "$1"
	else
		printf '%s' "$1"
	fi
}

# gettext ignores LANGUAGE when the locale is C, so a C locale is
# replaced by the language's own locale. An unknown code keeps the
# caller's locale: naming a locale that does not exist makes glibc warn.
setup_locale () {
	local code=$1
	local mapped=

	case "$code" in
		en) mapped=en_US.UTF-8 ;;
		fr) mapped=fr_FR.UTF-8 ;;
	esac

	TEXTDOMAIN=euromillions
	TEXTDOMAINDIR="${DATA_DIR}/locale"
	LANGUAGE=$code
	export TEXTDOMAIN TEXTDOMAINDIR LANGUAGE

	if [ -n "$mapped" ]; then
		LC_MESSAGES=$mapped
		LANG=$mapped
		unset LC_ALL
		export LC_MESSAGES LANG
	fi
}

# Warn once when a requested language has no working catalogue
warn_missing_translation () {
	local code=$1

	case "$code" in
		en|C|C.*|POSIX) return 0 ;;
	esac

	# A working catalogue translates this msgid
	[ "$(_ 'Numbers')" = "Numbers" ] || return 0

	printf '%s\n' "$(format_message "$(_ 'no translation for %s, using English')" "$code")" >&2
}

# Build the language list: English plus every PO catalogue
languages () {
	local file code list=en

	for file in "${DATA_DIR}"/po/*.po; do
		[ -e "$file" ] || continue
		code=${file##*/}
		code=${code%.po}
		[ "$code" = en ] && continue
		list+=" ${code}"
	done

	printf '%s\n' "${list}"
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
	printf '%s %s [--lang CODE] [--no-color] [-h | --help]\n\n' "$(_ 'Usage:')" "${0##*/}"
	printf '%s\n\n' "$(format_message "$(_ 'Draw %s numbers from %s to %s and %s stars from %s to %s.')" \
		"${COUNTNUMBERS}" "${NUMBERSDOWN}" "${NUMBERSUP}" \
		"${COUNTSTARS}" "${STARSDOWN}" "${STARSUP}")"
	printf '%s\n' "$(_ 'Options:')"
	printf '  -l, --lang CODE  %s\n' "$(_ 'output language, overriding the locale')"
	printf '      --no-color   %s\n' "$(_ 'never use colours')"
	printf '  -h, --help       %s\n' "$(_ 'show this help')"
	printf '\n%s %s\n' "$(_ 'Languages:')" "$(languages)"
}

# Language from EUROMILLIONS_LANG, then the locale, then English
detect_language () {
	local code=${EUROMILLIONS_LANG:-${LC_ALL:-${LANG:-}}}
	code=${code%%.*}
	code=${code%%_*}
	printf '%s' "${code:-en}"
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
		printf '%s%s: %s%s\n' "${ERROR_COLOR}" "$(_ 'draw failed')" "${label}" "${ERROR_RESET}" >&2
		exit 1
	fi

	mapfile -t draws <<< "${output}"

	if (( ${#draws[@]} != count )); then
		printf '%s%s: %s (%s/%s)%s\n' "${ERROR_COLOR}" "$(_ 'short draw')" "${label}" \
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
setup_locale "$language"
warn_missing_translation "$language"

if [ "$error_kind" = needs_code ]; then
	printf '%s%s%s\n' "${ERROR_COLOR}" \
		"$(format_message "$(_ 'option %s needs a language code')" "${error_arg}")" "${ERROR_RESET}" >&2
	usage >&2
	exit 2
fi

if [ "$error_kind" = unknown ]; then
	printf '%s%s%s\n' "${ERROR_COLOR}" \
		"$(format_message "$(_ 'unknown argument: %s')" "${error_arg}")" "${ERROR_RESET}" >&2
	usage >&2
	exit 2
fi

if (( show_help )); then
	usage
	exit 0
fi

# Start functions
draw "$(_ 'Numbers')" "${COUNTNUMBERS}" "${NUMBERSDOWN}" "${NUMBERSUP}" "${NUMBERS_COLOR}"
draw "$(_ 'Stars')" "${COUNTSTARS}" "${STARSDOWN}" "${STARSUP}" "${STARS_COLOR}"
