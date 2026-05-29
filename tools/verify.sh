#!/bin/bash
set -e

echo "=== 居净清单 (JuJingList) 验证 ==="

# L1 — 静态分析
echo "--- L1: flutter analyze ---"
flutter analyze
echo "[PASS] L1 静态分析"

# L2 — 运行时验证
echo "--- L2: 单元测试 ---"
if [ -d "test/unit" ] && [ "$(ls -A test/unit/ 2>/dev/null)" ]; then
    flutter test test/unit/
    echo "[PASS] L2 单元测试"
else
    echo "[SKIP] L2 单元测试（目录为空）"
fi

echo "--- L2: 集成测试 ---"
if [ -d "test/integration" ] && [ "$(ls -A test/integration/ 2>/dev/null)" ]; then
    flutter test test/integration/
    echo "[PASS] L2 集成测试"
else
    echo "[SKIP] L2 集成测试（目录为空）"
fi

# L3 — 端到端验证
echo "--- L3: E2E 测试 ---"
if [ -d "test/e2e" ] && [ "$(ls -A test/e2e/ 2>/dev/null)" ]; then
    flutter test test/e2e/
    echo "[PASS] L3 E2E 测试"
else
    echo "[SKIP] L3 E2E 测试（目录为空）"
fi

# 环境自检
echo "--- 环境自检 ---"
flutter doctor -v 2>&1 | head -30

echo ""
echo "=== 验证完成 ==="
