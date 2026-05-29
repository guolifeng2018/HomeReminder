# 实现方案

---

## 基本信息

- **功能 ID**：F-05
- **功能名称**：core/reminder 提醒核心
- **实现策略**：6 个工作单元，REM-01~REM-04 可并行，REM-05 串行集成，REM-06 收尾测试

---

## 涉及模块

| 模块 | 变更类型 | 说明 |
|------|---------|------|
| `lib/src/core/reminder/code/` | **新建 6 文件** | spoken_time_parser.dart, reminder_scheduler.dart, postpone_logic.dart, retry_policy.dart, reminder_service_impl.dart, reminder_service_interface.dart |
| `lib/src/core/reminder/reminder.dart` | **新建** | barrel file 统一导出 |
| `lib/src/core/providers/code/service_providers.dart` | **修改** | 添加 ReminderServiceImpl 的 Provider（或注释指引替换 stub） |
| `lib/src/core/providers/code/reminder_service.dart` | **修改** | 扩展抽象接口（新增 parseTime / postpone / checkOverdue 等方法签名） |
| `test/unit/reminder/` | **新建目录** | 5 个测试文件 |

---

## 实现步骤

### 步骤 REM-01：时间解析引擎

**文件**：`lib/src/core/reminder/code/spoken_time_parser.dart`

**关键实现**：
- 类名 `SpokenTimeParser`，静态方法 `DateTime? parse(String input, {DateTime? referenceDate})`
- 内部按优先级顺序匹配：纯相对偏移 → 日期+时间组合 → 仅日期 → 仅时间
- **必须覆盖的 24 种模式**：

| # | 输入 | 预期输出（相对 referenceDate=2026-06-01 周一 10:00） |
|---|------|------|
| 1 | 今天下午3点 | 2026-06-01 15:00 |
| 2 | 明天早上 | 2026-06-02 08:00（早上默认8点） |
| 3 | 后天下午 | 2026-06-03 14:00（下午默认14点） |
| 4 | 大后天 | 2026-06-04 09:00（无时间默认9点） |
| 5 | 下周一下午 | 2026-06-08 14:00（下周一是 6/8） |
| 6 | 下周三 | 2026-06-10 09:00 |
| 7 | 本周五 | 2026-06-05 09:00 |
| 8 | 周末 | 2026-06-06 09:00（周六） |
| 9 | 下周末 | 2026-06-13 09:00（下周六） |
| 10 | 月底 | 2026-06-30 09:00（6月最后一天） |
| 11 | 半个月后 | 2026-06-16 10:00（+15天，保持原时刻） |
| 12 | 下个月5号 | 2026-07-05 09:00 |
| 13 | 每天早上8点 | 2026-06-01 08:00（今天8点） |
| 14 | 每周三 | 2026-06-03 09:00（最近周三） |
| 15 | 隔天 | 2026-06-03 10:00（+2天） |
| 16 | 三天后 | 2026-06-04 10:00 |
| 17 | 一周后 | 2026-06-08 10:00 |
| 18 | 上午9点 | 2026-06-01 09:00（今天） |
| 19 | 中午12点 | 2026-06-01 12:00 |
| 20 | 晚上8点 | 2026-06-01 20:00 |
| 21 | 凌晨2点 | 2026-06-01 02:00 |
| 22 | 半小时后 | 2026-06-01 10:30 |
| 23 | 15分钟后 | 2026-06-01 10:15 |
| 24 | 2小时后 | 2026-06-01 12:00 |

> 注：此表为验收测试的基准数据。referenceDate 固定为 `DateTime(2026, 6, 1, 10, 0)`（周一），所有断言基于此。

**歧义处理规则**：
- 「下周末」→ 下周六（不是下周日），按中国习惯周末指周六
- 「周末」→ 本周六（若今天是周六则返回下周六）
- 「隔天」→ +2 天（即后天，与「后天」同义）
- 「月底」→ 本月最后一天（28/29/30/31 自适应，含闰年 2 月 29 日）
- 「下个月5号」→ 下个月第 5 天，若该月不足 5 天（实际上不可能）取最后一天

**验收标准**：
```bash
flutter analyze lib/src/core/reminder/code/spoken_time_parser.dart  # 零 warning
# 测试见 REM-06
```

---

### 步骤 REM-02：定时调度引擎

**文件**：`lib/src/core/reminder/code/reminder_scheduler.dart`

**关键实现**：
- 类名 `ReminderScheduler`
- 方法 `DateTime? nextTriggerTime(DateTime scheduledAt, ReminderFrequency frequency)`：
  - `once` → 返回 `null`（不重复）
  - `daily` → `scheduledAt.add(Duration(days: 1))`
  - `weekly` → `scheduledAt.add(Duration(days: 7))`
  - `biweekly` → `scheduledAt.add(Duration(days: 14))`
  - `monthly` → 安全加一月（`_addMonthsSafe`，月末溢出取最后一天）
- 方法 `Future<List<Reminder>> findOverdue(ReminderRepository repo)`：
  - 调用 `repo.getOverdue()` 获取过期提醒
  - 对每个过期提醒调用 `repo.update(reminder.copyWith(status: ReminderStatus.overdue))`
  - 返回标记后的提醒列表
- 方法 `bool shouldReschedule(Reminder reminder)`：
  - status 为 `completed` 或 `dismissed` → `false`
  - status 为 `pending` 或 `overdue` 且 frequency ≠ once → `true`

**验收标准**：
```bash
flutter analyze lib/src/core/reminder/code/reminder_scheduler.dart  # 零 warning
```

---

### 步骤 REM-03：推迟逻辑

**文件**：`lib/src/core/reminder/code/postpone_logic.dart`

**关键实现**：
- 枚举 `PostponePreset { oneHour, threeHours, tomorrow, custom }`
- 类 `PostponeLogic`，静态方法：
  ```dart
  static DateTime postpone(DateTime original, {
    required PostponePreset preset,
    Duration? custom,
  })
  ```
- 四种模式映射：
  - `oneHour` → `original.add(const Duration(hours: 1))`
  - `threeHours` → `original.add(const Duration(hours: 3))`
  - `tomorrow` → `DateTime(original.year, original.month, original.day + 1, original.hour, original.minute)`（次日同时间）
  - `custom` → `original.add(custom!)`（custom 为 null 时抛 `ArgumentError`）

**验收标准**：
```bash
flutter analyze lib/src/core/reminder/code/postpone_logic.dart  # 零 warning
```

---

### 步骤 REM-04：重试机制

**文件**：`lib/src/core/reminder/code/retry_policy.dart`

**关键实现**：
- 类 `RetryPolicy`
- 静态常量 `maxRetries = 3`
- 静态常量列表 `retryIntervals = [5, 15, 45]`（分钟）
- 静态方法 `DateTime? nextRetryTime(int attemptNumber, DateTime originalTime)`：
  - `attemptNumber < 1` → 抛 `ArgumentError`
  - `attemptNumber > maxRetries` → 返回 `null`（不再重试）
  - 否则 → `originalTime.add(Duration(minutes: retryIntervals[attemptNumber - 1]))`
- 静态方法 `bool shouldRetry(int attemptNumber)` → `attemptNumber >= 1 && attemptNumber <= maxRetries`

**验收标准**：
```bash
flutter analyze lib/src/core/reminder/code/retry_policy.dart  # 零 warning
```

---

### 步骤 REM-05：ReminderService 实现 + Provider 注册

**文件**：
- `lib/src/core/reminder/code/reminder_service_interface.dart` — 扩展的抽象接口
- `lib/src/core/reminder/code/reminder_service_impl.dart` — 真实实现
- `lib/src/core/providers/code/reminder_service.dart` — 修改抽象接口
- `lib/src/core/providers/code/service_providers.dart` — 添加真实 Provider

**扩展的 `ReminderService` 接口**（在 providers 中修改 stub 文件）：
```dart
abstract class ReminderService {
  /// 解析口语时间文本 → DateTime
  DateTime? parseTime(String input, {DateTime? referenceDate});

  /// 创建提醒（写入 DB 并返回持久化后的 Reminder）
  Future<Reminder> createReminder({
    required int groupId,
    required String title,
    String? content,
    required DateTime scheduledAt,
    ReminderFrequency frequency = ReminderFrequency.once,
  });

  /// 推迟提醒
  Future<Reminder> postponeReminder(int reminderId, PostponePreset preset, {Duration? custom});

  /// 获取下次重试时间
  DateTime? getNextRetryTime(int attemptNumber, DateTime originalTime);

  /// 扫描并标记过期提醒，返回标记数量
  Future<int> checkOverdue();

  /// 取消提醒
  Future<void> cancelReminder(int id);

  /// 调度提醒（保留兼容）
  Future<void> scheduleReminder(dynamic reminder);
}
```

**`ReminderServiceImpl` 实现**：
- 构造函数注入：`GroupRepository`, `ReminderRepository`, `ReminderScheduler`, `PostponeLogic`, `RetryPolicy`, `SpokenTimeParser`
- `createReminder`：构造 Reminder 对象 → `reminderRepo.insert()` → 返回持久化 Reminder
- `postponeReminder`：`reminderRepo.getById()` → 调用 `PostponeLogic.postpone()` → `reminderRepo.update()` 新时间
- `checkOverdue`：调用 `ReminderScheduler.findOverdue(repo)` → 返回标记数量
- `parseTime`：委托 `SpokenTimeParser.parse()`
- `getNextRetryTime`：委托 `RetryPolicy.nextRetryTime()`

**Provider 注册**：
在 `service_providers.dart` 中添加：
```dart
final reminderServiceImplProvider = Provider<ReminderServiceImpl>((ref) {
  final db = ref.watch(databaseProvider);
  final groupRepo = GroupRepository(db);
  final reminderRepo = ReminderRepository(db);
  return ReminderServiceImpl(
    groupRepository: groupRepo,
    reminderRepository: reminderRepo,
    scheduler: ReminderScheduler(),
    postpone: PostponeLogic(),
    retryPolicy: RetryPolicy(),
    timeParser: SpokenTimeParser(),
  );
});
```

同时修改 `reminderServiceProvider` 从返回 `StubReminderService()` 改为返回 `ref.watch(reminderServiceImplProvider)`（或通过 override 机制在 app 启动时替换）。

**验收标准**：
```bash
flutter analyze lib/src/core/reminder/  # 零 warning
grep -r 'import.*feature' lib/src/core/reminder/  # 空输出
grep -r 'package:flutter/material.dart' lib/src/core/reminder/code/  # 空输出（不依赖 Flutter Widget）
```

---

### 步骤 REM-06：单元测试 + 集成验证

**目录**：`test/unit/reminder/`

**测试文件 1**：`spoken_time_parser_test.dart`（≥22 tests）
- 固定 `referenceDate = DateTime(2026, 6, 1, 10, 0)`（周一）
- 逐条验证 REM-01 中的 24 种模式
- 额外边界：「下周末→下周六」「月底→6月30日（2026年6月）」「隔天→6月3日」「闰年2月底→2月29日」
- null 场景：空字符串 / 无意义输入 → `null`

**测试文件 2**：`reminder_scheduler_test.dart`（≥10 tests）
- `nextTriggerTime`: once→null, daily→+1d, weekly→+7d, biweekly→+14d, monthly→+1月（1月31日→2月28日 非闰年 / 2月28日→3月28日）
- `shouldReschedule`: pending+daily→true, completed+daily→false, dismissed+daily→false
- `findOverdue`: mock ReminderRepository，验证 overdue 标记调用次数

**测试文件 3**：`postpone_logic_test.dart`（≥5 tests）
- 推迟 1h → 精确 +1 小时
- 推迟 3h → 精确 +3 小时
- 推迟到明天 → 同时间次日
- 自定义 30 分钟 → +30min
- custom=null 且 preset=custom → ArgumentError

**测试文件 4**：`retry_policy_test.dart`（≥5 tests）
- attempt 1 → +5min
- attempt 2 → +15min
- attempt 3 → +45min
- attempt 4 → null
- attempt 0 / -1 → ArgumentError

**测试文件 5**：`reminder_service_test.dart`（≥8 tests）
- 使用 `mocktail` mock `GroupRepository` + `ReminderRepository`
- `createReminder` → 验证 `reminderRepo.insert` 被调用一次，参数 correct
- `postponeReminder` → 验证 getById + update 调用链
- `checkOverdue` → 验证 getOverdue + batchUpdateStatus 调用链
- 过期提醒自动标记 overdue
- 已完成提醒不重新调度
- dismissed 提醒不重新调度

**验收标准**：
```bash
flutter test test/unit/reminder/  # 全部 PASS，≥50 条测试
flutter analyze lib/src/core/reminder/  # 零 warning
```

---

## 依赖

| 依赖 | 类型 | 说明 |
|------|------|------|
| Dart SDK | 运行时 | `DateTime`, `Duration`, `RegExp` |
| `package:flutter_riverpod/flutter_riverpod.dart` | 外部库 | Provider / ProviderScope（REM-05） |
| `package:drift/drift.dart` | 外部库 | 数据库事务类型（通过 Repository 间接使用） |
| `package:mocktail/mocktail.dart` | 开发依赖 | REM-06 测试 mock |
| `lib/src/core/common/code/models/enums.dart` | 模块（F-01） | ReminderStatus, ReminderFrequency |
| `lib/src/core/common/code/models/reminder_model.dart` | 模块（F-01） | Reminder 实体 |
| `lib/src/core/database/code/group_repository.dart` | 模块（F-02） | GroupRepository（REM-05 注入） |
| `lib/src/core/database/code/reminder_repository.dart` | 模块（F-02） | ReminderRepository（REM-05 注入） |
| `lib/src/core/providers/code/database_providers.dart` | 模块（F-03） | databaseProvider（REM-05 Provider） |
| `lib/src/core/providers/code/reminder_service.dart` | 模块（F-03） | ReminderService 抽象接口 |

> **mocktail** 需要在 `pubspec.yaml` 的 `dev_dependencies` 中添加。如未添加，REM-06 的 mock 测试可降级为使用真实 in-memory database 完成集成测试。

---

## 排除项

1. **系统闹钟注册**：不调用 `flutter_local_notifications` / `AlarmManager` / `UNNotificationRequest`，F-06 负责。
2. **语音→文本**：不做 ASR，F-10 负责。
3. **Widget / UI**：不 import `package:flutter/material.dart`，不创建任何页面或组件。
4. **通知权限**：F-06 负责。
5. **持久化 retryCount**：不修改 Reminder 模型或数据库 schema。重试次数由调用方外部维护，`RetryPolicy` 只做数学计算。
6. **时区 / 夏令时**：全部本地时间，不处理时区转换。
7. **跨年边界**：`_addMonthsSafe` 已处理年末→次年 1 月，无需额外跨年逻辑。
8. **国际化 i18n**：所有中文模式硬编码，不做多语言。
9. **DateFormatter 迁移**：不在 F-05 中修改 `core/common` 的 `DateFormatter`。`SpokenTimeParser` 是独立实现，位于 `core/reminder`，与 `DateFormatter` 并行存在。后续可通过 DEPRECATED 注释标记 `DateFormatter` 并在 F-07+ 迁移。
