#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"

# Validate a copy without node_modules: npm's .bin tree is symlinks, and
# omarchy-plugin-validate refuses any symlink in the plugin folder.
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
if command -v rsync >/dev/null; then
  rsync -a --exclude node_modules --exclude .git "$ROOT/" "$STAGE/"
else
  cp -a "$ROOT/." "$STAGE/"
  rm -rf "$STAGE/node_modules" "$STAGE/.git"
fi
omarchy plugin validate "$STAGE"

if ! command -v npm >/dev/null; then
  echo "npm is required for engine tests" >&2
  exit 1
fi
(cd "$ROOT" && npm test)

if command -v qmllint >/dev/null; then
  qmllint -I "${OMARCHY_PATH}/shell" "$ROOT"/ui/*.qml
else
  echo "qmllint not found; skipped"
fi

# Fail if UI or engine grow a network API. Docs may mention https://.
if grep -RInE 'XMLHttpRequest|WebSocket|import QtNetwork|QNetworkAccess' "$ROOT/ui"; then
  echo "network API found in ui/" >&2
  exit 1
fi

echo "ok"
