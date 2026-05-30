#!/usr/bin/env bash
set -euo pipefail

pkgname="helium-browser-bin"
version="0.12.5.1"
revision="1"
short_desc="Private, fast, and honest web browser based on Chromium"
homepage="https://helium.computer"
license="GPL-3.0-only AND BSD-3-Clause"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "Need root to run: $*" >&2
    exit 1
  fi
}

ensure_cmd() {
  local cmd="$1" pkg="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Installing required package for '$cmd': $pkg"
    as_root xbps-install -Sy "$pkg"
  fi
  need "$cmd"
}

need xbps-install
need xbps-query

installed_pkgver="$(xbps-query -p pkgver "$pkgname" 2>/dev/null || true)"
expected_pkgver="${pkgname}-${version}_${revision}"
if [ "$installed_pkgver" = "$expected_pkgver" ]; then
  echo "$expected_pkgver is already installed; skipping Helium download."
  exit 0
fi

ensure_cmd curl curl
ensure_cmd xz xz
need tar
need xbps-create
need xbps-rindex

arch="$(xbps-uhelper arch 2>/dev/null || uname -m)"
case "$arch" in
  x86_64)
    upstream_arch="x86_64"
    checksum="b5f8b2d4c9315eaf6f3a3a79ed1df29078e5786d158b3fc2dadb705db1e73f00"
    ;;
  aarch64)
    upstream_arch="arm64"
    checksum="aba702aef0e1f5e61067008b02b297643a58925d19ce2da0f60a7d97e1be4080"
    ;;
  *-musl)
    echo "Helium's upstream Linux binary is glibc-based; refusing to package it for $arch." >&2
    exit 1
    ;;
  *)
    echo "Unsupported architecture: $arch" >&2
    exit 1
    ;;
esac

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

repo="$workdir/repo"
stage="$workdir/stage"
mkdir -p "$repo" "$stage/opt/$pkgname" \
  "$stage/usr/bin" \
  "$stage/usr/share/applications" \
  "$stage/usr/share/icons/hicolor/256x256/apps" \
  "$stage/usr/share/pixmaps"

archive="helium-${version}-${upstream_arch}_linux.tar.xz"
url="https://github.com/imputnet/helium-linux/releases/download/${version}/${archive}"

echo "Downloading $url"
curl -L --fail -o "$workdir/$archive" "$url"

echo "${checksum}  $workdir/$archive" | sha256sum -c -

tar -xf "$workdir/$archive" -C "$workdir"
extracted="$workdir/helium-${version}-${upstream_arch}_linux"

cp -a "$extracted/." "$stage/opt/$pkgname/"
ln -s "/opt/$pkgname/helium-wrapper" "$stage/usr/bin/helium-browser"

# Patch the desktop file to call the XBPS-managed launcher and icon name.
sed \
  -e 's/^Name=Helium$/Name=Helium Browser/' \
  -e 's/^Exec=helium/Exec=helium-browser/g' \
  -e 's/^Icon=helium$/Icon=helium-browser/' \
  "$extracted/helium.desktop" > "$stage/usr/share/applications/helium-browser.desktop"

install -m644 "$extracted/product_logo_256.png" \
  "$stage/usr/share/icons/hicolor/256x256/apps/helium-browser.png"
install -m644 "$extracted/product_logo_256.png" \
  "$stage/usr/share/pixmaps/helium-browser.png"

# xbps-create does not auto-detect ELF dependencies. Add dependency patterns
# only when the package name exists in the configured Void repositories, so a
# renamed optional integration package does not abort the whole install.
dep_pkgs=(
  desktop-file-utils
  hicolor-icon-theme
  liberation-fonts-ttf
  xdg-utils
  gtk+3
  nss
  alsa-lib
  dbus
  libcups
  libXScrnSaver
)

deps=""
for dep in "${dep_pkgs[@]}"; do
  if xbps-query -R "$dep" >/dev/null 2>&1; then
    deps+="${deps:+ }${dep}>=0"
  else
    echo "Warning: skipping unavailable XBPS dependency: $dep" >&2
  fi
done

(
  cd "$repo"
  xbps-create \
    -A "$arch" \
    -n "${pkgname}-${version}_${revision}" \
    -s "$short_desc" \
    -S "$short_desc. Packaged from the upstream Helium Linux tarball." \
    -H "$homepage" \
    -l "$license" \
    -m "local <local@void>" \
    -D "$deps" \
    "$stage"
  xbps-rindex -a "${pkgname}-${version}_${revision}.${arch}.xbps"
)

echo "Installing $pkgname through XBPS"
as_root xbps-install -y -R "$repo" "$pkgname"

echo "Installed. Run: helium-browser"
