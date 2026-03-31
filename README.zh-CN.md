# OpenViking Memory Plugin for Claude Code

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Python 3.10+](https://img.shields.io/badge/Python-3.10+-green.svg)](https://www.python.org/)

[English](README.md) | **中文**

基于 [OpenViking](https://github.com/volcengine/OpenViking)，为 Claude Code 提供跨会话的长期记忆自动提取、存储和语义召回能力。

## 功能特性

- **自动会话记忆** -- 每轮对话自动摄入并提交到记忆系统
- **语义召回** -- 每次提问时自动检索相关记忆并注入上下文
- **按需召回** -- 使用 `/memory-recall` 随时搜索历史记忆
- **Embedding 支持** -- 使用 SiliconFlow API 进行向量化（BAAI/bge-large-zh-v1.5）
- **本地模式** -- 无需服务器，基于文件系统的向量存储
- **HTTP 模式** -- 可选连接远程 openviking-server

## 前置条件

- Python 3.10 或更高版本
- [uv](https://docs.astral.sh/uv/)（推荐）或 pip
- SiliconFlow API Key（用于 Embedding）-- [在此注册](https://siliconflow.cn)
- Claude Code CLI

## 快速开始

### 一键安装

```bash
git clone https://github.com/Yu-Xiao-Sheng/openviking-memory-plugin.git
cd openviking-memory-plugin
SILICONFLOW_API_KEY=sk-your-key-here bash install.sh
```

### 或使用显式参数

```bash
bash install.sh --api-key sk-your-key-here --project /path/to/your/project
```

### 安装完成后

1. 重启 Claude Code
2. 打开一个包含 `ov.conf` 的项目目录
3. 开始对话 -- 记忆会被自动捕获

## 配置说明

### ov.conf

安装脚本会在项目根目录自动生成 `ov.conf`，也可以手动创建：

```bash
cp ov.conf.example ./ov.conf
# 编辑 ./ov.conf，将 YOUR_SILICONFLOW_API_KEY_HERE 替换为你的实际 API Key
```

### 配置项

| 选项 | 说明 | 默认值 |
|------|------|--------|
| `storage.workspace` | OpenViking 工作目录 | `~/.openviking-workspace` |
| `embedding.dense.provider` | Embedding API 提供方 | `openai` |
| `embedding.dense.model` | Embedding 模型名称 | `BAAI/bge-large-zh-v1.5` |
| `embedding.dense.api_base` | Embedding API 地址 | `https://api.siliconflow.cn/v1` |
| `embedding.dense.dimension` | Embedding 向量维度 | `1024` |
| `log.level` | 日志级别 | `INFO` |

## 工作原理

### Hook 生命周期

| 事件 | 作用 |
|------|------|
| `SessionStart` | 创建 OpenViking 会话，将会话状态保存到 `.openviking/memory/` |
| `UserPromptSubmit` | 搜索相关记忆，将 Top-3 结果注入上下文 |
| `Stop`（异步） | 解析最后一轮对话，摄入到 OpenViking 会话中 |
| `SessionEnd` | 提交会话，触发长期记忆提取 |

### 架构流程

```
用户提问
    |
    +--> [UserPromptSubmit hook] --> 检索相关记忆 --> 注入上下文
    |
    +--> Claude Code 处理提问（携带记忆上下文）
            |
            +--> [Stop hook] --> 从 transcript 提取对话轮次 --> 摘要 --> 摄入 OpenViking
                    |
                    +--> [SessionEnd hook] --> 提交会话 --> OpenViking 提取长期记忆
```

### 记忆召回技能

使用 `/memory-recall` 斜杠命令按需搜索记忆：

```
/memory-recall 我们之前对数据库 schema 做了哪些决定？
```

## 安装选项

```bash
# 使用默认设置安装
SILICONFLOW_API_KEY=sk-xxx bash install.sh

# 安装到指定项目
bash install.sh --api-key sk-xxx --project ~/my-project

# 使用自定义 venv 路径
bash install.sh --api-key sk-xxx --venv-path ~/.my-venv

# 跳过依赖安装（使用已有 venv）
bash install.sh --skip-deps
```

## 常见问题

| 问题 | 解决方案 |
|------|----------|
| `python not found` | 确保已安装 Python 3.10+，重新运行 `install.sh` |
| `ov.conf not found` | 将 `ov.conf.example` 复制到项目根目录并重命名为 `ov.conf` |
| `API key invalid` | 检查 `ov.conf` 中的 SiliconFlow API Key 是否正确 |
| 启动较慢 | 首次会话需要初始化 Embedding 模型，后续启动会更快 |
| 无法召回记忆 | 确保至少完成过一次完整会话（开始 + 结束）以触发记忆提取 |

## 卸载

```bash
cd openviking-memory-plugin
bash uninstall.sh
```

此操作会移除插件文件、Marketplace 注册信息，并可选择删除 venv 和工作目录。

## 许可证

[Apache-2.0](LICENSE)

## 致谢

- [OpenViking](https://github.com/volcengine/OpenViking) by ByteDance/volcengine
- 基于 [Claude Code Plugin](https://docs.anthropic.com/en/docs/claude-code/plugins) 体系构建
