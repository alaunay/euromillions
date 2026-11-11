#!/usr/bin/env bash

set -euo pipefail

source_path=${BASH_SOURCE[0]}
if command -v readlink >/dev/null 2>&1 && readlink -f -- / >/dev/null 2>&1; then
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

# shuf is GNU coreutils; BSD and macOS install it as gshuf
SHUF=${SHUF:-shuf}

# auto, always, or never; see use_color
COLOR_MODE=${EUROMILLIONS_COLOR:-auto}

# Jackpot alert: mail when the next draw can pay at least this much
JACKPOT_URL=${JACKPOT_URL:-https://www.sto.api.fdj.fr/anonymous/service-draw-info/v3/draws?game_name=euromillions&current=true}
CURL=${CURL:-curl}
ALERT_THRESHOLD=${ALERT_THRESHOLD:-100000000}
ALERT_TO=${ALERT_TO:-}
ALERT_MAILER=${ALERT_MAILER:-}

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
	printf '%s %s [--cron | --threshold] [--lang CODE] [--no-color] [-h | --help]\n\n' "$(_ 'Usage:')" "${0##*/}"
	printf '%s\n\n' "$(format_message "$(_ 'Draw %s numbers from %s to %s and %s stars from %s to %s.')" \
		"${COUNTNUMBERS}" "${NUMBERSDOWN}" "${NUMBERSUP}" \
		"${COUNTSTARS}" "${STARSDOWN}" "${STARSUP}")"
	printf '%s\n' "$(_ 'Options:')"
	printf '  -l, --lang CODE  %s\n' "$(_ 'output language, overriding the locale')"
	printf '      --cron       %s\n' "$(_ 'mail the next jackpot when it reaches the threshold')"
	printf '      --threshold  %s\n' "$(_ 'print the alert threshold and exit')"
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
	if ! output=$("${SHUF}" --random-source="${RANDOM_SOURCE}" -i "${lo}-${hi}" -n "${count}" | sort -n); then
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

# Format an amount of euro with the nearest SI prefix, rounded
si_amount () {
	local amount=$1
	local divisor=1
	local prefix=
	local value

	while :; do
		value=$(( (amount + divisor / 2) / divisor ))
		(( value < 1000 )) && break

		case "$prefix" in
			'') prefix=k ;;
			k) prefix=M ;;
			M) prefix=G ;;
			G) prefix=T ;;
			*) break ;;
		esac
		divisor=$(( divisor * 1000 ))
	done

	printf '%s %s€' "${value}" "${prefix}"
}

# Validate the alert threshold
check_threshold () {
	case "$ALERT_THRESHOLD" in
		''|*[!0-9]*)
			printf '%s\n' "$(format_message "$(_ 'invalid ALERT_THRESHOLD: %s')" "$ALERT_THRESHOLD")" >&2
			exit 2
			;;
	esac
}

send_alert () {
	local subject=$1
	local body=$2
	local mailer=$ALERT_MAILER

	if [ -z "$mailer" ]; then
		if command -v sendmail >/dev/null 2>&1; then
			mailer=sendmail
		elif command -v msmtp >/dev/null 2>&1; then
			mailer=msmtp
		elif command -v mail >/dev/null 2>&1; then
			mailer=mail
		fi
	fi

	if [ -z "$mailer" ]; then
		printf '%s\n' "$(_ 'alert: no mailer found, set ALERT_MAILER')" >&2
		return 1
	fi

	case ${mailer##*/} in
		sendmail|msmtp)
			if ! printf 'To: %s\nSubject: %s\nMIME-Version: 1.0\nContent-Type: text/plain; charset=UTF-8\n\n%s\n' \
				"$ALERT_TO" "$subject" "$body" | "$mailer" -t; then
				printf '%s\n' "$(_ 'alert: the mailer failed')" >&2
				return 1
			fi
			;;
		*)
			if ! printf '%s\n' "$body" | "$mailer" -s "$subject" "$ALERT_TO"; then
				printf '%s\n' "$(_ 'alert: the mailer failed')" >&2
				return 1
			fi
			;;
	esac
}

# The next jackpot, in euro, from the FDJ draw information endpoint
fetch_jackpot () {
	local response raw value scale

	if ! command -v "$CURL" >/dev/null 2>&1; then
		printf '%s\n' "$(_ 'alert: curl is not installed')" >&2
		return 1
	fi

	if ! response=$("$CURL" -fsS --max-time 10 -H 'User-Agent: euromillions' \
		"$JACKPOT_URL" 2>/dev/null); then
		printf '%s\n' "$(format_message "$(_ 'alert: cannot read the jackpot from %s')" "$JACKPOT_URL")" >&2
		return 1
	fi

	raw=$(printf '%s' "$response" |
		sed -n 's/.*"estimated_jackpot":\[{"value":\([0-9]*\),"currency":"EUR","scale":\([0-9]*\)}.*/\1 \2/p')

	if [ -z "$raw" ]; then
		printf '%s\n' "$(_ 'alert: the jackpot response is invalid')" >&2
		return 1
	fi

	value=${raw% *}
	scale=${raw#* }

	while (( scale > 0 )); do
		value=$((value / 10))
		scale=$((scale - 1))
	done

	printf '%s' "$value"
}

# Mail the next jackpot when it reaches the threshold, and stay silent otherwise
run_cron () {
	local jackpot amount

	check_threshold

	if ! jackpot=$(fetch_jackpot); then
		return 1
	fi

	(( jackpot >= ALERT_THRESHOLD )) || return 0

	amount=$(si_amount "$jackpot")

	if [ -z "$ALERT_TO" ]; then
		printf '%s\n' "$(_ 'alert: ALERT_TO is not set, no mail sent')" >&2
		return 1
	fi

	send_alert "$(format_message "$(_ 'Euromillions: next draw %s')" "$amount")" \
		"$(format_message "$(_ 'next draw: %s')" "$amount")"
}

language=$(detect_language)
show_help=0
cron=0
show_threshold=0
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
		--cron)
			cron=1
			shift
			;;
		--threshold)
			show_threshold=1
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

if (( show_threshold )); then
	check_threshold
	si_amount "$ALERT_THRESHOLD"
	printf '\n'
	exit 0
fi

if (( cron )); then
	run_cron
	exit $?
fi

# Start functions
draw "$(_ 'Numbers')" "${COUNTNUMBERS}" "${NUMBERSDOWN}" "${NUMBERSUP}" "${NUMBERS_COLOR}"
draw "$(_ 'Stars')" "${COUNTSTARS}" "${STARSDOWN}" "${STARSUP}" "${STARS_COLOR}"
