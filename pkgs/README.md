# pkgs

One folder per package, each with a PKGBUILD:

    pkgs/vtx/PKGBUILD
    pkgs/glassy-shell/PKGBUILD
    ...

Add `license=('GPL-3.0-or-later')` and the copyright line `# (c) 2026 34 & Claude`
to every PKGBUILD.

## Where the packages come from

- `vtx`, `cmaal`, `claudes-glassy` (glassy-shell, glassy-wallpapers), `vitrainstall`: our own projects
- `vitra-branding`: the Vitra logo (Scherben-V), icons, fastfetch logo and os-release;
  the files live right here in `pkgs/vitra-branding/`
- `illogical-impulse-*`: end-4's dependency packages, copied from
  claudes-glassy `deps/arch/` (https://github.com/end-4/dots-hyprland, GPL-3.0)
- everything else with a `.aur-origin` file: imported from the AUR with
  `./scripts/import-aur.sh <name>` so Vitra users get them prebuilt
