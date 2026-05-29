#!/bin/bash
# tools/next-agent.sh — 读取 SESSION-HANDOFF.md，自动启动下一个 agent 的新会话
#
# 用法：
#   bash tools/next-agent.sh          # 在新终端窗口打开
#   bash tools/next-agent.sh --print  # 仅打印命令，不启动

HANDOFF_FILE="harness/SESSION-HANDOFF.md"

if [ ! -f "$HANDOFF_FILE" ]; then
    echo "[FAIL] 未找到 $HANDOFF_FILE"
    exit 1
fi

# 提取角色：在 "## 下一个 Agent" 和下一个 "## " 之间查找 "- **角色**：" 行
ROLE=$(sed -n '/^## 下一个 Agent/,/^## /p' "$HANDOFF_FILE" | grep '^- \*\*角色\*\*' | sed 's/.*：//' | sed 's/\*\*//g' | sed 's/<!--.*-->//g' | tr -d ' ')

if [ -z "$ROLE" ]; then
    echo "[FAIL] SESSION-HANDOFF.md 中未找到 '下一个 Agent → 角色' 字段"
    echo "请手动指定角色启动，或先运行上一个 agent 完成交接。"
    exit 1
fi

echo "下一个 Agent：$ROLE"

if [ "$1" = "--print" ]; then
    echo ""
    echo "在新终端执行："
    echo "  cd $(pwd) && deepseek-tui"
    echo "（agent 会自动识别角色为 $ROLE）"
    exit 0
fi

# 尝试在新终端窗口启动
case "$(uname -s)" in
    Darwin)
        osascript -e "tell application \"Terminal\" to do script \"cd $(pwd) && echo '启动 $ROLE agent...' && deepseek-tui\"" 2>/dev/null &&             echo "[OK] 已在 Terminal 中启动新会话" ||             echo "[WARN] 无法自动启动，请手动执行：cd $(pwd) && deepseek-tui"
        ;;
    Linux)
        if command -v gnome-terminal &>/dev/null; then
            gnome-terminal -- bash -c "cd $(pwd) && echo '启动 $ROLE agent...' && deepseek-tui"
            echo "[OK] 已在 gnome-terminal 中启动新会话"
        elif command -v xterm &>/dev/null; then
            xterm -e "cd $(pwd) && echo '启动 $ROLE agent...' && deepseek-tui" &
            echo "[OK] 已在 xterm 中启动新会话"
        else
            echo "[WARN] 未找到可用终端，请手动执行：cd $(pwd) && deepseek-tui"
        fi
        ;;
    *)
        echo "[WARN] 未知平台，请手动执行：cd $(pwd) && deepseek-tui"
        ;;
esac
