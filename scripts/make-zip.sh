#!/bin/sh
# make-zip.sh <cores dir> <yabadabadoo checkout> <out dir>
# From <cores dir>/<platform>/yabadabadoo_libretro.so, makes in <out dir>:
#   SATURN.pak.zip                    the pak's contents, for the Pak Store (all platforms)
#   Yabadabadoo-NextUI-<version>.zip  extract at the root of the SD card
# The version is pak.json's: v<Yabadabadoo version, 3 numbers>.<package release>,
# eg. v0.3.0.1 for the first package of Yabadabadoo 0.3.
set -e
[ $# -eq 3 ] || { echo "usage: $0 <cores dir> <yabadabadoo checkout> <out dir>" >&2; exit 1; }
here=$(cd "$(dirname "$0")/.." && pwd)
cores=$(cd "$1" && pwd)
src=$(cd "$2" && pwd)
mkdir -p "$3"
out=$(cd "$3" && pwd)

version=$(jq -r .version "$here/pak.json")
# the Yabadabadoo version, from the core's own info file ("0.3" -> 0.3.0)
core_version=$(sed -n 's/^display_version *= *"\(.*\)"/\1/p' \
	"$src/packaging/onion/RetroArch/.retroarch/cores/yabadabadoo_libretro.info")
case $core_version in
	*.*.*) ;;
	*.*) core_version=$core_version.0 ;;
	*) core_version=$core_version.0.0 ;;
esac
case $version in
	v"$core_version".[0-9]*) ;;
	*) echo "pak.json version $version is not v$core_version.<package release>" >&2; exit 1 ;;
esac
rev=$(git -C "$src" rev-parse --short HEAD 2>/dev/null || echo unknown)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# pak <dir> <platform>...: the pak with the cores of those platforms
pak() {
	dir=$1
	shift
	mkdir -p "$dir"
	cp "$here/nextui/SATURN.pak/"* "$dir/"
	for platform in "$@"; do
		mkdir -p "$dir/cores/$platform"
		cp "$cores/$platform/yabadabadoo_libretro.so" "$dir/cores/$platform/"
	done
	cp "$src/yabause/COPYING" "$dir/LICENSE-yabadabadoo.txt"
	cp "$src/packaging/THIRD-PARTY-NOTICES.txt" "$dir/THIRD-PARTY-NOTICES.txt"
	printf 'SATURN.pak %s\nYabadabadoo %s (%s)\n' "$version" "$core_version" "$rev" > "$dir/version.txt"
	chmod +x "$dir/launch.sh"
}

platforms=
for so in "$cores"/*/yabadabadoo_libretro.so; do
	[ -f "$so" ] || continue
	platforms="$platforms $(basename "$(dirname "$so")")"
done
[ -n "$platforms" ] || { echo "no cores in $cores" >&2; exit 1; }

# Pak Store: the zip holds what is inside SATURN.pak
# shellcheck disable=SC2086 # one argument per platform
pak "$tmp/store" $platforms
rm -f "$out/SATURN.pak.zip"
(cd "$tmp/store" && zip -qrX "$out/SATURN.pak.zip" .)

# SD card: Bios and Roms folders, and a pak per platform with its own core
mkdir -p "$tmp/sd"
cp -R "$here/nextui/Bios" "$here/nextui/Roms" "$tmp/sd/"
for platform in $platforms; do
	pak "$tmp/sd/Emus/$platform/SATURN.pak" "$platform"
done
sd=Yabadabadoo-NextUI-$version.zip
rm -f "$out/$sd"
(cd "$tmp/sd" && zip -qrX "$out/$sd" Bios Emus Roms)

echo "$out/SATURN.pak.zip"
echo "$out/$sd"
