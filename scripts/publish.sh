#!/usr/bin/env bash
# vitra-repo publish script
# (c) 2026 34 & Claude - GPL-3.0
# Laedt out/x86_64/ ins GitHub-Release "x86_64" hoch und kopiert packages.json nach vitra-web.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="x86_64"
OUT="$ROOT/out/$ARCH"
GH_REPO="${GH_REPO:-femboyss/vitra-repo}"
WEB="${WEB:-$ROOT/../vitra-web}"

command -v gh >/dev/null || { echo "!! gh fehlt: sudo pacman -S github-cli && gh auth login"; exit 1; }
[[ -f "$OUT/vitra.db" ]] || { echo "!! Erst ./scripts/build.sh ausfuehren"; exit 1; }

if ! gh release view "$ARCH" -R "$GH_REPO" >/dev/null 2>&1; then
  echo ":: Lege Release $ARCH an"
  gh release create "$ARCH" -R "$GH_REPO" --title "Vitra packages ($ARCH)" \
    --notes "Rolling package release. pacman: Server = https://github.com/$GH_REPO/releases/download/\$arch" --latest=false
fi

cd "$OUT"
mapfile -t local_files < <(ls -1 vitra.db vitra.db.sig vitra.files vitra.files.sig *.pkg.tar.zst *.pkg.tar.zst.sig packages.json 2>/dev/null || true)

echo ":: Lade ${#local_files[@]} Dateien hoch"
gh release upload "$ARCH" -R "$GH_REPO" --clobber "${local_files[@]}"

echo ":: Entferne alte Dateien aus dem Release"
mapfile -t remote < <(gh release view "$ARCH" -R "$GH_REPO" --json assets -q '.assets[].name')
for r in "${remote[@]}"; do
  keep=0
  for l in "${local_files[@]}"; do [[ "$r" == "$l" ]] && keep=1 && break; done
  if [[ $keep -eq 0 ]]; then
    echo "   - $r"
    gh release delete-asset "$ARCH" "$r" -R "$GH_REPO" -y
  fi
done

if [[ -d "$WEB" ]]; then
  cp packages.json "$WEB/packages.json"
  echo ":: packages.json nach $WEB kopiert (dort committen + pushen)"
fi
echo ":: Fertig."
