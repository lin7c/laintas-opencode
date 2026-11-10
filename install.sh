#!/usr/bin/env bash
# Install the Laintas provider into OpenCode's global config, then sign in.
# Safe to re-run: it merges into opencode.json and never touches other keys.
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
CONFIG_FILE="$CONFIG_DIR/opencode.json"
mkdir -p "$CONFIG_DIR"
[ -f "$CONFIG_FILE" ] || echo '{}' > "$CONFIG_FILE"

CONFIG_FILE="$CONFIG_FILE" node <<'NODE'
const fs = require('fs')
const path = process.env.CONFIG_FILE
const cfg = JSON.parse(fs.readFileSync(path, 'utf8'))
cfg.$schema = cfg.$schema || 'https://opencode.ai/config.json'
cfg.plugin = Array.isArray(cfg.plugin) ? cfg.plugin : []
if (!cfg.plugin.includes('opencode-laintas')) cfg.plugin.push('opencode-laintas')
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
