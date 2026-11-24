#!/usr/bin/env bash
# vitra-repo: copy AUR packages into pkgs/ so [vitra] ships them prebuilt
# (c) 2026 34 & Claude - GPL-3.0
#
#   ./scripts/import-aur.sh wlogout darkly-bin ...   import / update from the AUR
#   (package names or pkgbases; split packages are imported by their pkgbase)
#
# Keeps the PKGBUILD and its local files, writes pkgs/<name>/.aur-origin
# (AUR commit) so you can see where it came from.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
(( $# )) || { echo "usage: $0 <aur-package>..."; exit 1; }
for want in "$@"; do
    # split packages live under their pkgbase (otf-space-grotesk -> 38c3-styles)
    p=$(curl -fsSL "https://aur.archlinux.org/rpc/v5/info?arg[]=$want" | jq -r '.results[0].PackageBase // empty')
    [[ -n $p ]] || { echo "!! $want: not in the AUR"; exit 1; }
    [[ $p != "$want" ]] && echo ":: $want is built by $p"
    tmp=$(mktemp -d)
    git clone -q --depth 1 "https://aur.archlinux.org/$p.git" "$tmp/$p"
    [[ -f $tmp/$p/PKGBUILD ]] || { echo "!! $p: not in the AUR"; rm -rf "$tmp"; exit 1; }
    rm -rf "$ROOT/pkgs/$p"
    mkdir -p "$ROOT/pkgs/$p"
    (cd "$tmp/$p" && git ls-files -z | xargs -0 -I{} cp --parents {} "$ROOT/pkgs/$p/")
    rm -f "$ROOT/pkgs/$p/.SRCINFO" "$ROOT/pkgs/$p/.gitignore"
    printf 'https://aur.archlinux.org/packages/%s\ncommit %s\nimported %s\n' \
        "$p" "$(git -C "$tmp/$p" rev-parse --short HEAD)" "$(date +%F)" >"$ROOT/pkgs/$p/.aur-origin"
    rm -rf "$tmp"
    echo ":: imported $p"
done
