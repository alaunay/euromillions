# bash completion for euromillions
#
# Install as /usr/share/bash-completion/completions/euromillions, or
# source it from ~/.bashrc for a checkout.

# Language codes come from the script itself: --help ends with the list
_euromillions_languages () {
	local line

	line=$("$1" --help 2>/dev/null | tail -n 1) || return 1

	case "$line" in
		*:*) compgen -W "${line#*:}" -- "${2:-}" ;;
	esac
}

_euromillions () {
	local cur prev cmd
	local option

	COMPREPLY=()
	cur=${COMP_WORDS[COMP_CWORD]}
	prev=${COMP_WORDS[COMP_CWORD-1]}
	cmd=${COMP_WORDS[0]}

	case "$prev" in
		-l|--lang)
			mapfile -t COMPREPLY < <(_euromillions_languages "$cmd" "$cur")
			return 0
			;;
	esac

	case "$cur" in
		--lang=*)
			while IFS= read -r option; do
				COMPREPLY+=("--lang=${option}")
			done < <(_euromillions_languages "$cmd" "${cur#--lang=}")
			return 0
			;;
	esac

	mapfile -t COMPREPLY < <(compgen -W '-l --lang --cron --threshold --no-color -h --help' -- "$cur")
}

complete -F _euromillions euromillions euromillions.sh
