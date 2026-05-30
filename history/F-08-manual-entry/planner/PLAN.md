# 实现方案

<!-- 由 planner 填写。implementer 据此实现。 -->

---

## 基本信息

- **功能 ID**：F-08
- **功能名称**：手动录入流程

---

## 涉及模块

| 模块 | 变更类型 | 说明 |
|------|---------|------|
| router | 修改 | `/add` 路由替换 placeholder stub 为真实 `ReminderFormPage` |
| feature/home | 修改 | `home_page.dart` / `home_fab.dart` 增加表单返回后自动刷新逻辑 |

---

## 实现步骤

<!-- 按顺序排列 -->

### 步骤 1：修复 GoRouter /add 路由

- **内容**：
  1. 在 `lib/src/router/code/app_router.dart` 顶部添加 import：`import '../../feature/home/code/reminder_form_page.dart';`
  2. 将 `/add` 路由的 builder 从 `const AddReminderPage()` 替换为 `const ReminderFormPage()`（新建模式，`reminderId` 为 null）
  3. 确认 `placeholder_pages.dart` 中 `AddReminderPage` 类仍保留（F-08 不删除它，防止影响其他引用）；但路由不再指向它
- **验收标准**：
  - `flutter analyze lib/src/router/ 零 warning`
  - GoRouter `/add` 路由编译通过且指向 `ReminderFormPage`
- **涉及文件**：`lib/src/router/code/app_router.dart`

### 步骤 2：首页表单返回后自动刷新

- **内容**：
  1. 修改 `home_page.dart` 手机布局（`_buildPhoneLayout`）中 `TodayTimeline` 的 `onTap` 回调：将 `Navigator.of(context).push(...)` 改为 `await`，检查 `result == true` 时调用 `ref.invalidate(todayRemindersProvider)` 和 `ref.invalidate(groupsProvider)`
  2. 同上修改平板布局（`_buildTabletLayout`）中的 `TodayTimeline` `onTap` 回调
  3. 修改 `home_fab.dart`：将 FAB 的导航方式从 `Navigator.of(context).pushNamed(route)` 改为通过构造参数注入 `onAdd` / `onVoice` 回调（`VoidCallback`），由调用方（`home_page.dart`）在回调中执行 `Navigator.push` + await + invalidate。`addRoute` 和 `voiceRoute` 参数可保留作为 fallback
  4. 修改 `home_page.dart` 中 `HomeFab` 的实例化：传入 `onAdd` 回调，在回调中 `Navigator.push(MaterialPageRoute(builder: (_) => const ReminderFormPage()))` 并 await 结果，若 `true` 则 invalidate
- **验收标准**：
  - `flutter analyze lib/src/feature/home/ 零 warning`
  - `flutter test test/unit/home/ 全部通过`
  - 新建提醒保存后返回首页，列表新增该条提醒（数据自动刷新）
  - 编辑提醒保存后返回首页，列表项更新
- **涉及文件**：`lib/src/feature/home/code/home_page.dart`, `lib/src/feature/home/code/home_fab.dart`

### 步骤 3：最终验证

- **内容**：运行全量静态分析和单元测试，确保无 regression。重点验证 `reminder_form_page_test.dart`、`reminder_form_validation_test.dart`、`reminder_form_submit_test.dart`、`reminder_form_edit_test.dart`、`home_page_test.dart` 全部通过。
- **验收标准**：
  - `flutter analyze lib/src/feature/home/ 零 warning`
  - `flutter analyze lib/src/router/ 零 warning`
  - `flutter test test/unit/home/ 全部通过`（覆盖 ≥4 个测试文件：form UI、form validation、form submit create、form edit）
- **涉及文件**：无新文件（仅验证）

---

## 依赖

<!-- 外部库、工具、或必须先完成的模块 -->

| 依赖 | 类型 | 说明 |
|------|------|------|
| F-02 core/database | 模块 | ReminderRepository（insert/update/delete/getById/getAll）已完成 |
| F-05 core/reminder | 模块 | ReminderFrequency 枚举、Reminder 模型已定义 |
| F-07 feature/home | 模块 | HomePage、HomeFab、TodayTimeline、home_providers 已实现，表单页需嵌入 |
| flutter_riverpod | 外部库 | 已在 pubspec.yaml，Provider.invalidate 用于触发刷新 |
| intl | 外部库 | 已在 pubspec.yaml，DateFormat 用于日期格式化（表单页已使用） |

---

## 排除项

<!-- 明确本次不做，防止 overflow -->

1. **CupertinoDatePicker 平台自适应**：F-08 描述中 "CupertinoDatePicker/DatePicker" 中的 "/" 表示二者择一即可，当前 Material `showDatePicker` + `showTimePicker` 已完整工作，不额外引入自适应逻辑。
2. **集成测试新增**：`test/integration/` 目录（当前为空）的集成测试由后续 F-19（端到端测试）统一编写。
3. **删除提醒功能修改**：`today_timeline.dart` 中 `Dismissible`（红色背景 + 删除图标）+ `AlertDialog('确定删除该提醒？')` 已完整实现，无需改动。
4. **重复提醒后续调度**：表单仅负责 `ReminderFrequency` 枚举值的 UI 选择和存储。按频率自动创建下一次提醒的调度逻辑由 F-05（core/reminder）中的 `ReminderScheduler` 负责。
5. **表单页模块拆分**：`ReminderFormPage` 属于 `feature/home` 模块（与 HomePage 在同一模块目录下），不拆分为独立 feature。
6. **语音录入路径**：FAB 的 "语音录入" 子项（/voice）由 F-13 实现，本次仅处理 "手动添加" 路径的导航和刷新。
