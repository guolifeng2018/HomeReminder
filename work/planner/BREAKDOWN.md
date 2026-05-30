# 功能拆分

<!-- 由 planner 填写。implementer 据此分配工作单元。 -->

---

## 基本信息

- **功能 ID**：F-08
- **功能名称**：手动录入流程
- **涉及模块**：feature/home（修改），core/common（依赖模型+枚举），core/database（依赖 ReminderRepository + GroupRepository），core/providers（依赖 Provider）

---

## 前置依赖（全部已完成）

| 依赖 ID | 名称 | 提供内容 |
|---------|------|---------|
| F-02 | core/database | `ReminderRepository.insert/update/delete/getById/getAll`，`GroupRepository.getAll/getById` |
| F-05 | core/reminder | `ReminderServiceImpl.createReminder`（含参数校验） |
| F-07 | feature/home | `HomePage`、`TodayTimeline`、`HomeFab`、`home_providers.dart`、`add_reminder_page.dart`（stub） |

---

## 工作单元

<!-- 每个单元 = 单一行为 + 可执行验证命令 + 依赖关系 -->

| # | 单元名称 | 描述 | 验证命令 | 依赖 | 状态 |
|---|---------|------|---------|------|------|
| 1 | ReminderFormPage UI | 替换 `add_reminder_page.dart` stub：完整表单 UI（标题 TextField maxLength=50、内容 multiline maxLength=200、分组 DropdownButton、日期时间选择器 DatePicker+TimePicker、频率 SegmentedButton 五个选项），接收可选 `reminderId` 参数区分新建/编辑模式，AppBar 标题根据模式显示"添加提醒"/"编辑提醒" | `flutter analyze lib/src/feature/home/code/reminder_form_page.dart` 零 warning；widget 测试验证 5 个表单字段正确渲染 | 无 | pending |
| 2 | 表单验证逻辑 | 标题非空校验（minLength=1→errorText），时间校验（scheduledAt ≤ DateTime.now() → SnackBar 提示"时间不能是过去"），分组必选校验（未选择→提交按钮 disabled + errorText），提交按钮在所有校验通过后才可点击 | `flutter test test/unit/home/reminder_form_validation_test.dart` — 覆盖 4 场景：空标题提交拦截、过去时间拦截、未选分组拦截、全部合法提交通过 | #1 | pending |
| 3 | 新建提交流程 | 表单验证通过后调用 `ReminderRepository.insert`（通过 `reminderRepositoryProvider`），成功后 `Navigator.pop(context, true)`，失败显示 SnackBar 错误信息；pop 后首页 `HomePage` 的 `groupsProvider`/`todayRemindersProvider` 通过 autoDispose 自动刷新 | `flutter test test/unit/home/reminder_form_submit_test.dart` — 模拟 repository 验证 insert 调用参数正确、pop 返回 true | #1, #2 | pending |
| 4 | 编辑流程 | 表单页接收可选 `reminderId`，编辑模式下从 `ReminderRepository.getById` 加载已有提醒预填充全部字段（title/content/groupId/scheduledAt/frequency），提交时调用 `ReminderRepository.update` 覆盖全部字段，pop(true)，字段预填充完全一致 | `flutter test test/unit/home/reminder_form_edit_test.dart` — 验证 5 字段预填充值与数据库记录完全一致，保存后调用 update 且字段正确 | #1, #2, #3 | pending |
| 5 | 删除流程 | `TodayTimeline` 每个列表项包裹 `Dismissible`：background=红色+删除图标，onDismissed 前弹出 `AlertDialog`（标题"确定删除该提醒？"，取消/确认两按钮），确认后调用 `ReminderRepository.delete` → 列表自动刷新 | `flutter test test/unit/home/today_timeline_delete_test.dart` — 4 场景：Dismissible 渲染正确、确认删除→repository.delete 调用、取消→列表不变、删除后列表-1 | #3 | pending |
| 6 | 重复提醒配置 | 表单页 SegmentedButton 五个选项（一次性/每天/每周/隔周/每月），映射 `ReminderFrequency` 枚举值，新建和编辑均正确保存和回显 | `flutter test test/unit/home/reminder_frequency_test.dart` — 验证 5 个选项渲染、选中值映射枚举正确、编辑回显正确 | #1 | pending |
| 7 | Barrel file 更新 | 更新 `home.dart` 导出 `reminder_form_page.dart`（替换旧的 `add_reminder_page.dart`），确保 `home_page.dart` 中 `TodayTimeline` 的 `onTap` 从 `null` 改为导航到编辑表单页 | `flutter analyze lib/src/feature/home/` 零 warning；`dart run build_runner build --delete-conflicting-outputs` 成功 | #4, #5 | pending |

---

## 依赖拓扑

```
#1 ──→ #2 ──→ #3 ──→ #4 ──→ #7
  │                        │
  └──→ #6 ────────────────┘
                #5 ────────┘

说明：
- #1（UI）是所有后续单元的基础
- #2（验证）依赖 #1 的表单结构
- #3（新建提交）依赖 #1+#2
- #4（编辑流程）依赖 #1+#2+#3（编辑复用表单+验证+提交逻辑，仅数据源不同）
- #5（删除流程）独立于表单，仅依赖 #3（需要理解 repository API）
- #6（频率配置）依赖 #1，与 #2-#4 并行
- #7（barrel+布线）依赖 #4+#5 完成
```

---

## 排除项

<!-- 本次明确不做的内容，防止 implementer overreach -->

1. **不做** CupertinoDatePicker 的 iOS/Android 自适应切换——统一使用 Material `DatePicker` + `TimePicker`（`showDatePicker` + `showTimePicker`），`ThemeData.platform` 自适应已由 Flutter 处理
2. **不做** 表单页的平板自适应布局——表单页保持手机单列布局，平板双列仅限首页
3. **不做** 分组下拉中创建新分组——新分组创建属于 F-11（feature/group_manage）范围
4. **不做** 语音录入跳转——FAB "语音录入"子项路由 `/voice` 由 F-10（feature/voice_input）负责
5. **不做** 删除提醒后的 Undo SnackBar——需求未提及，不画蛇添足
6. **不做** 重复提醒自动生成下一条——频率仅存储，自动调度由 F-05 ReminderScheduler 处理，不在表单层
