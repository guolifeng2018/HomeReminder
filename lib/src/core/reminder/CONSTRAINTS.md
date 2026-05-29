# 模块约束 — core/reminder

---

## 数据约束

1. **禁止**直接操作 Drift 数据库（ReminderScheduler 等纯逻辑类），数据库访问必须通过 Repository 层。
2. **必须**使用本地时间（`DateTime.now()`），不处理时区转换。
3. **禁止**修改 Reminder 模型或数据库 schema。retryCount 由调用方外部维护。

---

## 接口约束

1. **禁止** import `package:flutter/material.dart` 或任何 Widget/UI 代码。
2. **禁止** import feature 层任何模块。
3. **禁止**调用系统通知 API（`flutter_local_notifications`），留待 F-06 处理。
4. **禁止**使用 `print`、`debugger`、`TODO` 注释。
5. **必须**所有公共方法有文档注释。

---

## 性能约束

1. **必须**口语时间解析为纯同步计算，不涉及 I/O 或异步操作。
2. **必须**调度计算为 O(1) 时间复杂度。
