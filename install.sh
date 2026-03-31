#!/usr/bin/env bash
set -euo pipefail

# --- Color helpers ---
info()  { printf '\033[0;34m[INFO]\033[0m  %s\n' "$1"; }
ok()    { printf '\033[0;32m[OK]\033[0m    %s\n' "$1"; }
warn()  { printf '\033[0;33m[WARN]\033[0m  %s\n' "$1"; }
err()   { printf '\033[0;31m[ERROR]\033[0m %s\n' "$1" >&2; }

usage() {
  cat <<'USAGE'
Usage: install.sh [OPTIONS]

Install OpenViking memory plugin for Claude Code.

Options:
  --api-key KEY       SiliconFlow API key (required, or set SILICONFLOW_API_KEY env var)
  --venv-path PATH    Custom Python venv path (default: ~/.openviking-venv)
  --project PATH      Project directory for ov.conf (default: current directory)
  --skip-deps         Skip OpenViking installation (use existing venv)
  -h, --help          Show this help message

Examples:
  SILICONFLOW_API_KEY=sk-xxx bash install.sh
  bash install.sh --api-key sk-xxx --project ~/my-project
USAGE
  exit 0
}

# --- Parse arguments ---
API_KEY=""
VENV_PATH="$HOME/.openviking-venv"
PROJECT_DIR="$(pwd)"
SKIP_DEPS=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --api-key)    API_KEY="$2"; shift 2 ;;
    --venv-path)  VENV_PATH="$2"; shift 2 ;;
    --project)    PROJECT_DIR="$2"; shift 2 ;;
    --skip-deps)  SKIP_DEPS=true; shift ;;
    -h|--help)    usage ;;
    *) err "Unknown option: $1"; exit 1 ;;
  esac
done

# API key from env if not provided via argument
if [[ -z "$API_KEY" ]]; then
  API_KEY="${SILICONFLOW_API_KEY:-}"
fi

if [[ -z "$API_KEY" ]]; then
  err "No API key provided. Use --api-key or set SILICONFLOW_API_KEY env var."
  err "Get your API key at: https://siliconflow.cn"
  exit 1
fi

if [[ "$API_KEY" == YOUR_SILICONFLOW_API_KEY_HERE ]]; then
  err "Please replace the placeholder API key with your actual SiliconFlow API key."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "  OpenViking Memory Plugin Installer"
echo "  ==================================="
echo ""

# --- Step 1: Preflight checks ---
info "Checking prerequisites..."

# Check Python
PYTHON_CMD=""
for cmd in python3 python; do
  if command -v "$cmd" >/dev/null 2>&1; then
    py_version=$("$cmd" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || echo "0.0")
    py_major="${py_version%%.*}"
    py_minor="${py_version#*.}"
    if [[ "$py_major" -ge 3 ]] && [[ "$py_minor" -ge 10 ]]; then
      PYTHON_CMD="$cmd"
      break
    fi
  fi
done

if [[ -z "$PYTHON_CMD" ]]; then
  err "Python 3.10+ is required but not found. Install it first."
  exit 1
fi
ok "Python: $($PYTHON_CMD --version 2>&1)"

# Check/install uv
UV_CMD=""
for candidate in "$HOME/.local/bin/uv" "$HOME/.cargo/bin/uv" "$(command -v uv 2>/dev/null)"; do
  if [[ -n "$candidate" ]] && [[ -x "$candidate" ]]; then
    UV_CMD="$candidate"
    break
  fi
done

if [[ -z "$UV_CMD" ]]; then
  warn "uv not found. Attempting to install..."
  if curl -LsSf https://astral.sh/uv/install.sh 2>/dev/null | sh >/dev/null 2>&1; then
    UV_CMD="$HOME/.local/bin/uv"
    if [[ -x "$UV_CMD" ]]; then
      ok "uv installed: $($UV_CMD --version 2>&1)"
    else
      UV_CMD=""
    fi
  fi
  if [[ -z "$UV_CMD" ]]; then
    warn "uv install failed. Will use python3 -m venv instead."
  fi
else
  ok "uv: $($UV_CMD --version 2>&1)"
fi

# Check claude
if command -v claude >/dev/null 2>&1; then
  ok "Claude Code CLI found"
else
  warn "Claude Code CLI not found in PATH. Plugin hooks use claude for summarization."
fi

echo ""

# --- Step 2: Create venv and install openviking ---
if [[ "$SKIP_DEPS" == true ]]; then
  if [[ ! -x "$VENV_PATH/bin/python3" ]]; then
    err "Skip-deps requested but venv not found at: $VENV_PATH"
    exit 1
  fi
  ok "Using existing venv: $VENV_PATH"
else
  if [[ -d "$VENV_PATH" ]]; then
    warn "Venv already exists at: $VENV_PATH (skipping creation)"
  else
    info "Creating Python venv at: $VENV_PATH"
    if [[ -n "$UV_CMD" ]]; then
      "$UV_CMD" venv "$VENV_PATH" --python 3.12 2>/dev/null || "$UV_CMD" venv "$VENV_PATH" 2>/dev/null
    else
      "$PYTHON_CMD" -m venv "$VENV_PATH"
    fi
    ok "Venv created"
  fi

  info "Installing openviking package..."
  if [[ -n "$UV_CMD" ]]; then
    "$UV_CMD" pip install --python "$VENV_PATH/bin/python3" openviking 2>&1 | tail -1
  else
    "$VENV_PATH/bin/python3" -m pip install --quiet openviking 2>&1 | tail -1
  fi

  # Verify installation
  if "$VENV_PATH/bin/python3" -c "from openviking import SyncOpenViking" 2>/dev/null; then
    ov_version=$("$VENV_PATH/bin/python3" -c "import openviking; print(openviking.__version__)" 2>/dev/null || echo "unknown")
    ok "OpenViking $ov_version installed"
  else
    err "OpenViking installation verification failed. Try running manually:"
    err "  $VENV_PATH/bin/python3 -m pip install openviking"
    exit 1
  fi
fi

echo ""

# --- Step 3: Create workspace ---
mkdir -p "$HOME/.openviking-workspace"
ok "Workspace: $HOME/.openviking-workspace"

# --- Step 4: Generate ov.conf ---
OV_CONF_TARGET="$PROJECT_DIR/ov.conf"
if [[ -f "$OV_CONF_TARGET" ]]; then
  warn "ov.conf already exists at $OV_CONF_TARGET -- skipping (not overwriting)"
else
  if [[ -f "$SCRIPT_DIR/ov.conf.example" ]]; then
    sed "s|YOUR_SILICONFLOW_API_KEY_HERE|$API_KEY|" "$SCRIPT_DIR/ov.conf.example" > "$OV_CONF_TARGET"
    chmod 600 "$OV_CONF_TARGET"
    ok "Created $OV_CONF_TARGET (chmod 600)"
  else
    err "ov.conf.example not found at $SCRIPT_DIR. Skipping config creation."
    info "Create ov.conf manually in your project root. See README for details."
  fi
fi

# --- Step 5: Install plugin files ---
PLUGIN_DIR="$HOME/.claude/plugins/openviking-memory"
MARKETPLACE_DIR="$HOME/.claude/plugins/local-marketplace"

info "Installing plugin files to: $PLUGIN_DIR"
mkdir -p "$PLUGIN_DIR"
for item in .claude-plugin hooks scripts skills; do
  if [[ -e "$SCRIPT_DIR/$item" ]]; then
    cp -r "$SCRIPT_DIR/$item" "$PLUGIN_DIR/"
  fi
done
ok "Plugin files installed"

# --- Step 6: Set up marketplace ---
mkdir -p "$MARKETPLACE_DIR/.claude-plugin"
MARKETPLACE_JSON="$MARKETPLACE_DIR/.claude-plugin/marketplace.json"

# Symlink plugin into marketplace
ln -sfn "$PLUGIN_DIR" "$MARKETPLACE_DIR/openviking-memory"

# Create or merge marketplace.json
if [[ -f "$MARKETPLACE_JSON" ]]; then
  info "Merging into existing marketplace.json"
  "$PYTHON_CMD" -c "
import json, os

path = '$MARKETPLACE_JSON'
with open(path) as f:
    data = json.load(f)

plugins = data.setdefault('plugins', [])
plugin_names = [p.get('name', '') for p in plugins]

if 'openviking-memory' not in plugin_names:
    plugins.append({
        'name': 'openviking-memory',
        'description': 'OpenViking memory plugin for Claude Code',
        'author': {'name': 'Yu-Xiao-Sheng'},
        'homepage': 'https://github.com/Yu-Xiao-Sheng/openviking-memory-plugin',
        'source': './openviking-memory'
    })

with open(path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
else
  info "Creating marketplace.json"
  cat > "$MARKETPLACE_JSON" << 'MPJSON'
{
  "name": "local",
  "owner": { "name": "local" },
  "metadata": {
    "description": "Local marketplace for manually installed plugins",
    "version": "1.0.0"
  },
  "plugins": [
    {
      "name": "openviking-memory",
      "description": "OpenViking memory plugin for Claude Code - provides automatic session memory extraction and semantic recall",
      "author": { "name": "Yu-Xiao-Sheng" },
      "homepage": "https://github.com/Yu-Xiao-Sheng/openviking-memory-plugin",
      "source": "./openviking-memory"
    }
  ]
}
MPJSON
fi
ok "Marketplace configured"

# --- Step 7: Register in settings.json ---
SETTINGS="$HOME/.claude/settings.json"

if [[ ! -f "$SETTINGS" ]]; then
  warn "settings.json not found at $SETTINGS. Skipping auto-registration."
  warn "You will need to manually add the marketplace and enable the plugin."
else
  info "Registering plugin in settings.json..."

  # Backup settings.json
  cp "$SETTINGS" "$SETTINGS.bak"

  "$PYTHON_CMD" -c "
import json, os

path = os.path.expanduser('~/.claude/settings.json')
with open(path) as f:
    data = json.load(f)

# Register marketplace
data.setdefault('extraKnownMarketplaces', {})
data['extraKnownMarketplaces']['openviking-memory-marketplace'] = {
    'source': {
        'source': 'directory',
        'path': os.path.expanduser('~/.claude/plugins/local-marketplace')
    }
}

# Enable plugin
data.setdefault('enabledPlugins', {})
data['enabledPlugins']['openviking-memory@openviking-memory-marketplace'] = True

with open(path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
  ok "Plugin registered (backup saved at settings.json.bak)"
fi

# --- Step 8: Summary ---
echo ""
echo "========================================"
echo "  Installation Complete!"
echo "========================================"
echo ""
echo "  Python venv:    $VENV_PATH"
if [[ -x "$VENV_PATH/bin/python3" ]]; then
  echo "  OpenViking:     $($VENV_PATH/bin/python3 -c 'import openviking; print(openviking.__version__)' 2>/dev/null || echo 'unknown')"
fi
echo "  Config:         $OV_CONF_TARGET"
echo "  Plugin:         $PLUGIN_DIR"
echo "  Marketplace:    $MARKETPLACE_DIR"
echo ""
echo "  Next steps:"
echo "    1. Restart Claude Code"
echo "    2. Open a project directory containing ov.conf"
echo "    3. Start chatting -- memories are captured automatically"
echo ""
echo "  To uninstall:  bash $SCRIPT_DIR/uninstall.sh"
echo ""
