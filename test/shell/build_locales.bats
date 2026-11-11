#!/usr/bin/env bats
#
# Tests for tools/build-locales.sh.

setup() {
	ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
	TEST_TMPDIR=${BATS_TEST_TMPDIR:-$(mktemp -d)}
	SANDBOX="${TEST_TMPDIR}/repo"

	mkdir -p "${SANDBOX}/tools" "${SANDBOX}/po"
	cp "${ROOT}/tools/build-locales.sh" "${SANDBOX}/tools/"
	cp "${ROOT}"/po/*.po "${SANDBOX}/po/"

	MO="${SANDBOX}/locale/fr/LC_MESSAGES/euromillions.mo"
}

@test "compiles a catalogue for each po file" {
	run "${SANDBOX}/tools/build-locales.sh"
	[ "$status" -eq 0 ]
	[ -f "$MO" ]
	[[ "$output" == *"built "* ]]
}

@test "is idempotent" {
	run "${SANDBOX}/tools/build-locales.sh"
	[ "$status" -eq 0 ]
	first=$(md5sum "$MO" | cut -d' ' -f1)

	run "${SANDBOX}/tools/build-locales.sh"
	[ "$status" -eq 0 ]
	[ "$(md5sum "$MO" | cut -d' ' -f1)" = "$first" ]
}

@test "does nothing when there is no po file" {
	rm "${SANDBOX}"/po/*.po
	run "${SANDBOX}/tools/build-locales.sh"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
	[ ! -d "${SANDBOX}/locale" ]
}

@test "fails on a malformed catalogue" {
	printf 'msgid ""\nmsgstr ""\n\nmsgid "unterminated\n' > "${SANDBOX}/po/broken.po"

	run "${SANDBOX}/tools/build-locales.sh"
	[ "$status" -ne 0 ]
	[ ! -f "${SANDBOX}/locale/broken/LC_MESSAGES/euromillions.mo" ]
}

@test "rejects a translation whose placeholders drift" {
	cat > "${SANDBOX}/po/drift.po" <<'EOF'
msgid ""
msgstr ""
"Content-Type: text/plain; charset=UTF-8\n"

#, python-format
msgid "Draw %s numbers."
msgstr "Tirer %s numéros sur %s."
EOF

	run "${SANDBOX}/tools/build-locales.sh"
	[ "$status" -ne 0 ]
	[[ "$output" == *"drift.po"* ]]
	[ ! -f "${SANDBOX}/locale/drift/LC_MESSAGES/euromillions.mo" ]
}
