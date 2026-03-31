#!/usr/bin/env bash
set -euo pipefail

info()  { printf '\033[0;34m[INFO]\033[0m  %s\n' "$1"; }
ok()    { printf '\033[0;32m[OK]\033[0m    %s\n' "$1"; }
warn()  { printf '\033[0;33m[WARN]\033[0m  %s\n' "$1"; }
err()   { printf '\033[0;31m[ERROR]\033[0m %s\n' "$1" >&2; }

confirm() {
  local prompt="$1"
  local response
  printf '\033[0;33m%s\033[0m [y/N] ' "$prompt"
  read -r response
  [[ "$response" =~ ^[Yy]$ ]]
}

PLUGIN_DIR="$HOME/.claude/plugins/openviking-memory"
MARKETPLACE_DIR="$HOME/.claude/plugins/local-marketplace"
MARKETPLACE_SYMLINK="$MARKETPLACE_DIR/openviking-memory"
SETTINGS="$HOME/.claude/settings.json"

echo ""
echo "  OpenViking Memory Plugin Uninstaller"
echo "  ====================================="
echo ""

# --- Step 1: Remove plugin files ---
if [[ -L "$MARKETPLACE_SYMLINK" ]]; then
  rm -f "$MARKETPLACE_SYMLINK"
  ok "Removed marketplace symlink"
elif [[ -e "$MARKETPLACE_SYMLINK" ]]; then
  rm -rf "$MARKETPLACE_SYMLINK"
  ok "Removed marketplace plugin directory"
else
  warn "Marketplace symlink not found (already removed)"
fi

if [[ -d "$PLUGIN_DIR" ]]; then
  rm -rf "$PLUGIN_DIR"
  ok "Removed plugin files: $PLUGIN_DIR"
else
  warn "Plugin directory not found: $PLUGIN_DIR"
fi

# --- Step 2: Clean marketplace.json if empty ---
MARKETPLACE_JSON="$MARKETPLACE_DIR/.claude-plugin/marketplace.json"
if [[ -f "$MARKETPLACE_JSON" ]]; then
  # Check if openviking-memory is the only plugin
  if command -v python3 >/dev/null 2>&1; then
    remaining=$(python3 -c "
import json
with open('$MARKETPLACE_JSON') as f:
    data = json.load(f)
plugins = [p for p in data.get('plugins', []) if p.get('name') != 'openviking-memory']
print(len(plugins))
" 2>/dev/null || echo "error")

    if [[ "$remaining" == "0" ]]; then
      rm -rf "$MARKETPLACE_DIR"
      ok "Removed local marketplace directory (was empty)"
    else
      # Remove just the openviking-memory entry
      python3 -c "
import json
with open('$MARKETPLACE_JSON') as f:
    data = json.load(f)
data['plugins'] = [p for p in data.get('plugins', []) if p.get('name') != 'openviking-memory']
with open('$MARKETPLACE_JSON', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
      ok "Removed openviking-memory from marketplace.json"
    fi
  fi
fi

# --- Step 3: Remove from settings.json ---
if [[ -f "$SETTINGS" ]]; then
  info "Updating settings.json..."
  cp "$SETTINGS" "$SETTINGS.bak"

  python3 -c "
import json, os

path = os.path.expanduser('~/.claude/settings.json')
with open(path) as f:
    data = json.load(f)

# Remove marketplace entry
markets = data.get('extraKnownMarketplaces', {})
markets.pop('openviking-memory-marketplace', None)
# Also clean up old 'local' key if it points to our marketplace
local_market = markets.get('local', {}).get('source', {})
if local_market.get('path', '').endswith('.claude/plugins/local-marketplace'):
    # Only remove if no other plugins use it
    pass  # Keep 'local' in case user has other plugins

# Disable plugin
plugins = data.get('enabledPlugins', {})
plugins.pop('openviking-memory@openviking-memory-marketplace', None)
plugins.pop('openviking-memory@local', None)

with open(path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
  ok "Plugin removed from settings.json (backup at settings.json.bak)"
fi

# --- Step 4: Optional cleanup ---
echo ""
if confirm "Remove Python venv at ~/.openviking-venv?"; then
  rm -rf "$HOME/.openviking-venv"
  ok "Removed venv"
fi

if confirm "Remove workspace at ~/.openviking-workspace? (contains all extracted memories)"; then
  rm -rf "$HOME/.openviking-workspace"
  ok "Removed workspace"
fi

echo ""
ok "Uninstall complete!"
echo ""
echo "  Note: ov.conf files in your project directories were NOT removed."
echo "  Remove them manually if desired."
echo ""
