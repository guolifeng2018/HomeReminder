# 实现方案

---

## 基本信息

- **功能 ID**：F-05
- **功能名称**：core/reminder 提醒核心

---

## 涉及模块

| 模块 | 变更类型 | 说明 |
|------|---------|------|
| lib/src/core/reminder/ | 新建 | 提醒核心模块，4 个独立逻辑组件 + 1 个整合 Service |
| lib/src/core/providers/code/service_providers.dart | 修改 | 将 ReminderService stub 替换为真实实现 |
| test/unit/reminder/ | 新建 | 5 个测试文件，覆盖全部组件 |

---

## 实现步骤

### 步骤 1：时间解析引擎

- **内容**：创建 `lib/src/core/reminder/code/time_parser.dart`
  - `TimeParser` 类，`parse(String input) → DateTime?` 方法
  - 支持 ≥20 种口语模式：今天下午3点、明天早上8点、后天下午2点、下周一下午3点、下周三、周末（周六）、月底（本月最后一天）、半个月后、下个月5号、每天早上8点、每周三、隔天（后天）、三天后、下周末（下周六）、大后天、中午12点、傍晚18点、下周五晚上8点、半年后、明年今天
  - 歧义处理：下周末→下周六，隔天→后天，月底→本月最后一天（28/29/30/31）
  - 使用 `intl` 包的 `DateFormat` 做基础解析
- **验收标准**：`flutter test test/unit/reminder/time_parser_test.dart` ≥25 条用例全部通过
- **涉及文件**：`lib/src/core/reminder/code/time_parser.dart`（新建）

### 步骤 2：重复调度器

- **内容**：创建 `lib/src/core/reminder/code/recurrence_scheduler.dart`
  - `RecurrenceScheduler` 类，`nextTrigger(DateTime lastTrigger, ReminderFrequency frequency) → DateTime`
  - once → 返回 null（不重复）
  - daily → lastTrigger + 1 day
  - weekly → lastTrigger + 7 days
  - biweekly → lastTrigger + 14 days
  - monthly → lastTrigger + 1 month（处理月底边界：1月31日→2月28/29日）
- **验收标准**：`flutter test test/unit/reminder/recurrence_scheduler_test.dart` 覆盖 5 种频率 + 跨月边界
- **涉及文件**：`lib/src/core/reminder/code/recurrence_scheduler.dart`（新建）

### 步骤 3：推迟逻辑

- **内容**：创建 `lib/src/core/reminder/code/postpone_policy.dart`
  - `PostponePolicy` 类
  - `postpone1Hour(DateTime from) → DateTime`
  - `postpone3Hours(DateTime from) → DateTime`
  - `postponeTomorrow(DateTime from) → DateTime`（from + 1 day，same time）
  - `postponeCustom(DateTime from, Duration duration) → DateTime`
- **验收标准**：`flutter test test/unit/reminder/postpone_policy_test.dart` 4 种推迟方法全部正确
- **涉及文件**：`lib/src/core/reminder/code/postpone_policy.dart`（新建）

### 步骤 4：重试机制

- **内容**：创建 `lib/src/core/reminder/code/retry_policy.dart`
  - `RetryPolicy` 类
  - `nextRetryDelay(int attempt) → Duration?`：attempt 1→5min, 2→15min, 3→45min, ≥4→null（不再重试）
  - `nextRetryAt(DateTime scheduledAt, int attempt) → DateTime?`
- **验收标准**：`flutter test test/unit/reminder/retry_policy_test.dart` 3 次退避间隔正确 + 上限停止
- **涉及文件**：`lib/src/core/reminder/code/retry_policy.dart`（新建）

### 步骤 5：ReminderService 整合

- **内容**：创建 `lib/src/core/reminder/code/reminder_service.dart`
  - `ReminderServiceImpl` 实现 `ReminderService` 抽象接口
  - 构造函数注入 `GroupRepository` + `ReminderRepository`
  - `createReminder(title, content, groupId, timeExpression, frequency)`：解析时间→计算 nextTrigger→写入 DB
  - `markCompleted(id)` / `markDismissed(id)`：更新状态
  - `checkOverdue()`：扫描 overdue 提醒并标记
  - `getUpcoming(limit)`：查询未来提醒
- **验收标准**：`flutter test test/unit/reminder/reminder_service_test.dart` 使用 mock repository 验证全部 CRUD 路径
- **涉及文件**：
  - `lib/src/core/reminder/code/reminder_service.dart`（新建）
  - `lib/src/core/providers/code/service_providers.dart`（修改）

### 步骤 6：Barrel + Provider 注册

- **内容**：
  - `lib/src/core/reminder/reminder.dart` barrel file 导出全部组件
  - 更新 `service_providers.dart` 中的 `reminderServiceProvider`，将 stub 替换为 `ReminderServiceImpl`
- **验收标准**：`flutter analyze lib/src/core/reminder/` 零 warning
- **涉及文件**：
  - `lib/src/core/reminder/reminder.dart`（新建）
  - `lib/src/core/providers/code/service_providers.dart`（修改）

---

## 依赖

| 依赖 | 类型 | 说明 |
|------|------|------|
| intl | 外部库 | DateFormat 解析，pubspec.yaml 已包含 |
| lib/src/core/common/ | 模块 | Reminder/Group 数据模型、ReminderStatus/Frequency 枚举 |
| lib/src/core/database/ | 模块 | GroupRepository + ReminderRepository（步骤 5 需要） |
| lib/src/core/providers/ | 模块 | ReminderService 抽象接口（步骤 5 需要） |

---

## 排除项

1. 不实现系统闹钟实际注册——F-06 职责
2. 不实现 UI——F-08 职责
3. 不做真实平台 API 调用
4. 不做 i18n 多语言
