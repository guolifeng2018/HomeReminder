# FIX-QUEUE — F-05 core/reminder

> L2 运行时验证不通过，以下 4 个问题需 implementer 修复。
> 修复完成后运行 `flutter analyze && flutter test test/unit/reminder/` 确认全绿，再交 reviewer。

---

## 问题 1

- **验证层**：L2
- **评分维度**：测试覆盖
- **位置**：`test/unit/reminder/reminder_service_test.dart`（**文件缺失**）
- **实际结果**：REM-06 要求 5 个测试文件，实际仅交付 4 个。缺少 `reminder_service_test.dart`，`ReminderServiceImpl` 的 `createReminder` / `postponeReminder` / `checkOverdue` / `cancelReminder` / `scheduleReminder` / `nextTriggerTime` 均无直接测试。
- **根因**：BREAKDOWN REM-06 明确要求编写 `reminder_service_test.dart`（≥8 tests），使用 mocktail mock `ReminderRepository` 验证服务层调用路径。该文件未创建。
- **期望行为**：新增 `reminder_service_test.dart`，至少覆盖：
  - `createReminder` → 验证 `reminderRepo.insert` 被调用，参数正确
  - `createReminder` → groupId=0 抛出 `ArgumentError`
  - `createReminder` → title 为空抛出 `ArgumentError`
  - `postponeReminder` → 验证 `getById` + `update` 调用链
  - `checkOverdue` → 验证 `getOverdue` + overdue 标记
  - `cancelReminder` → 验证状态变为 dismissed
  - `scheduleReminder` → 验证 insert 调用
  - 已完成/dismissed 提醒在 checkOverdue 中被跳过
- **修复指引**：在 `test/unit/reminder/` 下创建 `reminder_service_test.dart`，使用 `mocktail` mock `ReminderRepository`，注入到 `ReminderServiceImpl`，逐条验证上述场景。参考 BREAKDOWN REM-06 中的测试文件 5 规格。

---

## 问题 2

- **验证层**：L2
- **评分维度**：正确性
- **位置**：`lib/src/core/reminder/code/reminder_scheduler.dart:1-72`
- **实际结果**：`ReminderScheduler` 缺少 `findOverdue(ReminderRepository)` 方法。BREAKDOWN REM-02 将此列为调度引擎的三大核心职责之一："扫描过期提醒 — `findOverdue(ReminderRepository)` 查询 status=pending 且 scheduledAt < now 的提醒并标记为 overdue"。当前 overdue 扫描逻辑被移至 `ReminderServiceImpl.checkOverdue()`，导致 `ReminderScheduler` 职责不完整，且 `reminder_scheduler_test.dart` 未覆盖 overdue 扫描。
- **根因**：implementer 将 DB 操作从调度器移至服务层，偏离了 BREAKDOWN 规定的职责划分（调度器负责时间计算 + 状态判定，但 BREAKDOWN 明确要求调度器直接调用 Repository）。
- **期望行为**：二选一：
  - **方案 A（推荐）**：在 `ReminderScheduler` 中添加 `Future<List<Reminder>> findOverdue(ReminderRepository repo)` 方法，将 `ReminderServiceImpl.checkOverdue()` 中的 overdue 扫描逻辑委托给 scheduler。同时在 `reminder_scheduler_test.dart` 中添加 mock Repository 的 overdue 扫描测试。
  - **方案 B**：如果认为当前架构（调度器纯计算，服务层编排 DB）更合理，则需更新 BREAKDOWN.md 和 PLAN.md 记录此决策变更，并在 `reminder_scheduler_test.dart` 中补充说明 `isOverdue` / `shouldSkip` 已覆盖 overdue 判定逻辑（当前仅测试了 `isOverdue` 和 `shouldSkip`，未测试组合场景）。
- **修复指引**：方案 A 更简单且符合原有规格。在 `ReminderScheduler` 中新增方法，`ReminderServiceImpl.checkOverdue()` 委托调用。补充测试。

---

## 问题 3

- **验证层**：L2
- **评分维度**：架构合规
- **位置**：`lib/src/core/providers/code/reminder_service.dart:10-14`
- **实际结果**：`ReminderService` 抽象接口仅含 `scheduleReminder(dynamic)` 和 `cancelReminder(int)` 两个方法。但 BREAKDOWN REM-05 要求扩展此接口，新增 `parseTime` / `createReminder` / `postponeReminder` / `getNextRetryTime` / `checkOverdue` 等方法签名。当前 `ReminderServiceImpl` 虽然实现了这些方法，但它们不在接口契约中，下游通过 `reminderServiceProvider`（返回 `ReminderService` 类型）无法调用这些方法。
- **根因**：implementer 未按 BREAKDOWN 扩展抽象接口，`ReminderServiceImpl` 的新增方法只能通过具体类型访问，失去了依赖倒置的好处。
- **期望行为**：在 `ReminderService` 抽象类中添加：
  ```dart
  DateTime? parseTime(String input, {DateTime? referenceDate});
  Future<Reminder> createReminder({required int groupId, required String title, ...});
  Future<void> postponeReminder(int id, PostponePreset preset, {Duration? custom});
  DateTime? getNextRetryTime(int attemptNumber, DateTime originalTime);
  Future<int> checkOverdue();
  ```
  同时更新 `StubReminderService` 为每个新方法抛出 `UnimplementedError`。
- **修复指引**：编辑 `lib/src/core/providers/code/reminder_service.dart`，在 `ReminderService` 抽象类中添加上述方法签名（需要 import 相关类型），在 `StubReminderService` 中添加对应的 stub 实现（抛 `UnimplementedError`）。

---

## 问题 4

- **验证层**：L2
- **评分维度**：架构合规
- **位置**：`lib/src/core/providers/code/service_providers.dart:14-17`
- **实际结果**：`reminderServiceProvider` 仍返回 `StubReminderService()`，未添加 `reminderServiceImplProvider` 或通过 `ProviderScope.overrides` 注释指引替换 stub。BREAKDOWN REM-05 要求"在 service_providers.dart 中通过 ProviderScope.overrides 注释指引替换 stub"。
- **根因**：implementer 未完成 Provider 注册步骤。下游（F-06 notification、feature 页面）无法通过 DI 获取 `ReminderServiceImpl` 实例。
- **期望行为**：在 `service_providers.dart` 中添加：
  ```dart
  /// ReminderService 真实实现 Provider
  ///
  /// 在 app 启动时通过 ProviderScope.overrides 替换 [reminderServiceProvider]：
  /// ```dart
  /// ProviderScope(
  ///   overrides: [
  ///     reminderServiceProvider.overrideWith((ref) {
  ///       return ReminderServiceImpl(
  ///         reminderRepo: ref.watch(reminderRepositoryProvider),
  ///       );
  ///     }),
  ///   ],
  ///   child: MyApp(),
  /// )
  /// ```
  final reminderServiceImplProvider = Provider<ReminderServiceImpl>((ref) {
    final db = ref.watch(databaseProvider);
    return ReminderServiceImpl(
      reminderRepo: ReminderRepository(db),
    );
  });
  ```
- **修复指引**：编辑 `lib/src/core/providers/code/service_providers.dart`，添加上述 Provider 定义。注意需要 import `ReminderServiceImpl` 和 `ReminderRepository`。如果不想在此阶段完全替换 stub（因为 F-06 未就位），至少添加注释指引说明如何通过 `ProviderScope.overrides` 替换。

---

## 附：轻微偏离（不阻塞，但建议统一）

以下偏离不影响 L2 判定，但建议在修复上述 4 个问题时一并处理：

| # | 偏离点 | PLAN/BREAKDOWN 预期 | 实际实现 | 建议 |
|---|--------|-------------------|---------|------|
| A | `PostponeLogic` 方法签名 | 静态方法 | 实例方法（`const` 构造） | 统一为静态方法或接受当前设计（两者均可，当前测试已覆盖） |
| B | `RetryPolicy.nextRetryTime` 对 attemptNumber<1 | 抛出 `ArgumentError` | 返回 `null` | 接受当前实现（返回 null 是更安全的防御性编程），更新 PLAN 记录 |
| C | `PostponeLogic.postpone` custom=null | 抛出 `ArgumentError` | 默认 1 小时 | 接受当前实现（默认值避免崩溃），更新 PLAN 记录 |
| D | `GroupRepository` 未注入 `ReminderServiceImpl` | 构造函数注入 | 未注入 | 当前不需要（groupId 仅做 int 传递），可后续需要时添加 |
