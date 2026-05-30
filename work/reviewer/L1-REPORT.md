# L1 静态分析报告

- **功能**：F-07（feature/home 首页）
- **日期**：2026-05-30
- **结果**：**PASS**

---

## 1. 全量 lint 检查

**命令**：`flutter analyze`

**输出摘要**：

```
Analyzing HomeReminder...

   info • The local variable '_fakeReminder' starts with an underscore •
   test/unit/reminder/reminder_service_test.dart:15:12 •
   no_leading_underscores_for_local_identifiers

1 issue found. (ran in 0.8s)
```

**判定**：1 个 info 级别提示，位于 `test/unit/reminder/reminder_service_test.dart:15`，**预存在**、非 F-07 引入、非 error/warning。CONSTRAINTS.md 要求「零报错 + 禁止 warnings 遗留」，此 info 不构成 warning，不阻塞通过。

---

## 2. 模块 lint 检查

**命令**：`flutter analyze lib/src/feature/home/`

**输出**：

```
Analyzing home...
No issues found! (ran in 0.7s)
```

**判定**：模块代码零问题。

---

## 3. 全局 CONSTRAINTS 检查

| # | 约束 | 结论 |
|---|------|------|
| 1 | 依赖方向 feature → core 不可逆，下层禁止 import 上层 | ✅ 通过 — `grep 'import.*feature' lib/src/core/` 零命中 |
| 2 | 必须使用 Riverpod，禁止 BLoC/GetX 等 | ✅ 通过 — 仅 `flutter_riverpod` import，无 bloc/getx |
| 3 | 禁止 Widget 直接访问 Drift | ✅ 通过 — `grep 'import.*drift\|database' lib/src/feature/home/` 零命中 |
| 4 | ASR/LLM 必须通过 Method Channel | ✅ N/A — F-07 不涉及 ASR/LLM |
| 5 | 禁止网络请求、数据上传 | ✅ 通过 — 无 http/dio import |
| 6 | 按需申请权限 | ✅ N/A — F-07 不涉及权限 |
| 7 | Android 10+ / iOS 15+ 兼容 | ✅ N/A — F-07 不涉及平台 API |
| 10 | flutter analyze 零报错 | ✅ 通过 — 模块零问题，全量仅 1 预存 info |

---

## 4. 模块 CONSTRAINTS 检查

| # | 约束 | 结论 |
|---|------|------|
| 1 | 禁止 Widget 直接访问 Drift，必须通过 Repository/Provider | ✅ 通过 — 数据访问全部通过 `home_providers.dart` 中的 Riverpod Provider |
| 2 | 必须使用 groupsProvider / todayRemindersProvider / filterProvider / filteredRemindersProvider | ✅ 通过 — 四个 Provider 均已定义并使用 |
| 3 | 所有 Widget 支持空状态渲染 | ✅ 通过 — HomePage（EmptyHomeView）、GroupOverviewBar（'暂无分组'）、TodayTimeline（'今日暂无待办'）均有空态 |
| 4 | 禁止业务逻辑写在 build() 中 | ✅ 通过 — 数据查询在 Provider 层，过滤在 filteredRemindersProvider |
| 5 | 分组卡片 ListView.builder 懒加载 | ✅ 通过 — `ListView.builder(scrollDirection: Axis.horizontal)` |
| 6 | 今日待办 ListView.builder 懒加载 | ✅ 通过 — `ListView.builder(shrinkWrap: true, NeverScrollableScrollPhysics)` |

---

## 5. 文件清单

| 文件 | 行数 | 状态 |
|------|------|------|
| `lib/src/feature/home/home.dart` | 12 | ✅ barrel file |
| `lib/src/feature/home/code/home_providers.dart` | 55 | ✅ 4 个 Provider |
| `lib/src/feature/home/code/home_header.dart` | 80 | ✅ 日期 + 天气占位 |
| `lib/src/feature/home/code/group_overview_card.dart` | 196 | ✅ 卡片 + CustomPainter |
| `lib/src/feature/home/code/group_overview_bar.dart` | 130 | ✅ 横向列表 |
| `lib/src/feature/home/code/today_timeline.dart` | 216 | ✅ 时间线列表 |
| `lib/src/feature/home/code/status_filter_bar.dart` | 66 | ✅ 4 tab ChoiceChip |
| `lib/src/feature/home/code/empty_home_view.dart` | 49 | ✅ 空状态组件 |
| `lib/src/feature/home/code/home_fab.dart` | 170 | ✅ FAB 展开菜单 |
| `lib/src/feature/home/code/home_page.dart` | 236 | ✅ 组装 + 响应式 |
| `lib/src/feature/home/code/add_reminder_page.dart` | 17 | ✅ F-08 占位页 |
