# L1 静态分析报告

---

## 基本信息

- **功能 ID**：F-04
- **验证日期**：2026-05-30
- **轮次**：round 1

---

## 验证命令

```bash
flutter analyze
flutter analyze lib/src/router/
```

## 输出摘要

- `flutter analyze lib/src/router/`：**No issues found**
- `flutter analyze`（全局）：零 error，5 warning + 1 info（均在 test/unit/home/ 和 test/unit/reminder/ 中，非 F-04 范围）

## 架构约束检查

| 约束 | 检查方法 | 结果 |
|------|---------|------|
| 禁止网络请求 | `grep -r "http\|fetch\|dio" lib/src/router/` | PASS（无匹配） |
| 禁止 Widget 直接访问数据库 | `grep -r "database\|drift" lib/src/router/code/`（排除 providers import） | PASS（无匹配） |
| 禁止依赖 feature 层 | `grep -r "import.*feature" lib/src/router/` | PASS（无匹配） |
| placeholder_pages 是内部 stub | app_router.dart import `placeholder_pages.dart` | PASS |
| 路由模块零 warning | `flutter analyze lib/src/router/` | PASS（No issues） |
| 无调试代码残留 | `grep -rn "print(\|debugger\|TODO" lib/src/router/` | PASS（无匹配） |

## 模块约束检查（lib/src/router/CONSTRAINTS.md）

| # | 约束 | 结果 |
|---|------|------|
| 1 | 仅依赖 core 层和 go_router | PASS |
| 2 | appRouterProvider 暴露 GoRouter | PASS |
| 3 | redirect 中不执行 I/O 或状态修改 | PASS（仅读取 Provider） |
| 4 | flutter analyze 零 warning | PASS |
| 5 | 无网络请求 | PASS |

---

## 结果

**PASS**
