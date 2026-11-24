#!/usr/bin/env bash
# vitra-repo: can every [vitra] package be installed on a CLEAN Vitra/Arch system?
# (c) 2026 34 & Claude - GPL-3.0
#
# Uses its own pacman config with only core, extra, multilib and [vitra]
# (not the repos of the machine you run it on, e.g. SteamOS holo/jupiter),
# downloads fresh package lists into a temp folder and asks pacman to resolve
# every package. No root needed (uses fakeroot), nothing is installed.
#
#   ./scripts/check-deps.sh            check the published repo
#   ./scripts/check-deps.sh --local    check out/x86_64 (before publishing)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
command -v fakeroot >/dev/null || { echo "!! fakeroot missing: sudo pacman -S --needed base-devel"; exit 1; }
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/db" "$TMP/cache"

server='https://github.com/femboyss/vitra-repo/releases/download/$arch'
[[ ${1:-} == --local ]] && server="file://$ROOT/out/\$arch"

cat >"$TMP/pacman.conf" <<CONF
[options]
Architecture = auto
SigLevel = Never
[core]
Include = /etc/pacman.d/mirrorlist
[extra]
Include = /etc/pacman.d/mirrorlist
[multilib]
Include = /etc/pacman.d/mirrorlist
[vitra]
Server = $server
CONF

P=(pacman --config "$TMP/pacman.conf" --dbpath "$TMP/db" --cachedir "$TMP/cache" --noconfirm)
echo ":: downloading clean package lists (core, extra, multilib, vitra)"
fakeroot -- "${P[@]}" -Sy >/dev/null
mapfile -t pkgs < <("${P[@]}" -Slq vitra)
echo ":: checking ${#pkgs[@]} [vitra] packages"
bad=0
for p in "${pkgs[@]}"; do
    if ! out=$("${P[@]}" -Sp --print-format '%n' "vitra/$p" 2>&1 >/dev/null); then
        echo "!! $p"; sed 's/^/     /' <<<"$out" | grep -iE "unable|not found|error" | head -5
        bad=$((bad + 1))
    fi
done
if (( bad )); then
    echo ":: $bad package(s) can NOT be installed on a clean system"
    echo "   missing AUR deps: ./scripts/import-aur.sh <name>, then build + publish"
    exit 1
fi
echo ":: all ${#pkgs[@]} packages install fine on a clean system"
