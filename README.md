# Yabadabadoo for NextUI

A NextUI pak (tag `SATURN`) of [Yabadabadoo](https://github.com/elderica/Yabadabadoo),
a Sega Saturn libretro core, with its AArch64 SH-2 recompiler.

The paks are unofficial builds from the elderica/Yabadabadoo fork, where the AArch64
recompiler lives until it is merged upstream
([ProRapSuperstarOriginalMaster/Yabadabadoo](https://github.com/ProRapSuperstarOriginalMaster/Yabadabadoo)).
Then `core.env` switches to the upstream repository.

| NextUI platform | Devices |
|---|---|
| `tg5040` | TrimUI Smart Pro, Brick, Brick Hammer |
| `tg5050` | TrimUI Smart Pro S |
| `h700` | Anbernic RG35XX / RG40XX family |

## Install

- **Pak Store:** install *SATURN*.
- **By hand:** extract `Yabadabadoo-NextUI-<version>.zip` from a release at the root of
  the SD card.

Then put a Saturn BIOS in `Bios/SATURN/` (`sega_101.bin`, Japan, or `mpr-17933.bin`,
USA/Europe) and games in `Roms/Sega Saturn (SATURN)/`. The log of the last run is
`.userdata/<platform>/logs/SATURN.txt`.

## Versions

`v<Yabadabadoo version>.<package release>`, eg. `v0.3.0.1` is the first package of
Yabadabadoo 0.3 (written with three numbers). The Pak Store compares the four numbers.
`pak.json`'s `version`, the release tag and `release-notes/<version>.md` go together.
An empty `release-notes/<version>.prerelease` makes the release a pre-release.

## Build

`core.env` names the Yabadabadoo revision. The toolchains are NextUI's
`ghcr.io/loveretro/<platform>-toolchain` images (arm64), run with docker.

```sh
git clone https://github.com/elderica/Yabadabadoo core
git -C core checkout aarch64-dynarec
for p in tg5040 tg5050 h700; do ./scripts/build-core.sh $p core cores/$p; done
./scripts/make-zip.sh cores core dist
```

`dist/SATURN.pak.zip` is the Pak Store's file (the pak's contents, a core per
platform in `cores/<platform>`); `dist/Yabadabadoo-NextUI-<version>.zip` is the one to
extract at the root of the SD card.

GitHub Actions (`.github/workflows/build.yml`) builds them on every push, and for a
tag `v*` that matches `pak.json` makes the release with `release-notes/<tag>.md`.
