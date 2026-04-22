#!/usr/bin/env bash
# Auto-migrate openviking data directory from project dir to ~/.openviking/vectordb
# Detects if ./data is an openviking data dir, migrates it, and replaces with symlink

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${0}}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Target: new unified location
NEW_VDB_PATH="$HOME/.openviking/vectordb"

# Check if ./data exists in project dir
if [[ ! -d "$PROJECT_DIR/data" ]]; then
  # No ./data, nothing to migrate
  exit 0
fi

# Check if ./data is an openviking data directory (contains vectordb/viking/_system subdirs)
if [[ ! -d "$PROJECT_DIR/data/vectordb" ]] && [[ ! -d "$PROJECT_DIR/data/viking" ]] && [[ ! -d "$PROJECT_DIR/data/_system" ]]; then
  # ./data exists but doesn't look like openviking data - leave it alone
  exit 0
fi

# It's an openviking data dir - check if already migrated or needs migration
if [[ -L "$PROJECT_DIR/data" ]]; then
  # Already a symlink, already migrated
  exit 0
fi

# Ensure new target directory exists
mkdir -p "$(dirname "$NEW_VDB_PATH")"

# Check if new location already has data
if [[ -d "$NEW_VDB_PATH" ]] && [[ "$(ls -A "$NEW_VDB_PATH" 2>/dev/null)" ]]; then
  # New location already has data - we need to merge
  # For now, just replace old data with symlink (user can handle merge manually if needed)
  echo "[openviking-memory] WARNING: $NEW_VDB_PATH already exists, cannot auto-migrate (manual merge required)" >&2
  exit 0
fi

# Perform migration
if command -v mv >/dev/null 2>&1; then
  # Move data to new location
  mv "$PROJECT_DIR/data" "$NEW_VDB_PATH"

  # Create symlink to maintain compatibility
  ln -s "$NEW_VDB_PATH" "$PROJECT_DIR/data"

  echo "[openviking-memory] migrated ./data -> $NEW_VDB_PATH"
fi
