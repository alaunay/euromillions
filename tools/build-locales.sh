#!/bin/sh
#
# Compile po/*.po into locale/<code>/LC_MESSAGES/euromillions.mo.
# Needs msgfmt, from the gettext package.

set -eu

root=$(cd -- "$(dirname -- "$0")/.." && pwd)

for po in "$root"/po/*.po; do
	[ -e "$po" ] || continue
	code=$(basename "$po" .po)
	mkdir -p "$root/locale/$code/LC_MESSAGES"
	final="$root/locale/$code/LC_MESSAGES/euromillions.mo"
	tmp="$final.tmp"

	# Compile to a temporary name: a failed msgfmt leaves no catalogue
	if ! msgfmt --check --output-file="$tmp" "$po"; then
		rm -f "$tmp"
		exit 1
	fi
	mv "$tmp" "$final"
	printf 'built %s\n' "$final"
done
