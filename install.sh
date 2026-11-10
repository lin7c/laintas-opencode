#!/usr/bin/env bash
# Laintas for OpenCode — one-command install (macOS / Linux).
#
# 1. If OpenCode is not installed, installs the official OpenCode binary
#    (pinned version, downloaded from the OpenCode project's own GitHub
#    releases — OpenCode is MIT-licensed, see https://github.com/sst/opencode).
# 2. Installs the Laintas plugin into OpenCode's local plugin directory.
# 3. Merges the Laintas provider entry into the global OpenCode config.
#
# Safe to re-run: existing config keys are never touched.
set -euo pipefail

OPENCODE_VERSION="1.19.5"
PLUGIN_URL="https://raw.githubusercontent.com/lin7c/opencode-laintas/main/index.ts"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
CONFIG_FILE="$CONFIG_DIR/opencode.json"
PLUGIN_FILE="$CONFIG_DIR/plugin/laintas.ts"

# ---------- 1. OpenCode itself ----------
if command -v opencode >/dev/null 2>&1; then
  echo "OpenCode found: $(opencode --version 2>/dev/null || echo present)"
else
  OS="$(uname -s)"; ARCH="$(uname -m)"
  case "$OS" in
    Darwin) PLATFORM="darwin" ;;
    Linux)  PLATFORM="linux" ;;
    *) echo "Unsupported OS: $OS — on Windows use install.ps1 instead."; exit 1 ;;
  esac
  case "$ARCH" in
    arm64|aarch64) A="arm64" ;;
    x86_64|amd64)  A="x64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
  esac
  echo "Installing OpenCode $OPENCODE_VERSION ($PLATFORM-$A)..."
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  mkdir -p "$BIN_DIR"
  if [ "$PLATFORM" = "darwin" ]; then
    curl -fsSL "https://github.com/sst/opencode/releases/download/v$OPENCODE_VERSION/opencode-darwin-$A.zip" -o "$TMP/oc.zip"
    unzip -qo "$TMP/oc.zip" -d "$TMP"
  else
    # Prefer the glibc build; fall back to musl on Alpine-style systems.
    if ldd --version 2>&1 | grep -qi musl; then SUFFIX="-musl"; else SUFFIX=""; fi
    curl -fsSL "https://github.com/sst/opencode/releases/download/v$OPENCODE_VERSION/opencode-linux-$A$SUFFIX.tar.gz" -o "$TMP/oc.tar.gz"
    tar -xzf "$TMP/oc.tar.gz" -C "$TMP"
  fi
  install -m 755 "$TMP/opencode" "$BIN_DIR/opencode"
  # Very old x86_64 CPUs need the baseline build; swap automatically.
  if ! "$BIN_DIR/opencode" --version >/dev/null 2>&1 && [ "$A" = "x64" ]; then
    echo "Standard build does not run on this CPU; fetching the baseline build..."
    if [ "$PLATFORM" = "darwin" ]; then
      curl -fsSL "https://github.com/sst/opencode/releases/download/v$OPENCODE_VERSION/opencode-darwin-x64-baseline.zip" -o "$TMP/ocb.zip"
      unzip -qo "$TMP/ocb.zip" -d "$TMP"
    else
      curl -fsSL "https://github.com/sst/opencode/releases/download/v$OPENCODE_VERSION/opencode-linux-x64-baseline$SUFFIX.tar.gz" -o "$TMP/ocb.tar.gz"
      tar -xzf "$TMP/ocb.tar.gz" -C "$TMP"
    fi
    install -m 755 "$TMP/opencode" "$BIN_DIR/opencode"
  fi
  echo "OpenCode installed: $("$BIN_DIR/opencode" --version)"
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
      RC="$HOME/.bashrc"; [ "$(basename "${SHELL:-}")" = "zsh" ] && RC="$HOME/.zshrc"
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC"
      echo "Added ~/.local/bin to PATH in $RC — open a new terminal before running opencode."
      ;;
  esac
fi

# ---------- 2. Laintas plugin ----------
mkdir -p "$CONFIG_DIR/plugin"
echo "Installing the Laintas plugin..."
curl -fsSL "$PLUGIN_URL" -o "$PLUGIN_FILE"
[ -f "$CONFIG_FILE" ] || echo '{}' > "$CONFIG_FILE"

# ---------- 3. Provider config (merge, never overwrite other keys) ----------
if command -v node >/dev/null 2>&1; then
  CONFIG_FILE="$CONFIG_FILE" node <<'NODE'
const fs = require('fs')
const path = process.env.CONFIG_FILE
const cfg = JSON.parse(fs.readFileSync(path, 'utf8'))
cfg.$schema = cfg.$schema || 'https://opencode.ai/config.json'
cfg.provider = cfg.provider || {}
cfg.provider.laintas = {
  npm: '@ai-sdk/openai-compatible',
  name: 'Laintas',
  options: { baseURL: 'https://laintas.com/v1' },
  models: {},
}
fs.writeFileSync(path, JSON.stringify(cfg, null, 2) + '\n')
NODE
elif command -v python3 >/dev/null 2>&1; then
  CONFIG_FILE="$CONFIG_FILE" python3 <<'PY'
import json, os
path = os.environ['CONFIG_FILE']
cfg = json.load(open(path))
cfg.setdefault('$schema', 'https://opencode.ai/config.json')
cfg.setdefault('provider', {})['laintas'] = {
    'npm': '@ai-sdk/openai-compatible', 'name': 'Laintas',
    'options': {'baseURL': 'https://laintas.com/v1'}, 'models': {},
}
json.dump(cfg, open(path, 'w'), indent=2)
open(path, 'a').write('\n')
PY
elif ! grep -q '"laintas"' "$CONFIG_FILE"; then
  # Fresh config and no JSON tool available: write the full entry directly.
  cat > "$CONFIG_FILE" <<'JSON'
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "laintas": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Laintas",
      "options": { "baseURL": "https://laintas.com/v1" },
      "models": {}
    }
  }
}
JSON
else
  echo "Note: could not merge the provider entry automatically."
  echo "Add the provider.laintas entry from the README to $CONFIG_FILE by hand."
fi
echo "Laintas provider configured in $CONFIG_FILE"

cat <<'EOF'

Done. Now sign in and pick a model:

  opencode auth login     # choose "Laintas" -> "Sign in with Laintas"
  opencode                # then /models to pick a Laintas model

Your Laintas account balance is what gets billed — there is no API key.
EOF
