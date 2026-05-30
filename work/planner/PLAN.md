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
| feature/home | 修改 | 替换 `add_reminder_page.dart` → `reminder_form_page.dart`（完整表单），修改 `today_timeline.dart`（添加 Dismissible），修改 `home_page.dart`（onTap 布线），更新 `home.dart` barrel |
| core/common | **只读依赖** | `Reminder`、`ReminderStatus`、`ReminderFrequency`、`Group` 模型 |
| core/database | **只读依赖** | `ReminderRepository.insert/update/delete/getById`、`GroupRepository.getAll` |
| core/providers | **只读依赖** | `reminderRepositoryProvider`、`groupRepositoryProvider` |

---

## 实现步骤

<!-- 按顺序排列 -->

### 步骤 1：ReminderFormPage 完整表单 UI

- **内容**：
  1. 新建文件 `lib/src/feature/home/code/reminder_form_page.dart`
  2. `ReminderFormPage` 为 `ConsumerStatefulWidget`，构造参数接收可选 `reminderId`（int?，默认 null）
  3. AppBar 标题：`reminderId == null ? '添加提醒' : '编辑提醒'`
  4. 表单字段：
     - **标题**：`TextFormField`，`maxLength: 50`，`decoration: labelText='标题'`，`controller` 绑定
     - **内容**：`TextFormField`，`maxLength: 200`，`maxLines: null`（multiline），`decoration: labelText='内容（可选）'`
     - **分组下拉**：`DropdownButtonFormField<Group>`，从 `groupRepositoryProvider` 加载全部 Group 列表，`items` 为 Group.name 列表，`value` 为当前选中的 Group，`decoration: labelText='分组'`，`validator` 非空
     - **时间选择**：`ListTile` 显示当前选中时间（格式 `yyyy-MM-dd HH:mm`），点击触发 `showDatePicker()` → 选择日期后链式 `showTimePicker()` → 更新 `_selectedDateTime`
     - **重复频率**：`SegmentedButton<ReminderFrequency>`，`segments` 为 5 个 `ButtonSegment(value: freq, label: Text(freq.displayName))`，绑定 `_selectedFrequency`
  5. 底部 `ElevatedButton('保存')`，通过 `_formKey.currentState!.validate()` 触发验证
  6. 编辑模式时在 `initState` 中异步加载提醒数据预填充

- **验收标准**：`flutter analyze lib/src/feature/home/code/reminder_form_page.dart` 零 warning
- **涉及文件**：`lib/src/feature/home/code/reminder_form_page.dart`（新建）

### 步骤 2：表单验证逻辑

- **内容**：
  1. 使用 `GlobalKey<FormState>` 管理表单验证
  2. 标题 `TextFormField.validator`：`value == null || value.trim().isEmpty ? '标题不能为空' : null`
  3. 分组 `DropdownButtonFormField.validator`：`value == null ? '请选择分组' : null`
  4. 时间校验不在 validator 中（因为 ListTile 不是 FormField），在 `_onSubmit()` 方法中单独检查：
     ```dart
     if (_selectedDateTime.isBefore(DateTime.now())) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('时间不能是过去')),
       );
       return;
     }
     ```
  5. 提交按钮置于表单内，`onPressed` 先 `_formKey.currentState!.validate()` 再执行时间校验

- **验收标准**：`flutter test test/unit/home/reminder_form_validation_test.dart` 全部通过
- **涉及文件**：`lib/src/feature/home/code/reminder_form_page.dart`（同上）

### 步骤 3：新建提交流程

- **内容**：
  1. `_onSubmit()` 方法校验通过后：
     ```dart
     final repo = ref.read(reminderRepositoryProvider);
     try {
       await repo.insert(Reminder(
         groupId: _selectedGroup!.id,
         title: _titleController.text.trim(),
         content: _contentController.text.trim().isEmpty
             ? null
             : _contentController.text.trim(),
         scheduledAt: _selectedDateTime,
         frequency: _selectedFrequency,
         status: ReminderStatus.pending,
         createdAt: DateTime.now(),
       ));
       if (mounted) Navigator.of(context).pop(true);
     } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('保存失败: $e')),
         );
       }
     }
     ```
  2. 不调用 `ReminderServiceImpl.createReminder`（避免双重校验），直接使用 `ReminderRepository.insert`

- **验收标准**：`flutter test test/unit/home/reminder_form_submit_test.dart` 全部通过
- **涉及文件**：`lib/src/feature/home/code/reminder_form_page.dart`（同上）

### 步骤 4：编辑流程

- **内容**：
  1. `ReminderFormPage` 构造参数 `final int? reminderId;`
  2. 在 `initState` 中：
     - 若 `reminderId != null`，通过 `ref.read(reminderRepositoryProvider).getById(reminderId!)` 加载现有提醒
     - 预填充：`_titleController.text = reminder.title`，`_contentController.text = reminder.content ?? ''`，`_selectedDateTime = reminder.scheduledAt`，`_selectedFrequency = reminder.frequency`
     - 分组在 `groupsAsync.whenData` 回调中找到匹配的 Group 赋值给 `_selectedGroup`
  3. `_onSubmit()` 中区分模式：
     - 若 `reminderId != null`：调用 `repo.update(existing.copyWith(...))`
     - 若 `reminderId == null`：调用 `repo.insert(Reminder(...))`

- **验收标准**：`flutter test test/unit/home/reminder_form_edit_test.dart` 全部通过
- **涉及文件**：`lib/src/feature/home/code/reminder_form_page.dart`（同上）

### 步骤 5：删除流程

- **内容**：
  1. 修改 `today_timeline.dart`：在 `_TimelineItem` 外层包裹 `Dismissible`
  2. `Dismissible` 参数：
     - `key: ValueKey(reminder.id)`
     - `direction: DismissDirection.endToStart`（仅左滑）
     - `background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: right 20, child: Icon(Icons.delete, color: Colors.white))`
     - `confirmDismiss: (direction) async { return await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('确定删除该提醒？'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认删除'))])); }`
     - `onDismissed: (_) { /* 调用 repository.delete */ }`
  3. 注入 `reminderRepositoryProvider` 调用 `delete(reminder.id)`
  4. 删除后通过 `ref.invalidate(todayRemindersProvider)` 刷新列表
  5. `TodayTimeline` 添加 `onDelete` 回调：`final Future<void> Function(int reminderId)? onDelete`

- **验收标准**：`flutter test test/unit/home/today_timeline_delete_test.dart` 全部通过
- **涉及文件**：`lib/src/feature/home/code/today_timeline.dart`（修改）

### 步骤 6：重复提醒配置

- **内容**：
  1. 表单页 `_selectedFrequency` 初始值 `ReminderFrequency.once`
  2. `SegmentedButton<ReminderFrequency>`：
     ```dart
     SegmentedButton<ReminderFrequency>(
       segments: ReminderFrequency.values.map((f) =>
         ButtonSegment<ReminderFrequency>(
           value: f,
           label: Text(f.displayName),
         ),
       ).toList(),
       selected: {_selectedFrequency},
       onSelectionChanged: (set) => setState(() => _selectedFrequency = set.first),
     )
     ```
  3. 编辑模式回显：从 `reminder.frequency` 赋值

- **验收标准**：`flutter test test/unit/home/reminder_frequency_test.dart` 全部通过
- **涉及文件**：`lib/src/feature/home/code/reminder_form_page.dart`（同上）

### 步骤 7：Barrel file + 布线

- **内容**：
  1. 更新 `lib/src/feature/home/home.dart`：
     - 删除 `export 'code/add_reminder_page.dart';`
     - 添加 `export 'code/reminder_form_page.dart';`
  2. 修改 `home_page.dart` 中 `TodayTimeline` 的 `onTap`：
     - 手机布局：`onTap: (reminderId) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReminderFormPage(reminderId: reminderId)))`
     - 平板布局同
  3. 删除旧文件 `lib/src/feature/home/code/add_reminder_page.dart`
  4. 运行 `dart run build_runner build --delete-conflicting-outputs` 确认无生成冲突

- **验收标准**：`flutter analyze lib/src/feature/home/` 零 warning，全量 `flutter test` 通过
- **涉及文件**：`lib/src/feature/home/home.dart`（修改），`lib/src/feature/home/code/home_page.dart`（修改）

---

## 关键设计决策

| # | 决策 | 理由 |
|---|------|------|
| 1 | 表单页直接使用 `ReminderRepository` 而非 `ReminderService` | `ReminderService.createReminder` 有独立参数校验逻辑，可能重复报错；直接仓库层更简洁，且已在 `_validateForm` 中覆盖所有校验 |
| 2 | 编辑模式通过构造参数 `reminderId` 区分，而非路由参数 | Material PageRoute 传参更直接，避免 GoRouter 的 extra/path 参数耦合 |
| 3 | 时间选择用 `showDatePicker` + 链式 `showTimePicker` | 需求未要求 CupertinoDatePicker 独立使用，Material picker 跨平台一致且测试 mock 简单 |
| 4 | `Dismissible.confirmDismiss` 返回 `Future<bool>` 控制 | 标准 Flutter 模式：确认弹窗返回 true 才执行 onDismissed，取消返回 false 则回弹 |
| 5 | `TodayTimeline` 不直接依赖 Provider，通过 `onDelete` 回调 | 保持组件可测试性，Provider 依赖放在 `HomePage` 层 |

---

## 依赖

<!-- 外部库、工具、或必须先完成的模块 -->

| 依赖 | 类型 | 说明 |
|------|------|------|
| `flutter_riverpod` | 外部库 | 已在 pubspec.yaml 中，用于读取 `reminderRepositoryProvider`/`groupRepositoryProvider` |
| `intl` | 外部库 | 已在 pubspec.yaml 中，用于日期格式化 `DateFormat('yyyy-MM-dd HH:mm')` |
| `ReminderRepository` (F-02) | 模块 | insert/update/delete/getById/getAll |
| `GroupRepository` (F-02) | 模块 | getAll |
| `Reminder` 模型 (F-01) | 模块 | copyWith/构造/字段 |
| `Group` 模型 (F-01) | 模块 | 字段访问 |
| `ReminderFrequency` / `ReminderStatus` 枚举 (F-01) | 模块 | 枚举值 + displayName |
| `home_providers.dart` (F-07) | 模块 | Provider 引用 |

---

## 排除项

<!-- 明确本次不做，防止 overflow -->

1. **不做** CupertinoDatePicker 平台自适应——统一 Material `showDatePicker` + `showTimePicker`
2. **不做** 表单页平板双列布局——仅首页需要响应式
3. **不做** 分组下拉中创建新分组——属于 F-11 范围
4. **不做** 语音录入跳转——FAB "语音录入" 由 F-10 负责
5. **不做** 删除后 Undo SnackBar——需求未提及
6. **不做** 重复提醒的自动调度——频率仅存储，调度由 F-05 `ReminderScheduler` 处理
7. **不做** 表单页的 `TextEditingController` dispose 外泄——`dispose()` 中必须调用 `_titleController.dispose()` 和 `_contentController.dispose()`
