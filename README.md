# OpenViking Memory Plugin for Claude Code

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Python 3.10+](https://img.shields.io/badge/Python-3.10+-green.svg)](https://www.python.org/)

**English** | [中文](README.zh-CN.md)

Automatically extract, store, and recall long-term memories across your Claude Code sessions using [OpenViking](https://github.com/volcengine/OpenViking).

## Features

- **Automatic session memory** -- every conversation turn is ingested and committed
- **Semantic recall** -- relevant memories are automatically injected into context on each prompt
- **On-demand recall** -- use `/memory-recall` to search historical memories at any time
- **Embedding support** -- uses SiliconFlow API for vector embeddings (BAAI/bge-large-zh-v1.5)
- **Local mode** -- works without a server using filesystem-based vector storage
- **HTTP mode** -- optionally connect to a remote openviking-server

## Prerequisites

- Python 3.10 or higher
- [uv](https://docs.astral.sh/uv/) (recommended) or pip
- SiliconFlow API key (for embeddings) -- [sign up here](https://siliconflow.cn)
- Claude Code CLI

## Quick Start

### One-line install

```bash
git clone https://github.com/Yu-Xiao-Sheng/openviking-memory-plugin.git
cd openviking-memory-plugin
SILICONFLOW_API_KEY=sk-your-key-here bash install.sh
```

### Or with explicit arguments

```bash
bash install.sh --api-key sk-your-key-here --project /path/to/your/project
```

### Then

1. Restart Claude Code
2. Open a project directory that contains `ov.conf`
3. Start chatting -- memories are captured automatically

## Configuration

### ov.conf

The installer generates `ov.conf` in your project root. You can also create it manually:

```bash
cp ov.conf.example ./ov.conf
# Edit ./ov.conf and replace YOUR_SILICONFLOW_API_KEY_HERE with your actual key
```

### Configuration options

| Option | Description | Default |
|--------|-------------|---------|
| `storage.workspace` | OpenViking workspace directory | `~/.openviking-workspace` |
| `storage.vectordb.path` | Vector database storage path | `~/.openviking/vectordb` |
| `embedding.dense.provider` | Embedding API provider | `openai` |
| `embedding.dense.model` | Embedding model name | `BAAI/bge-large-zh-v1.5` |
| `embedding.dense.api_base` | Embedding API base URL | `https://api.siliconflow.cn/v1` |
| `embedding.dense.dimension` | Embedding vector dimension | `1024` |
| `log.level` | Log verbosity | `INFO` |

## How It Works

### Hook Lifecycle

| Event | What happens |
|-------|-------------|
| `SessionStart` | Creates an OpenViking session, saves session state to `.openviking/memory/` |
| `UserPromptSubmit` | Searches for relevant memories, injects top-3 into context |
| `Stop` (async) | Parses last conversation turn, ingests into OpenViking session |
| `SessionEnd` | Commits session, triggers long-term memory extraction |

### Architecture

```
User Prompt
    |
    +--> [UserPromptSubmit hook] --> Recall relevant memories --> Inject into context
    |
    +--> Claude Code processes prompt (with memory context)
            |
            +--> [Stop hook] --> Extract turn from transcript --> Summarize --> Ingest to OpenViking
                    |
                    +--> [SessionEnd hook] --> Commit session --> OpenViking extracts long-term memories
```

### Memory Recall Skill

Use the `/memory-recall` slash command to search memories on demand:

```
/memory-recall What decisions did we make about the database schema?
```

## Install Options

```bash
# Install with default settings
SILICONFLOW_API_KEY=sk-xxx bash install.sh

# Install to a specific project
bash install.sh --api-key sk-xxx --project ~/my-project

# Use a custom venv location
bash install.sh --api-key sk-xxx --venv-path ~/.my-venv

# Skip dependency installation (use existing venv)
bash install.sh --skip-deps
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `python not found` | Ensure Python 3.10+ is installed. Run `install.sh` again. |
| `ov.conf not found` | Copy `ov.conf.example` to your project root as `ov.conf`. |
| `API key invalid` | Check your SiliconFlow API key in `ov.conf`. |
| Slow startup | First session initializes the embedding model. Subsequent starts are faster. |
| No memories recalled | Ensure you've had at least one full session (start + end) to extract memories. |

## Uninstall

```bash
cd openviking-memory-plugin
bash uninstall.sh
```

This removes plugin files, marketplace entries, and optionally the venv and workspace.

## License

[Apache-2.0](LICENSE)

## Credits

- [OpenViking](https://github.com/volcengine/OpenViking) by ByteDance/volcengine
- Built as a [Claude Code Plugin](https://docs.anthropic.com/en/docs/claude-code/plugins)
