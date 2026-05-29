# L1 静态分析报告

<!-- 由 reviewer 填写。 -->

---

## 基本信息

- **功能 ID**：F-01
- **验证日期**：2026-05-29
- **轮次**：round 1

---

## 验证命令

```bash
# lint + type check（全项目，因 src/ 不在 lib/ 下）
flutter analyze

# 架构边界：无 feature 层 import
grep -rn 'import.*feature' src/core/common/

# 模块约束：无 flutter_riverpod
grep -rn 'flutter_riverpod' src/core/common/

# 模块约束：无 Flutter Framework（纯 Dart 层）
grep -rn 'package:flutter/' src/core/common/

# 模块约束：无调试代码残留
grep -rn 'print\|debugger\|TODO' src/core/common/
```

---

## 架构边界检查

| 约束条目 | 文件 | 结果 |
|---------|------|------|
| CONSTRAINTS.md §架构约束.1 — 依赖方向不可逆，下层禁止 import 上层 | `src/core/common/` 全部源文件 | ✅ 无 `import.*feature` |
| CONSTRAINTS.md §架构约束.2 — 使用 Riverpod 做状态管理 | `src/core/common/` | ✅ common 层不引入 riverpod（constraint 明确允许） |
| CONSTRAINTS.md §架构约束.3 — 禁止 Widget 直接访问 Drift | N/A (common 层无 Widget) | ✅ |
| CONSTRAINTS.md §架构约束.4 — Method Channel 桥接 ASR/LLM | N/A (common 层不涉及) | ✅ |
| CONSTRAINTS.md §代码规范.1 — 禁止网络请求/数据上传/日志上报 | `src/core/common/` 全部源文件 | ✅ |
| CONSTRAINTS.md §代码规范.3 — 平台 API 版本兼容 | N/A (纯 Dart 层，无平台 API) | ✅ |
| CONSTRAINTS.md §工具链.1 — 禁止模型文件打包 | N/A | ✅ |
| CONSTRAINTS.md §工具链.2 — `flutter analyze` 零报错 | 全项目 | ✅ 0 errors, 0 warnings, 30 info-level |
| CONSTRAINTS.md §工具链.3 — 禁止 print/debugger/TODO | `src/core/common/` 全部源文件 | ✅ |

---

## 模块约束检查

| 约束条目 | 文件 | 结果 |
|---------|------|------|
| §1 禁止引入 flutter_riverpod | `src/core/common/` | ✅ grep 返回空（仅 CONSTRAINTS/ARCHITECTURE 文档提及） |
| §2 纯 Dart 层，不依赖 Flutter Framework | `src/core/common/` | ✅ 无 `package:flutter/` import |
| §3 禁止 import feature 层 | `src/core/common/` | ✅ grep 返回空（仅 CONSTRAINTS.md 文档提及） |
| §4 禁止 print/debugger/TODO | `src/core/common/` | ✅ grep 返回空（仅 CONSTRAINTS.md 文档提及） |
| §5 公开 API 有文档注释 | 全部 8 个源文件 | ✅ 所有 class/enum/方法 均含 `///` 文档注释 |
| §6 DateFormatter 仅依赖 `intl` | `date_formatter.dart` | ✅ 仅 import `package:intl/intl.dart` |
| §7 PermissionManager 仅抽象接口 + Stub | `permission_manager.dart`, `_stub.dart` | ✅ 无平台通道调用 |
| §8 序列化方法健壮处理 null/类型不匹配 | `group_model.dart`, `reminder_model.dart` | ✅ 含 `_parseInt`/`_safeInt` 等容错辅助函数 |

---

## flutter analyze 详情

- **errors**: 0
- **warnings**: 0
- **info**: 30（均为 test 文件中的 `avoid_redundant_argument_values` × 29 + `prefer_const_declarations` × 1）
- **结论**：零 warning/error，符合 CONSTRAINTS.md "禁止 warnings 遗留" 门禁

---

## 结果

- **判定**：PASS
- **问题数量**：0

---

## 问题清单

（无）

---

## 建议固化为规则

1. 30 个 `info` 级 lint 提示（`avoid_redundant_argument_values`）集中在测试文件，建议在 `analysis_options.yaml` 中对 `test/` 目录放宽该规则，或由 implementer 在后续轮次统一清理，避免 reviewer 每次都看到这些低价值提示。
