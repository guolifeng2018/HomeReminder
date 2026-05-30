# FIX-QUEUE — F-06（core/notification）

<!-- reviewer L1 发现问题，implementer 逐条修复后交还 reviewer。 -->

---

## 问题 1 ✅ 已解决（round 2）

- **验证层**：L1
- **评分维度**：正确性
- **位置**：`lib/src/core/notification/code/notification_service_impl.dart:_buildBodyText`
- **状态**：**已修复**
- **修复摘要**：implementer 添加了 `_maxBodyLength = 200` 常量和截断逻辑，body > 200 字符时截断至 199 + '…'。新增 4 个测试覆盖全场景。
- **验证结果**：L1 flutter analyze 零 error/warning（F-06 范围），L2 52/52 PASS，含 4 个新增截断测试。

---

## 附注 A ✅ 已处理

- `analysis_options.yaml` 排除 `history/` — implementer 已添加。当前全量 `flutter analyze` 仅有 1 info（F-05 范围），history/ 归档代码不再干扰。

---

## 附注 B（非阻塞）

- `flutter_app_badger` 版本当前为 `^1.5.0`，PLAN.md 指定 `^2.1.0`。当前功能正常（BadgeManager 13 tests PASS），版本差异不阻塞。建议在后续功能中统一升级依赖。
