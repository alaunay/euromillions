#!/usr/bin/env bats
#
# Tests for tools/build-repo.sh. The package fixtures need the distribution
# tools, so a test skips only when the tooling for that format is absent.

setup() {
	ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
	WORK="${BATS_TEST_TMPDIR}"
	DIST="${WORK}/dist"
	SITE="${WORK}/site"

	mkdir -p "$DIST"

	export GNUPGHOME="${WORK}/gnupg"
	mkdir -p "$GNUPGHOME"
	chmod 700 "$GNUPGHOME"
}

make_deb() {
	local root="${WORK}/deb"
	mkdir -p "$root/DEBIAN"
	cat > "$root/DEBIAN/control" <<'EOF'
Package: testpkg
Version: 1.0.0
Architecture: all
Maintainer: Test <test@example.org>
Description: test package
EOF
	dpkg-deb --build "$root" "$DIST/testpkg_1.0.0_all.deb" >/dev/null
}

make_rpm() {
	local top="${WORK}/rpmbuild"
	mkdir -p "$top"
	cat > "${WORK}/testpkg.spec" <<'EOF'
Name: testpkg
Version: 1.0.0
Release: 1
Summary: test package
License: MIT
BuildArch: noarch
%description
test package
%install
install -Dm644 /dev/null %{buildroot}/usr/share/testpkg/file
%files
/usr/share/testpkg/file
%changelog
EOF
	rpmbuild -bb "${WORK}/testpkg.spec" --define "_topdir $top" >/dev/null
	cp "$top"/RPMS/noarch/*.rpm "$DIST/"
}

make_key() {
	gpg --batch --pinentry-mode loopback --passphrase '' \
		--quick-generate-key 'Repo Test <repo@example.org>' rsa2048 sign 1d >/dev/null 2>&1
	gpg --list-secret-keys --with-colons | awk -F: '/^sec/ { print $5; exit }'
}

@test "prints usage without arguments" {
	run "$ROOT/tools/build-repo.sh"
	[ "$status" -ne 0 ]
}

@test "warns without a signing key" {
	command -v dpkg-scanpackages >/dev/null || skip "dpkg-scanpackages is missing"
	command -v apt-ftparchive >/dev/null || skip "apt-ftparchive is missing"

	run env -u REPO_GPG_KEY_ID REPO_ORIGIN=test REPO_LABEL=test REPO_NAME=test \
		"$ROOT/tools/build-repo.sh" "$DIST" "$SITE"

	[ "$status" -eq 0 ]
	[[ "$output" == *"stays unsigned"* ]]
	[ -f "$SITE/index.html" ]
	[ -f "$SITE/test.repo" ]
}

@test "builds a signed apt repository" {
	command -v dpkg-deb >/dev/null || skip "dpkg-deb is missing"
	command -v dpkg-scanpackages >/dev/null || skip "dpkg-scanpackages is missing"
	command -v apt-ftparchive >/dev/null || skip "apt-ftparchive is missing"
	command -v gpg >/dev/null || skip "gpg is missing"

	make_deb
	key=$(make_key)

	run env REPO_GPG_KEY_ID="$key" REPO_ORIGIN=test REPO_LABEL=test REPO_NAME=test \
		"$ROOT/tools/build-repo.sh" "$DIST" "$SITE"

	[ "$status" -eq 0 ]
	[ -f "$SITE/apt/dists/stable/InRelease" ]
	grep -q '^Package: testpkg$' "$SITE/apt/dists/stable/main/binary-amd64/Packages"
	gpg --verify "$SITE/apt/dists/stable/InRelease" >/dev/null 2>&1
}

@test "builds a signed rpm repository" {
	command -v rpmbuild >/dev/null || skip "rpmbuild is missing"
	command -v createrepo_c >/dev/null || skip "createrepo_c is missing"
	command -v gpg >/dev/null || skip "gpg is missing"

	make_rpm
	key=$(make_key)

	run env REPO_GPG_KEY_ID="$key" REPO_ORIGIN=test REPO_LABEL=test REPO_NAME=test \
		"$ROOT/tools/build-repo.sh" "$DIST" "$SITE"

	[ "$status" -eq 0 ]
	[ -f "$SITE/rpm/el10/repodata/repomd.xml" ]
	[ -f "$SITE/rpm/el10/repodata/repomd.xml.asc" ]
	gpg --verify "$SITE/rpm/el10/repodata/repomd.xml.asc" \
		"$SITE/rpm/el10/repodata/repomd.xml" >/dev/null 2>&1

	rpm --dbpath "${WORK}/rpmdb" --initdb
	gpg --armor --export "$key" > "${WORK}/key.asc"
	rpm --dbpath "${WORK}/rpmdb" --import "${WORK}/key.asc"
	run rpm --dbpath "${WORK}/rpmdb" --checksig "$SITE"/rpm/el10/*.rpm
	[[ "$output" == *"signatures OK"* ]]
}
