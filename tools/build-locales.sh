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
	msgfmt --check --output-file="$root/locale/$code/LC_MESSAGES/euromillions.mo" "$po"
	printf 'built %s\n' "$root/locale/$code/LC_MESSAGES/euromillions.mo"
done
