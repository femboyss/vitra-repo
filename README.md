# vitra-repo

Package repository for **Vitra**, an Arch-based Linux distribution.
Browse the packages: **vitra-web** -> https://femboyss.github.io/vitra-web

(c) 2026 34 & Claude. Licensed under GPL-3.0.

## Use it on Arch / Vitra

Add this to the end of `/etc/pacman.conf`:

```
[vitra]
SigLevel = Optional TrustAll
Server = https://github.com/femboyss/vitra-repo/releases/download/$arch
```

Then:

```
sudo pacman -Sy
pacman -Sl vitra        # list all Vitra packages
sudo pacman -S vtx      # install a package
```

> `SigLevel = Optional TrustAll` is only for the testing phase. Once packages are
> signed, this will change to a proper key import.

## How it works

- Every package lives in `pkgs/<name>/PKGBUILD`
- `scripts/build.sh` builds all packages and creates the pacman database in `out/x86_64/`
- `scripts/publish.sh` uploads everything to the GitHub release `x86_64`
  (that is what pacman downloads from) and writes `packages.json` for vitra-web
- Built packages are **never** committed to git, only uploaded as release assets

## Building (maintainers)

```
./scripts/build.sh              # build all packages
./scripts/build.sh vtx          # build only vtx
GPGKEY=<keyid> ./scripts/build.sh   # build and sign
./scripts/publish.sh            # upload to GitHub (needs gh, logged in)
```

---

## Deutsch

Paket-Repository fuer **Vitra**, eine Arch-basierte Linux-Distribution.
Pakete anschauen: **vitra-web** -> https://femboyss.github.io/vitra-web

Einbinden: den `[vitra]`-Block von oben ans Ende von `/etc/pacman.conf`, dann
`sudo pacman -Sy`. Danach findet pacman (und yay, paru, cmaal, vtx) alle Vitra-Pakete.

Pakete liegen in `pkgs/<name>/PKGBUILD`. `scripts/build.sh` baut sie, `scripts/publish.sh`
laedt sie ins GitHub-Release `x86_64` hoch. Fertige Pakete kommen nie ins Git, nur ins Release.

(c) 2026 34 & Claude. Lizenz: GPL-3.0.
