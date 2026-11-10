#!/usr/bin/env bash
# Install the Laintas provider into OpenCode, then sign in.
# Downloads the plugin into OpenCode's local plugin directory and merges the
# provider entry into the global config. Safe to re-run; never touches
# other config keys. Requires: curl, node (OpenCode already needs node).
set -euo pipefail

PLUGIN_URL="https://raw.githubusercontent.com/lin7c/opencode-laintas/main/index.ts"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
CONFIG_FILE="$CONFIG_DIR/opencode.json"
PLUGIN_FILE="$CONFIG_DIR/plugin/laintas.ts"

mkdir -p "$CONFIG_DIR/plugin"
echo "Downloading the Laintas plugin..."
curl -fsSL "$PLUGIN_URL" -o "$PLUGIN_FILE"
[ -f "$CONFIG_FILE" ] || echo '{}' > "$CONFIG_FILE"

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
console.log('Laintas provider added to', path)
NODE

cat <<'EOF'

Done. Now sign in and pick a model:

  opencode auth login     # choose "Laintas" -> "Sign in with Laintas"
  opencode                # then /models to pick a Laintas model

Your Laintas account balance is what gets billed — there is no API key.
EOF
