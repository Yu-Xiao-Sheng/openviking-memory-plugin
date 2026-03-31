#!/usr/bin/env bash
# UserPromptSubmit hook: auto-recall relevant memories and inject into context.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

PROMPT="$(_json_val "$INPUT" "prompt" "")"
if [[ -z "$PROMPT" || ${#PROMPT} -lt 10 ]]; then
  echo '{}'
  exit 0
fi

# Skip recall for slash commands (skills, plugins, built-in commands)
if [[ "$PROMPT" == /* ]]; then
  echo '{}'
  exit 0
fi

if [[ ! -f "$OV_CONF" || ! -f "$STATE_FILE" ]]; then
  echo '{}'
  exit 0
fi

# Run memory recall and inject results into systemMessage
RECALL_OUT="$(run_bridge recall --query "$PROMPT" --top-k 3 2>/dev/null || true)"

if [[ -z "$RECALL_OUT" || "$RECALL_OUT" == "No relevant memories found."* || "$RECALL_OUT" == "Memory unavailable"* ]]; then
  echo '{}'
  exit 0
fi

# Escape for JSON: backslash first, then double quotes, then newlines
ESCAPED="$(printf '%s' "$RECALL_OUT" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')"
echo "{\"systemMessage\":\"[openviking-memory] Relevant context:\\n${ESCAPED}\"}"
