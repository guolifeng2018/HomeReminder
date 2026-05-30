# 功能拆分

---

## 基本信息

- **功能 ID**：F-05
- **功能名称**：core/reminder 提醒核心
- **涉及模块**：core/reminder（新建内部文件）、core/providers（修改 service_providers.dart 注册真实实现）
- **依赖模块**：core/database（F-02，GroupRepository + ReminderRepository）、core/providers（F-03，databaseProvider + StubReminderService）、core/common（F-01，模型 + 枚举 + 现有 DateFormatter）

---

## 工作单元

| # | 单元名称 | 描述 | 验证命令 | 依赖 | 状态 |
|---|---------|------|---------|------|------|
| REM-01 | 时间解析引擎 | 实现 `SpokenTimeParser` 类（`lib/src/core/reminder/code/spoken_time_parser.dart`），支持 ≥20 种口语时间表达→DateTime 解析：今天下午3点 / 明天早上 / 后天下午 / 大后天 / 下周一下午 / 下周三 / 本周五 / 周末（周六） / 下周末（下周六） / 月底（本月最后一天） / 半个月后 / 下个月5号 / 每天早上8点 / 每周三 / 隔天 / 三天后 / 一周后 / 上午9点 / 中午12点 / 晚上8点 / 凌晨2点 / 半小时后 / X分钟后 / X小时后。解析结果返回 `DateTime?`，含 `referenceDate` 参数支持可测试性。处理歧义：「下周末→下周六」「隔天→后天」「月底→本月最后一天（28/29/30/31 自适应）」 | `flutter analyze lib/src/core/reminder/code/spoken_time_parser.dart` 零 warning | 无（独立纯 Dart 逻辑，仅依赖 Dart SDK） | pending |
| REM-02 | 定时调度引擎 | 实现 `ReminderScheduler` 类（`lib/src/core/reminder/code/reminder_scheduler.dart`），核心职责：1) 根据 `ReminderFrequency` 计算 `nextTriggerTime(scheduledAt, frequency)` — once 返回原时间、daily +1天、weekly +7天、biweekly +14天、monthly +1月（安全处理月末溢出）；2) 扫描过期提醒 — `findOverdue(ReminderRepository)` 查询 status=pending 且 scheduledAt < now 的提醒并标记为 overdue；3) 已完成/dismissed 提醒跳过不调度。注意：本单元不执行实际系统闹钟注册（那是 F-06 notification 的职责），只负责时间计算+状态判定。 | `flutter analyze lib/src/core/reminder/code/reminder_scheduler.dart` 零 warning | 无（纯时间计算逻辑，仅依赖 ReminderFrequency 枚举 + DateTime） | pending |
| REM-03 | 推迟逻辑 | 实现 `PostponeLogic` 类（`lib/src/core/reminder/code/postpone_logic.dart`），支持四种推迟模式：1小时 / 3小时 / 明天（次日同时间） / 自定义（任意 Duration），返回新的 `DateTime`。提供静态方法 `postpone(DateTime original, {required PostponePreset preset, Duration? custom})`，`PostponePreset` 枚举含 `oneHour / threeHours / tomorrow / custom`。 | `flutter analyze lib/src/core/reminder/code/postpone_logic.dart` 零 warning | 无（纯时间偏移计算） | pending |
| REM-04 | 重试机制 | 实现 `RetryPolicy` 类（`lib/src/core/reminder/code/retry_policy.dart`），3 次指数退避：第 1 次重试=+5min，第 2 次=+15min，第 3 次=+45min，超过 3 次不再重试。提供方法 `nextRetryTime(int attemptNumber, DateTime originalTime)` 返回下次重试 DateTime 或 null（已达上限）。`attemptNumber` 从 1 开始。 | `flutter analyze lib/src/core/reminder/code/retry_policy.dart` 零 warning | 无（纯数学计算） | pending |
| REM-05 | ReminderService 实现 + Provider 注册 | 实现 `ReminderServiceImpl`（`lib/src/core/reminder/code/reminder_service_impl.dart`），通过构造函数注入 `GroupRepository` + `ReminderRepository` + `ReminderScheduler` + `PostponeLogic` + `RetryPolicy` + `SpokenTimeParser`。实现 `ReminderService` 接口（扩展 F-03 stub 接口，新增 `parseTime` / `postpone` / `getNextRetry` / `createReminder` / `checkOverdue` 等方法）。关键行为：`createReminder` 写入 DB + 返回 Reminder；`checkOverdue` 扫描到期 → 标记 overdue → 根据 retryPolicy 决定重试调度；`postponeReminder` 更新 scheduledAt + 重置 retry count。在 `service_providers.dart` 中通过 `ProviderScope.overrides` 注释指引替换 stub。barrel file 导出。（注：核心调度注册由 F-05 完成，系统闹钟调用由 F-06 notification 使用本模块计算结果执行） | `flutter analyze lib/src/core/reminder/` 零 warning，`grep -r 'import.*feature' lib/src/core/reminder/` 返回空 | REM-01, REM-02, REM-03, REM-04（集成所有子引擎） | pending |
| REM-06 | 单元测试 + 集成验证 | 编写 `test/unit/reminder/` 完整测试套件：1) `spoken_time_parser_test.dart` ≥20 条口语解析用例（含歧义边界）；2) `reminder_scheduler_test.dart` 覆盖 once/daily/weekly/biweekly/monthly nextTriggerTime + overdue 扫描 + 状态跳过；3) `postpone_logic_test.dart` 推迟 1h/3h/明天/自定义 4 场景 + 跨天/跨月边界；4) `retry_policy_test.dart` 5/15/45 min 退避 + 超过 3 次返回 null；5) `reminder_service_test.dart` mock GroupRepository + ReminderRepository 验证 createReminder / postponeReminder / checkOverdue 调用路径 + overdue 自动标记 + 已完成/dismissed 不重新调度。所有测试使用 `flutter_test` + `mocktail`。最终运行 `flutter analyze` + `flutter test test/unit/reminder/` 全绿。 | `flutter analyze lib/src/core/reminder/` 零 warning && `flutter test test/unit/reminder/` 全部通过 | REM-05（所有源码就位） | pending |

---

## 依赖拓扑

```
REM-01（时间解析）──┐
REM-02（调度引擎）──┤
REM-03（推迟逻辑）──┼──→ REM-05（ReminderService）──→ REM-06（测试）
REM-04（重试机制）──┘
```

- **并行组**：REM-01 / REM-02 / REM-03 / REM-04 互不依赖，可并行实现。
- **串行节点**：REM-05 依赖全部 4 个子引擎就位；REM-06 依赖 REM-05 完成后编写测试。
- **推荐实现顺序**：先并行完成 REM-01~REM-04（每个约 30-60 分钟），再逐个集成到 REM-05（约 60 分钟），最后 REM-06 编写完整测试（约 60 分钟）。

---

## 排除项

1. **系统闹钟注册**：本模块不调用 `flutter_local_notifications` 或 Android `AlarmManager` / iOS `UNNotificationRequest`。实际系统通知由 F-06（core/notification）负责，F-05 仅提供时间计算结果（nextTriggerTime / retryTime）。
2. **语音输入解析**：口语时间解析仅处理已识别文本→DateTime，不做语音→文本（那是 F-10 core/voice 的职责）。
3. **通知 UI / 弹窗**：本模块不涉及任何 Widget、页面、弹窗，不 import `package:flutter/material.dart`。
4. **权限管理**：不处理通知权限申请，留给 F-06。
5. **持久化重试计数**：重试次数依赖 Reminder 实体的某个字段（建议在 Reminder 模型中加 `retryCount` 字段），但如果 Reminder 模型还未加此字段，REM-04 的重试计算接受外部传入 attemptNumber，由 REM-05 决定如何持久化。
6. **时区处理**：全部使用本地时间（`DateTime.now()`），不做时区转换。
7. **跨年/夏令时**：不处理夏令时切换歧义，以系统本地时间戳为准。
