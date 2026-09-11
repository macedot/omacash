#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ID="com.omacash.cashflow"
DEST="${HOME}/.config/omarchy/plugins/${ID}"
mkdir -p "$(dirname "$DEST")"
if [ -e "$DEST" ] && [ ! -L "$DEST" ]; then
  mv "$DEST" "${DEST}.bak.$(date +%s)"
fi
ln -sfn "$ROOT" "$DEST"
omarchy plugin enable "$ID" --section right || true
omarchy restart shell
echo "linked $DEST -> $ROOT"
