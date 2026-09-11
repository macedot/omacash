#!/usr/bin/env bash
set -euo pipefail
ID="com.omacash.cashflow"
DEST="${HOME}/.config/omarchy/plugins/${ID}"
if [ -L "$DEST" ]; then
  rm "$DEST"
  echo "unlinked $DEST"
else
  echo "no symlink at $DEST" >&2
  exit 1
fi
omarchy restart shell || true
