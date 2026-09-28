#!/usr/bin/env bash
#
# install.sh — Russian localization installer for OpenHands Agent Canvas
# Repo: https://github.com/Ghostivity/Russian-openhands.json
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Ghostivity/Russian-openhands.json/main/install.sh | bash
#   ...or with automatic confirmation:  ... | bash -s -- --yes
#   ...or for a non-default install:    AGENT_CANVAS_FRONTEND=/path/to/frontend bash install.sh
#
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/Ghostivity/Russian-openhands.json/main/openhands.json"
FRONTEND="${AGENT_CANVAS_FRONTEND:-/opt/agent-canvas/frontend}"
LOCALES="$FRONTEND/locales"
ASSETS="$FRONTEND/assets"

ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    -y|--yes) ASSUME_YES=1 ;;
  esac
done

if [ -t 1 ]; then
  B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; N=$'\033[0m'
else
  B=""; G=""; Y=""; R=""; N=""
fi
msg()  { printf '%s\n' "  $1"; }
ok()   { printf '%s\n' "  ${G}✔${N} $1"; }
warn() { printf '%s\n' "  ${Y}⚠${N} $1"; }
err()  { printf '%s\n' "  ${R}✘${N} $1" >&2; }

# ask "<question>" — returns 0 on yes. Works with `curl | bash` by reading /dev/tty.
ask() {
  if [ "$ASSUME_YES" = "1" ]; then return 0; fi
  local reply=""
  if [ -t 0 ]; then
    printf '  %s [y/N] ' "$1"
    read -r reply </dev/tty 2>/dev/null || read -r reply || { echo ""; return 1; }
  elif [ -e /dev/tty ]; then
    printf '  %s [y/N] ' "$1" > /dev/tty
    if ! read -r reply < /dev/tty; then
      echo "" >&2
      warn "No answer could be read (non-interactive session) — patch NOT applied."
      msg  "Re-run with --yes to apply the patch automatically."
      return 1
    fi
  else
    warn "$1 — no interactive terminal detected; re-run with --yes to accept."
    return 1
  fi
  case "$reply" in y|Y|yes|YES|Yes|д|Д|да|ДА|Да) return 0 ;; *) return 1 ;; esac
}

as_root() {  # run a write command with sudo when needed
  if [ "$(id -u)" = "0" ]; then "$@"
  elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then sudo "$@"
  else return 125
  fi
}

can_write() { [ -w "$1" ] && return 0; [ "$(id -u)" = "0" ] && return 0
  command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; }

echo ""
echo "${B}Russian localization for OpenHands Agent Canvas${N}"
echo "https://github.com/Ghostivity/Russian-openhands.json"
echo "--------------------------------------------------------------"

# ---------------------------------------------------------------- step 1: detect
if [ ! -d "$LOCALES" ] || [ ! -d "$FRONTEND" ]; then
  err "Agent Canvas frontend not found at: $FRONTEND"
  msg  "If Agent Canvas is installed elsewhere, re-run with:"
  msg  "  AGENT_CANVAS_FRONTEND=/path/to/frontend bash install.sh"
  exit 1
fi
if [ ! -f "$LOCALES/en/openhands.json" ]; then
  err "Unexpected locales layout in $LOCALES (no en/openhands.json)."
  exit 1
fi
ok "Agent Canvas frontend found: $FRONTEND"

# ---------------------------------------------------------------- step 2: download
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

command -v curl >/dev/null 2>&1 || { err "curl is required"; exit 1; }
curl -fsSL "$REPO_RAW" -o "$TMP/openhands.json" || { err "Download failed: $REPO_RAW"; exit 1; }
[ -s "$TMP/openhands.json" ] || { err "Downloaded file is empty"; exit 1; }

if command -v python3 >/dev/null 2>&1; then
  python3 -m json.tool "$TMP/openhands.json" >/dev/null 2>&1 \
    || { err "Downloaded file is not valid JSON"; exit 1; }
  RU_KEYS=$(python3 -c "import json;print(len(json.load(open('$TMP/openhands.json'))))")
  EN_KEYS=$(python3 -c "import json;print(len(json.load(open('$LOCALES/en/openhands.json'))))")
  MISSING=$(python3 - "$LOCALES/en/openhands.json" "$TMP/openhands.json" <<'PY'
import json, sys
en = set(json.load(open(sys.argv[1])))
ru = set(json.load(open(sys.argv[2])))
print(len(en - ru))
PY
)
  ok "Translation downloaded and valid: $RU_KEYS keys (en has $EN_KEYS, missing: $MISSING)"
  if [ "$MISSING" != "0" ]; then
    warn "Version drift detected — untranslated strings will fall back to English."
  fi
else
  warn "python3 not found — skipping JSON validation (continuing anyway)."
fi

TARGET_DIR="$LOCALES/ru"
if [ -f "$TARGET_DIR/openhands.json" ] && cmp -s "$TMP/openhands.json" "$TARGET_DIR/openhands.json"; then
  ok "Translation already installed and up to date: $TARGET_DIR/openhands.json"
else
  if ! can_write "$LOCALES"; then
    err "No write access to $LOCALES. Re-run with root privileges:"
    msg  "  curl -fsSL https://raw.githubusercontent.com/Ghostivity/Russian-openhands.json/main/install.sh | sudo bash"
    exit 1
  fi
  as_root mkdir -p "$TARGET_DIR"
  as_root cp "$TMP/openhands.json" "$TARGET_DIR/.openhands.json.tmp"
  as_root mv -f "$TARGET_DIR/.openhands.json.tmp" "$TARGET_DIR/openhands.json"
  ok "Translation installed: $TARGET_DIR/openhands.json"
fi

# ---------------------------------------------------------------- step 3: patch bundle
echo ""
echo "${B}Step 2 of 2:${N} register the language in the frontend bundle"
echo "  (without this, «Русский» will not appear in the language switcher)"

BUNDLE="$(grep -rl 'value:`uk`' "$ASSETS" 2>/dev/null | head -1 || true)"
if [ -z "$BUNDLE" ]; then
  warn "Could not locate the JS bundle containing the language list in $ASSETS."
  msg  "The translation file is installed, but you must add ru to the language list"
  msg  "manually — see the repository README, step 3."
  exit 0
fi

if grep -q 'value:`ru`' "$BUNDLE"; then
  ok "Bundle already contains «Русский» — nothing to patch: $BUNDLE"
else
  OLD='{label:`Українська`,value:`uk`}]'
  NEW='{label:`Українська`,value:`uk`},{label:`Русский`,value:`ru`}]'

  COUNT=$(python3 - "$BUNDLE" "$OLD" <<'PY'
import sys
src = open(sys.argv[1], encoding="utf-8").read()
print(src.count(sys.argv[2]))
PY
)
  echo ""
  echo "  Proposed change:"
  echo "    ${B}file:${N} $BUNDLE"
  echo "    ${B}find:${N}    $OLD"
  echo "    ${B}replace:${N} $NEW"
  echo "    ${B}matches found:${N} $COUNT"

  if [ "$COUNT" != "1" ]; then
    warn "Pattern check failed ($COUNT matches, expected exactly 1)."
    msg  "Your Agent Canvas build differs from the expected one — patch NOT applied."
    msg  "Add the language entry manually inside $BUNDLE, or open an issue at"
    msg  "https://github.com/Ghostivity/Russian-openhands.json/issues with your version."
    exit 0
  fi

  if ! as_root test -w "$BUNDLE"; then
    err "No write access to the bundle. Re-run with root privileges (sudo)."
    exit 1
  fi

  echo ""
  if ask "Apply this change?"; then
    BACKUP="$BUNDLE.bak-$(date +%Y%m%d%H%M%S)"
    as_root cp "$BUNDLE" "$BACKUP"
    python3 - "$BUNDLE" "$OLD" "$NEW" <<'PY'
import sys
path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
src = open(path, encoding="utf-8").read()
assert src.count(old) == 1
open(path, "w", encoding="utf-8").write(src.replace(old, new))
PY
    ok "Patch applied. Backup saved: $BACKUP"
  else
    warn "Patch skipped by user. The translation file is installed;"
    msg  "«Русский» will appear in the switcher only after this patch is applied."
    exit 0
  fi
fi

# ---------------------------------------------------------------- done
echo ""
ok "All done! Switch the language either way:"
msg  "  • Settings → Application → Language → «Русский»"
msg  "  • or open: http://<your-host>/canvas/?lng=ru"
msg  "  Then hard-refresh the page (Ctrl+Shift+R)."
echo ""
