#!/bin/sh
# build-core.sh <platform> <yabadabadoo checkout> <out dir>
# Builds yabadabadoo_libretro.so for a NextUI platform (tg5040, tg5050, h700)
# in that platform's toolchain image and checks it runs with the device's glibc.
set -e
[ $# -eq 3 ] || { echo "usage: $0 <platform> <yabadabadoo checkout> <out dir>" >&2; exit 1; }
platform=$1
src=$(cd "$2" && pwd)
mkdir -p "$3"
out=$(cd "$3" && pwd)
case $platform in
	tg5040|h700) glibc=2.28 ;;
	tg5050) glibc=2.33 ;;
	*) echo "unknown platform: $platform" >&2; exit 1 ;;
esac
image=ghcr.io/loveretro/$platform-toolchain:latest
docker run --rm -u "$(id -u):$(id -g)" -v "$src:/src" -w /src/yabause/src/libretro "$image" \
	sh -c "make platform=$platform clean >/dev/null && make platform=$platform -j\$(nproc)"
so=$src/yabause/src/libretro/yabadabadoo_libretro.so
# the newest glibc symbol version the core needs must exist on the device
need=$(objdump -T "$so" | grep -o 'GLIBC_[0-9.]*' | sed 's/GLIBC_//' | sort -uV | tail -n 1)
if [ "$(printf '%s\n%s\n' "$need" "$glibc" | sort -V | tail -n 1)" != "$glibc" ]; then
	echo "$platform: the core needs glibc $need, the device has $glibc" >&2
	exit 1
fi
cp "$so" "$out/yabadabadoo_libretro.so"
echo "$out/yabadabadoo_libretro.so (glibc $need)"
