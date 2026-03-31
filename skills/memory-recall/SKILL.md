---
name: memory-recall
description: Recall relevant long-term memories extracted by OpenViking Session memory. Use when the user asks about past decisions, prior fixes, historical context, or what was done in earlier sessions.
context: fork
allowed-tools: Bash
---

You are a memory retrieval sub-agent for OpenViking memory.

## Goal
Find the most relevant historical memories for: $ARGUMENTS

## Steps

1. Resolve the memory bridge script path.
```bash
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
STATE_FILE="$PROJECT_DIR/.openviking/memory/session_state.json"
BRIDGE="${CLAUDE_PLUGIN_ROOT:-}/scripts/ov_memory.py"

# Use the openviking venv Python if available
OV_VENV=""
for candidate in "$HOME/.openviking-venv" "$HOME/.local/share/openviking-venv"; do
  if [[ -x "$candidate/bin/python3" ]]; then
    OV_VENV="$candidate"
    break
  fi
done

if [[ -n "$OV_VENV" ]]; then
  PYTHON_BIN="$OV_VENV/bin/python3"
else
  PYTHON_BIN="python3"
fi
```

2. Run memory recall search.
```bash
$PYTHON_BIN "$BRIDGE" --project-dir "$PROJECT_DIR" --state-file "$STATE_FILE" recall --query "$ARGUMENTS" --top-k 5
```

3. Evaluate results and keep only truly relevant memories.
4. Return a concise curated summary to the main agent.

## Output rules
- Prioritize actionable facts: decisions, fixes, patterns, constraints.
- Include source URIs for traceability.
- If nothing useful appears, respond exactly: `No relevant memories found.`
