#!/usr/bin/env bash
# Empacota cada skill em dist/<nome>.zip, pronto para upload no Claude
# (Settings → Capabilities → Skills → Upload skill).
# Packs each skill into dist/<name>.zip, ready to upload to Claude.
#
# Uso / Usage: scripts/package-skill.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="${ROOT}/dist"
mkdir -p "$DIST"

for dir in "${ROOT}"/skills/*/; do
  name="$(basename "$dir")"
  out="${DIST}/${name}.zip"
  rm -f "$out"
  (cd "${ROOT}/skills" && zip -qr "$out" "$name" -x '*.DS_Store')
  echo "✔ ${out#"${ROOT}"/}"
  unzip -l "$out" | tail -n +4 | head -n -2 | awk '{print "    " $4}'
done
