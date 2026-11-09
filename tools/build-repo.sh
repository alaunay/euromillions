#!/bin/sh
#
# Assemble the apt and rpm repositories served by GitHub Pages.
#
# usage: REPO_GPG_KEY_ID=... tools/build-repo.sh DIST OUT
#
# DIST holds the .deb and .rpm files, OUT receives the site tree. Without a
# key the metadata stays unsigned, which apt will refuse by default.

set -eu

dist=${1:?usage: build-repo.sh DIST OUT}
out=${2:?usage: build-repo.sh DIST OUT}
key=${REPO_GPG_KEY_ID:-}
origin=${REPO_ORIGIN:-repository}
label=${REPO_LABEL:-$origin}
repo=${REPO_NAME:-$(basename "$(dirname "$out")")}
base=${REPO_BASE_URL:-https://alaunay.github.io/$repo}

mkdir -p "$out/apt/dists/stable/main/binary-amd64" "$out/apt/pool/main" \
	"$out/rpm/el10" "$out/keys"

sign() {
	if [ -z "$key" ]; then
		echo "warning: REPO_GPG_KEY_ID is not set, metadata stays unsigned" >&2
		return 1
	fi

	gpg --batch --yes --local-user "$key" "$@"
}

# ---- Debian -----------------------------------------------------------
for deb in "$dist"/*.deb; do
	[ -e "$deb" ] || continue
	cp "$deb" "$out/apt/pool/main/"
done

(
	cd "$out/apt"
	dpkg-scanpackages --multiversion pool > dists/stable/main/binary-amd64/Packages
	gzip -9cf dists/stable/main/binary-amd64/Packages > dists/stable/main/binary-amd64/Packages.gz
)

cat > "$out/apt/apt-ftparchive.conf" <<EOF
APT::FTPArchive::Release::Origin "$origin";
APT::FTPArchive::Release::Label "$label";
APT::FTPArchive::Release::Suite "stable";
APT::FTPArchive::Release::Codename "stable";
APT::FTPArchive::Release::Architectures "amd64";
APT::FTPArchive::Release::Components "main";
APT::FTPArchive::Release::Description "$label packages";
EOF

apt-ftparchive -c "$out/apt/apt-ftparchive.conf" release "$out/apt/dists/stable" \
	> "$out/apt/dists/stable/Release"

if sign --clearsign -o "$out/apt/dists/stable/InRelease" "$out/apt/dists/stable/Release"; then
	sign --armor --detach-sign -o "$out/apt/dists/stable/Release.gpg" \
		"$out/apt/dists/stable/Release"
fi

# ---- RPM --------------------------------------------------------------
rpm_dir="$out/rpm/el10"

for package in "$dist"/*.rpm; do
	[ -e "$package" ] || continue
	cp "$package" "$rpm_dir/"

	if [ -n "$key" ]; then
		rpmsign --addsign --define "_gpg_name $key" "$rpm_dir/$(basename "$package")" \
			>/dev/null
	fi
done

if ls "$rpm_dir"/*.rpm >/dev/null 2>&1; then
	if ! command -v createrepo_c >/dev/null 2>&1; then
		echo "createrepo_c is required for the rpm repository" >&2
		exit 1
	fi

	createrepo_c --quiet --database "$rpm_dir"

	if [ -n "$key" ]; then
		sign --armor --detach-sign -o "$rpm_dir/repodata/repomd.xml.asc" \
			"$rpm_dir/repodata/repomd.xml"
	fi
fi

# ---- Keys and landing page -------------------------------------------
if [ -n "$key" ]; then
	gpg --armor --export "$key" > "$out/keys/repo.asc"
fi

cat > "$out/index.html" <<EOF
<!doctype html>
<html lang="en">
<meta charset="utf-8">
<title>$label packages</title>
<h1>$label packages</h1>

<h2>Debian and Ubuntu</h2>
<pre>
curl -fsSL $base/keys/repo.asc \\
  | sudo gpg --dearmor -o /usr/share/keyrings/$origin.gpg
echo "deb [signed-by=/usr/share/keyrings/$origin.gpg] \\
$base/apt stable main" \\
  | sudo tee /etc/apt/sources.list.d/$origin.list
sudo apt update &amp;&amp; sudo apt install $origin
</pre>

<h2>CentOS and RHEL</h2>
<pre>
sudo curl -fsSL -o /etc/yum.repos.d/$origin.repo \\
  $base/$origin.repo
sudo dnf install $origin
</pre>
</html>
EOF

cat > "$out/$origin.repo" <<EOF
[$origin]
name=$label
baseurl=$base/rpm/el10
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=$base/keys/repo.asc
EOF
