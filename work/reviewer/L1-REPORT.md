# L1 静态分析报告 — F-04 路由系统

- **日期**：2026-05-29
- **验证层**：L1 静态分析
- **结果**：**FAIL** ❌

## 验证命令

| 命令 | 结果 |
|------|------|
| `flutter analyze` | 仅 info 级 lint，无 error/warning ✅ |
| `grep -r 'import.*feature' lib/src/core/router/` | **5 处匹配** ❌ |
| `grep -r 'print\|debugger\|TODO' lib/src/core/router/` | 无匹配 ✅ |
| `grep -r 'import.*feature' lib/main.dart` | 无匹配 ✅ |

## 通过项

- `src/` → `lib/src/` 迁移完整，无根级 `src/` 目录残留
- 无 `print`/`debugger`/`TODO` 调试代码残留
- `test/unit/router/` 14 条测试用例结构完整（implementer 自述全部 PASS）
- 7 个 feature 占位页面 + barrel file 齐全（共 12 个文件）

## 违规详情

| # | 约束 | 位置 | 实际结果 |
|---|------|------|---------|
| 1 | CONSTRAINTS.md §1 分层依赖规则 | `lib/src/core/router/code/app_router.dart:11-15` | core/router 直接 import 5 个 feature/* 模块 |

**违规 import 列表**：
1. `import '../../../feature/home/home.dart';` (line 11)
2. `import '../../../feature/voice_input/voice_input.dart';` (line 12)
3. `import '../../../feature/group_manage/group_manage.dart';` (line 13)
4. `import '../../../feature/cleanup/cleanup.dart';` (line 14)
5. `import '../../../feature/model_download/model_download.dart';` (line 15)

**违规说明**：CONSTRAINTS.md §1 明确规定"必须遵守分层依赖规则：feature → core，依赖方向不可逆。下层禁止 import 上层模块"。ARCHITECTURE.md 依赖方向图也明确 `core` 层处于底层，不允许逆依赖 `feature` 层。

## 判断

L1 **不通过**。存在架构硬约束违规，退回 implementer 修复后重新提交。L2 / L3 未执行。
