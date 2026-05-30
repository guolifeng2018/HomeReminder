#!/usr/bin/env bash
# 清理 DeepSeek harness 遗留的 subagent 状态，避免 agent_open/close 卡死或占满并发槽。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_FILE="${ROOT}/.deepseek/state/subagents.v1.json"

echo "[harness-cleanup] project: ${ROOT}"

if [[ -f "${STATE_FILE}" ]]; then
  echo "[harness-cleanup] removing stale subagent state: ${STATE_FILE}"
  rm -f "${STATE_FILE}"
else
  echo "[harness-cleanup] no subagent state file (ok)"
fi

# 可选：若 deepseek CLI 在 PATH 中，列出仍标记为 running 的 agent（仅诊断）
if command -v deepseek >/dev/null 2>&1; then
  echo "[harness-cleanup] tip: 若编排中仍有僵尸 subagent，在新 deepseek 会话里执行 agent_list(include_archived=true) 并对 Running 项 agent_close"
fi

echo "[harness-cleanup] done"
