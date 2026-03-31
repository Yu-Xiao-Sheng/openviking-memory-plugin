# OpenViking Memory Plugin for Claude Code

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Python 3.10+](https://img.shields.io/badge/Python-3.10%2B-blue.svg)](https://www.python.org/downloads/)
[![Code style: ruff](https://img.shields.io/badge/Code%20style-ruff-blue.svg)](https://github.com/astral-sh/ruff)

[简体中文](README.zh-CN.md) | [English](README.en.md)

## Overview

This plugin extends Claude Code with long-term memory capabilities using the OpenViking Memory integration. It enables Claude to remember and recall conversations, decisions, and context across sessions, significantly improving coherence and context retention in long-running development workflows.

## Features

- **Long-term Memory Storage**: Persist conversation history and context across Claude Code sessions
- **Intelligent Context Recall**: Automatically retrieve relevant memories based on current conversation context
- **Memory Management**: Efficiently manage and prune memories to maintain performance
- **Session Continuity**: Seamlessly continue conversations where they left off
- **Memory Organization**: Categorize and structure memories by project, session, and context type

## Installation

### Prerequisites

- Python 3.10 or higher
- An existing Claude Code installation
- OpenViking Memory service accessible

### From Source

```bash
git clone https://github.com/Yu-Xiao-Sheng/openviking-memory-plugin.git
cd openviking-memory-plugin
pip install -e .
```

### Configuration

Add the following to your Claude Code settings:

```json
{
  "hooks": {
    "sessionStart": [
      {
        "type": "memory:sessionMemory",
        "options": {
          "memory_service_url": "your-openviking-memory-url",
          "project_id": "your-project-id",
          "max_memory_size": 10000,
          "memory_threshold": 0.8
        }
      }
    ]
  }
}
```

## Usage

Once installed, the plugin automatically integrates with your Claude Code sessions:

1. **Memory Creation**: Memories are created automatically as you work
2. **Context Recall**: Relevant memories are injected into prompts based on context
3. **Memory Pruning**: Older or less relevant memories are automatically managed
4. **Session Continuity**: Continue conversations seamlessly between sessions

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `memory_service_url` | string | Required | URL to your OpenViking Memory service |
| `project_id` | string | Required | Unique identifier for this project |
| `max_memory_size` | integer | 10000 | Maximum number of memories to store |
| `memory_threshold` | float | 0.8 | Threshold for memory recall relevance |

## Memory Types

The plugin categorizes memories into several types:

- **Session Memories**: High-level context about current session goals
- **Conversation Memories**: Detailed conversation history and context
- **Decision Memories**: Important technical decisions and their rationale
- **Code Memories**: Code snippets, patterns, and implementations
- **Issue Memories**: Problems encountered and their solutions

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate and follow the existing code style.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on top of Claude Code
- Powered by OpenViking Memory service
- Inspired by the need for better long-term context in AI-assisted development