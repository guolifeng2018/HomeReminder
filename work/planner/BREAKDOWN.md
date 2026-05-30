# 功能拆分

---

## 基本信息

- **功能 ID**：F-05
- **功能名称**：core/reminder 提醒核心
- **涉及模块**：core/reminder（lib/src/core/reminder/）

---

## 工作单元

| # | 单元名称 | 描述 | 验证命令 | 依赖 | 状态 |
|---|---------|------|---------|------|------|
| 1 | 时间解析引擎 | 实现 `TimeParser` 类，将口语化中文时间字符串解析为 `DateTime`，覆盖 ≥20 种模式（今天下午3点/明天早上/后天下午/下周一下午/下周三/周末/月底/半个月后/下个月5号/每天早上8点/每周三/隔天/三天后/下周末/大后天/中午/傍晚/下周五晚上/半年后/明年等） | `flutter test test/unit/reminder/time_parser_test.dart` 全部通过 | 无 | pending |
| 2 | 重复调度器 | 实现 `RecurrenceScheduler`，根据频率（once/daily/weekly/biweekly/monthly）和上次触发时间计算 `nextTriggerTime`，处理跨月/跨年边界 | `flutter test test/unit/reminder/recurrence_scheduler_test.dart` 全部通过 | 无 | pending |
| 3 | 推迟逻辑 | 实现 `PostponePolicy`，支持推迟 1小时/3小时/明天/自定义时长，返回推迟后的 DateTime | `flutter test test/unit/reminder/postpone_policy_test.dart` 全部通过 | 无 | pending |
| 4 | 重试机制 | 实现 `RetryPolicy`，3 次指数退避（5min/15min/45min），达到上限后标记最终失败 | `flutter test test/unit/reminder/retry_policy_test.dart` 全部通过 | 无 | pending |
| 5 | ReminderService | 整合上述 4 组件，实现 `ReminderService` 完整业务逻辑：创建提醒（解析时间→计算调度→写入DB）、标记完成/dismissed、到期检测（overdue 自动标记）、通过构造函数注入 GroupRepository + ReminderRepository | `flutter test test/unit/reminder/reminder_service_test.dart` 全部通过 | #1, #2, #3, #4 | pending |
| 6 | Barrel + Provider 注册 | `lib/src/core/reminder/reminder.dart` barrel file 导出全部公开 API，Provider 注册（现有 service_providers.dart 中的 stub 替换为真实实现） | `flutter analyze lib/src/core/reminder/` 零 warning | #5 | pending |

---

## 依赖拓扑

```
#1（时间解析）──┐
#2（重复调度）──┤
#3（推迟逻辑）──┼──→ #5（ReminderService）→ #6（Barrel + Provider）
#4（重试机制）──┘
```

## 排除项

1. 不实现系统闹钟的实际注册——那是 F-06（notification）的职责，ReminderService 只负责计算调度时间
2. 不实现 UI 交互——时间选择 UI 在 F-08 中
3. 不做真实平台 API 调用——使用抽象接口，具体实现在各平台适配功能中
4. 不做 i18n 多语言——当前仅支持中文口语解析
