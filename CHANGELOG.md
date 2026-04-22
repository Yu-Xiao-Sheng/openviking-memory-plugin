# Changelog

## [1.1.0] - 2026-04-22

### Added
- Auto-migration: when entering a project with legacy `./data` directory, automatically migrate to `~/.openviking/vectordb` and replace with symlink
- Unified storage: vectordb now defaults to `~/.openviking/vectordb` instead of per-project `./data`
- Global `ov.conf` fallback: now checks `$HOME/.openviking/ov.conf` if project-level config not found

### Changed
- Updated `ov.conf.example` with new `storage.vectordb.path` option
- Improved `common.sh` shell compatibility and error handling

## [1.0.0] - 2026-03-31

### Added
- Initial release of openviking-memory plugin for Claude Code
- Automatic session memory extraction via SessionStart/Stop/SessionEnd hooks
- Semantic memory recall via UserPromptSubmit hook and `/memory-recall` skill
- One-command installer with OpenViking venv setup
- SiliconFlow embedding integration (BAAI/bge-large-zh-v1.5)
- Dynamic Python venv detection (no hardcoded paths)
- Uninstall script
