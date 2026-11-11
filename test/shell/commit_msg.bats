#!/usr/bin/env bats
#
# Tests for .githooks/commit-msg.

setup() {
	ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
	TEST_TMPDIR=${BATS_TEST_TMPDIR:-$(mktemp -d)}
	REPO="${TEST_TMPDIR}/repo"

	mkdir -p "${REPO}/.githooks"
	cp "${ROOT}/.githooks/commit-msg" "${REPO}/.githooks/"

	cd "${REPO}"
	git init -q
	git config user.name "Test"
	git config user.email "test@example.org"
	git config commit.gpgsign false
	git config core.hooksPath .githooks
}

commit() {
	git commit -q --allow-empty -m "$1" -m "$(printf '%s\n' "$2")"
}

@test "rejects a commit without trailers" {
	run commit "no trailers" "Body only."
	[ "$status" -ne 0 ]
	[[ "$output" == *"Co-authored-by"* ]]
}

@test "rejects a commit without a sign-off" {
	run commit "partial" "Co-authored-by: A <a@example.org>"
	[ "$status" -ne 0 ]
	[[ "$output" == *"Signed-off-by"* ]]
}

@test "rejects a sign-off that does not match the committer" {
	run commit "wrong sign-off" "Co-authored-by: A <a@example.org>
Signed-off-by: A <other@example.org>"
	[ "$status" -ne 0 ]
	[[ "$output" == *"does not match"* ]]
}

@test "accepts both trailers" {
	run commit "good" "Co-authored-by: A <a@example.org>
Signed-off-by: A <test@example.org>"
	[ "$status" -eq 0 ]
	git log -1 --format=%B | grep -q '^Signed-off-by: A <test@example.org>$'
}
