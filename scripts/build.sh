#!/usr/bin/env bash
# vitra-repo build script
# (c) 2026 34 & Claude - GPL-3.0
# Baut alle (oder ausgewaehlte) Pakete aus pkgs/ und erzeugt die pacman-Datenbank.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="x86_64"
OUT="$ROOT/out/$ARCH"
REPO="vitra"
mkdir -p "$OUT"

sign_args=()
if [[ -n "${GPGKEY:-}" ]]; then
  sign_args=(--sign --key "$GPGKEY")
  echo ":: Signiere mit Key $GPGKEY"
fi

if [[ $# -gt 0 ]]; then
  pkgs=("$@")
else
  mapfile -t pkgs < <(find "$ROOT/pkgs" -mindepth 2 -maxdepth 2 -name PKGBUILD -printf '%h\n' | xargs -rn1 basename | sort)
fi

if [[ ${#pkgs[@]} -eq 0 ]]; then
  echo ":: Keine Pakete in pkgs/ gefunden."
  exit 0
fi

for p in "${pkgs[@]}"; do
  dir="$ROOT/pkgs/$p"
  [[ -f "$dir/PKGBUILD" ]] || { echo "!! $p: kein PKGBUILD"; exit 1; }
  echo ":: Baue $p"
  (cd "$dir" && PKGDEST="$OUT" makepkg -sf --noconfirm --cleanbuild "${sign_args[@]}")
done

echo ":: Erzeuge Datenbank"
cd "$OUT"
repo_args=(--remove)
[[ -n "${GPGKEY:-}" ]] && repo_args+=(--sign --key "$GPGKEY")
repo-add "${repo_args[@]}" "$REPO.db.tar.gz" ./*.pkg.tar.zst

# GitHub-Releases koennen keine Symlinks: echte Kopien statt vitra.db -> vitra.db.tar.gz
for n in db files; do
  rm -f "$REPO.$n"
  cp -L "$REPO.$n.tar.gz" "$REPO.$n"
  [[ -f "$REPO.$n.tar.gz.sig" ]] && cp -L "$REPO.$n.tar.gz.sig" "$REPO.$n.sig"
done

echo ":: Erzeuge packages.json fuer vitra-web"
python3 - "$OUT" "$ARCH" <<'PY'
import json, os, subprocess, sys, time
out, arch = sys.argv[1], sys.argv[2]
pkgs = []
for f in sorted(os.listdir(out)):
    if not f.endswith(".pkg.tar.zst"):
        continue
    info = subprocess.run(["bsdtar", "-xOf", os.path.join(out, f), ".PKGINFO"],
                          capture_output=True, text=True).stdout
    d = {"depends": [], "license": []}
    for line in info.splitlines():
        if " = " not in line or line.startswith("#"):
            continue
        k, v = line.split(" = ", 1)
        if k in ("depend",):
            d["depends"].append(v)
        elif k == "license":
            d["license"].append(v)
        elif k in ("pkgname", "pkgver", "pkgdesc", "url", "builddate", "size", "packager"):
            d[k] = v
    d["file"] = f
    d["filesize"] = os.path.getsize(os.path.join(out, f))
    d["signed"] = os.path.exists(os.path.join(out, f + ".sig"))
    pkgs.append(d)
json.dump({"repo": "vitra", "arch": arch, "generated": int(time.time()), "packages": pkgs},
          open(os.path.join(out, "packages.json"), "w"), indent=2)
print(f":: {len(pkgs)} Pakete in packages.json")
PY

echo ":: Fertig. Ausgabe: $OUT"
