# 功能拆分

<!-- 由 planner 填写。implementer 据此分配工作单元。 -->

---

## 基本信息

- **功能 ID**：F-08
- **功能名称**：手动录入流程
- **涉及模块**：feature/home, router

---

## 工作单元

<!-- 每个单元 = 单一行为 + 可执行验证命令 + 依赖关系 -->

| # | 单元名称 | 描述 | 验证命令 | 依赖 | 状态 |
|---|---------|------|---------|------|------|
| 1 | 修复 GoRouter /add 路由 | 将 app_router.dart 中 `/add` 路由从 placeholder stub `AddReminderPage` 替换为真实的 `ReminderFormPage`（导入 `feature/home/code/reminder_form_page.dart`）。移除 `placeholder_pages.dart` 中不再需要的 `AddReminderPage` 引用。 | `flutter analyze lib/src/router/ 零 warning` | 无（F-02/F-05/F-07 已完成） | done |
| 2 | 首页表单返回后自动刷新 | 修改 `home_page.dart`：列表项 `onTap` 回调中 `await Navigator.push` 结果；若结果为 `true`，调用 `ref.invalidate(todayRemindersProvider)` 和 `ref.invalidate(groupsProvider)` 触发数据重新加载。同样处理平板布局中的列表项 onTap。修改 `home_fab.dart`：将 `_navigate` 方法改为接受回调，或直接使用 `Navigator.push` 推入 `ReminderFormPage`，使首页能监听返回结果并刷新。 | `flutter analyze lib/src/feature/home/ 零 warning && flutter test test/unit/home/ 全部通过` | #1 | done |
| 3 | 最终验证门禁 | 运行全量静态分析 + 单元测试确保零 regression。 | `flutter analyze lib/src/feature/home/ 零 warning && flutter test test/unit/home/ 全部通过` | #1, #2 | done |

---

## 依赖拓扑

```
#1（路由修复）──→ #2（首页刷新）──→ #3（最终验证）
```

---

## 排除项

<!-- 本次明确不做的内容，防止 implementer overreach -->

1. CupertinoDatePicker 平台自适应 — F-08 描述中 "CupertinoDatePicker/DatePicker" 表示二者择一即可，当前 Material `showDatePicker` + `showTimePicker` 已满足需求，不额外引入 `CupertinoDatePicker`。
2. 集成测试（integration_test）新增 — F-08 verification 中提到的集成测试在 `test/integration/` 目录（当前为空），由后续 F-19 统一编写 E2E 测试，不在本功能范围内。
3. 删除提醒功能修改 — 删除功能已在 `today_timeline.dart` 中通过 `Dismissible` + `AlertDialog` 完整实现（背景红色删除图标 + 确认弹窗 "确定删除该提醒？"），无需新增文件。
4. 重复提醒后续调度逻辑 — F-08 仅负责表单中频率选项的存储（`ReminderFrequency` 枚举值写入数据库），具体的按频率自动创建下一次提醒的调度逻辑由 F-05（core/reminder）负责。
5. 表单页独立模块拆分 — `ReminderFormPage` 当前位于 `feature/home/code/`，属于 `feature/home` 模块，不拆分为独立 feature 模块。
