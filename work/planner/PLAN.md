# 实现方案

<!-- 由 planner 填写。implementer 据此实现。 -->

---

## 基本信息

- **功能 ID**：F-07
- **功能名称**：feature/home 首页

---

## 涉及模块

| 模块 | 变更类型 | 说明 |
|------|---------|------|
| feature/home | 新建 | 首页全部代码（providers + widgets + barrel file） |
| router | 修改 | 在 app_router.dart 中注册首页路由 |

---

## 实现步骤

<!-- 按顺序排列 -->

### 步骤 1：HOME-01 — 首页 Riverpod Provider

- **内容**：
  - 创建 `lib/src/feature/home/code/home_providers.dart`
  - `groupsProvider`：`FutureProvider.autoDispose<List<Group>>`，从 `GroupRepository`（通过 `ref.watch(groupRepositoryProvider)`）获取 `getAllGroups()`，按 `sortOrder` ASC 排序
  - `todayRemindersProvider`：`FutureProvider.autoDispose<List<Reminder>>`，从 `ReminderRepository` 获取今日待办（`getTodayReminders()`），按 `scheduledAt` ASC 排序
  - `filterProvider`：`StateProvider<ReminderStatus?>`，初始值 `null`（表示"全部"）
  - `filteredRemindersProvider`：`Provider.autoDispose<List<Reminder>>`，根据 `filterProvider` 过滤 `todayRemindersProvider`：
    - filter 为 null → 返回全部
    - filter 为具体值 → `where((r) => r.status == filter).toList()`
- **验收标准**：`flutter analyze lib/src/feature/home/` 零 warning
- **涉及文件**：`lib/src/feature/home/code/home_providers.dart`

### 步骤 2：HOME-02 — 页面头部组件

- **内容**：
  - 创建 `lib/src/feature/home/code/home_header.dart`
  - `HomeHeader` StatelessWidget
  - 使用 `intl` 包 `DateFormat('yyyy年M月d日')` 格式化 `DateTime.now()`
  - 中文星期映射：`{'Monday': '星期一', ...}`，使用 `DateFormat('EEEE')` 获取英文星期再映射
  - 右侧：`Row([Icon(Icons.cloud_outlined), SizedBox(width: 4), Text('--°')])`
  - 布局：`Padding(padding: EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dateColumn, weatherPlaceholder]))`
- **验收标准**：`flutter test test/unit/home/home_header_test.dart` 全部通过
- **涉及文件**：`lib/src/feature/home/code/home_header.dart`

### 步骤 3：HOME-03 — 分组概览卡片

- **内容**：
  - 创建 `lib/src/feature/home/code/group_overview_card.dart`
  - `GroupOverviewCard` StatelessWidget，接收 `Group group, int pendingCount, int completedCount`
  - 图标映射：`_iconFor(String? iconName)` 函数，返回 `IconData`，映射表包含常用 kitchen/living/bedroom/cleaning 等
  - `CompletionRingPainter`：`CustomPainter`，画圆弧（`canvas.drawArc`），背景弧灰色 270°（3/4 圈），前景弧蓝色（比例=完成率），中心文字显示 percentage
  - 完成率计算：`total = pendingCount + completedCount; ratio = total > 0 ? completedCount / total : 0.0`
  - 待办 Badge：`Container(decoration: BoxDecoration(color: red, shape: BoxShape.circle), child: Text('$pendingCount'))`
  - 卡片样式：`SizedBox(width: 140, child: Card(child: Padding(padding: 12, child: Column(...))))`
- **验收标准**：`flutter test test/unit/home/group_overview_card_test.dart` 全部通过
- **涉及文件**：`lib/src/feature/home/code/group_overview_card.dart`

### 步骤 4：HOME-04 — 分组卡片横向列表

- **内容**：
  - 创建 `lib/src/feature/home/code/group_overview_bar.dart`
  - `GroupOverviewBar` StatelessWidget，接收 `AsyncValue<List<Group>> groups`
  - 使用 `SizedBox(height: 130, child: ...)`
  - loading 态：`Center(child: SizedBox(width: 130, height: 110, child: Card(child: Center(child: CircularProgressIndicator()))))`
  - 有数据：`ListView.builder(scrollDirection: Axis.horizontal, padding: EdgeInsets.symmetric(horizontal: 8), itemCount: groups.length, itemBuilder: (_, i) => Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: GroupOverviewCard(...)))`
  - 空数据：显示单个占位卡片 '暂无分组'
  - 需要计算每个分组的 pending/completed counts：通过 provider 获取（或接收 `Map<int, int>` pendingCounts 参数）
- **验收标准**：`flutter test test/unit/home/group_overview_bar_test.dart` 全部通过
- **涉及文件**：`lib/src/feature/home/code/group_overview_bar.dart`

### 步骤 5：HOME-05 — 今日待办时间线列表

- **内容**：
  - 创建 `lib/src/feature/home/code/today_timeline.dart`
  - `TodayTimeline` StatelessWidget，接收 `List<Reminder> reminders, Map<int, Group> groupMap, void Function(int reminderId)? onTap`
  - 时间提取：`DateFormat('HH:mm').format(reminder.scheduledAt)`
  - 分组色条：`Color _colorForGroup(int groupId)`，`HSLColor.fromAHSL(1.0, (groupId * 47) % 360, 0.6, 0.5).toColor()`
  - 时间轴：左侧 `Column([Container(width: 2, height: 12, color: grey), Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: primary)), Container(width: 2, height: 12, color: grey)])`，注意首尾项处理（首项无上线段，末项无下线段）
  - 卡片内容：`Row([Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, [Text(reminder.title), if (reminder.content != null) Text(reminder.content!)])), Container(width: 4, color: groupColor)])`
  - 列表：`ListView.builder(itemCount: reminders.length)`
  - 空列表：显示空状态文本 '今日暂无待办'
- **验收标准**：`flutter test test/unit/home/today_timeline_test.dart` 全部通过
- **涉及文件**：`lib/src/feature/home/code/today_timeline.dart`

### 步骤 6：HOME-06 — 状态筛选 TabBar

- **内容**：
  - 创建 `lib/src/feature/home/code/status_filter_bar.dart`
  - `StatusFilterBar` StatelessWidget，接收 `ReminderStatus? selected, void Function(ReminderStatus?) onChanged`
  - 选项列表：`[null(全部), ReminderStatus.pending(待处理), ReminderStatus.overdue(已过期), ReminderStatus.completed(已完成)]`
  - 标签映射：`_labelFor(ReminderStatus?)` → '全部' / '待处理' / '已过期' / '已完成'
  - 使用 `Wrap(spacing: 8, children: options.map((s) => ChoiceChip(label: Text(_labelFor(s)), selected: selected == s, onSelected: (_) => onChanged(s))).toList())`
  - 选中色：`selectedColor: Colors.blue.shade100`
- **验收标准**：`flutter test test/unit/home/status_filter_bar_test.dart` 全部通过
- **涉及文件**：`lib/src/feature/home/code/status_filter_bar.dart`

### 步骤 7：HOME-07 — 空状态组件

- **内容**：
  - 创建 `lib/src/feature/home/code/empty_home_view.dart`
  - `EmptyHomeView` StatelessWidget
  - 布局：`Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.home_outlined, size: 64, color: Colors.grey.shade400), SizedBox(height: 16), Text('还没有提醒', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)), SizedBox(height: 8), Text('点击下方 + 添加', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)), SizedBox(height: 80)]))`
- **验收标准**：`flutter test test/unit/home/empty_home_view_test.dart` 全部通过
- **涉及文件**：`lib/src/feature/home/code/empty_home_view.dart`

### 步骤 8：HOME-08 — FAB 展开菜单

- **内容**：
  - 创建 `lib/src/feature/home/code/home_fab.dart`
  - `HomeFab` StatefulWidget
  - 展开/收起状态：`_isExpanded` bool
  - 主按钮：`FloatingActionButton(onPressed: () => setState(() => _isExpanded = !_isExpanded), child: AnimatedRotation(turns: _isExpanded ? 0.125 : 0.0, duration: Duration(milliseconds: 200), child: Icon(Icons.add)))`
  - 子项（展开时显示在主按钮上方）：
    - `FloatingActionButton.small(heroTag: 'add', onPressed: () => navigator.pushNamed('/add'), child: Icon(Icons.edit_note))` + 标签 '手动添加'
    - `FloatingActionButton.small(heroTag: 'voice', onPressed: () => navigator.pushNamed('/voice'), child: Icon(Icons.mic))` + 标签 '语音录入'
  - 子项入场动画：`AnimatedSlide + AnimatedOpacity`
  - 使用 `Column(mainAxisSize: MainAxisSize.min, children: [if (_isExpanded) ...[voiceFab, sizedBox, addFab, sizedBox], mainFab])`
- **验收标准**：`flutter test test/unit/home/home_fab_test.dart` 全部通过
- **涉及文件**：`lib/src/feature/home/code/home_fab.dart`

### 步骤 9：HOME-09 — 首页组装 + 响应式布局

- **内容**：
  - 创建 `lib/src/feature/home/code/home_page.dart`
  - `HomePage` ConsumerStatefulWidget
  - 使用 `ref.watch(groupsProvider)`、`ref.watch(filteredRemindersProvider)`、`ref.watch(filterProvider)`
  - 构建分组映射：`Map<int, Group>` 从 groupsProvider 数据构建
  - `RefreshIndicator(onRefresh: () async { ref.invalidate(groupsProvider); ref.invalidate(todayRemindersProvider); await Future.delayed(Duration(milliseconds: 300)); }, child: ...)`
  - `LayoutBuilder(builder: (context, constraints) { if (constraints.maxWidth > 600) return _buildTabletLayout(...); else return _buildPhoneLayout(...); })`
  - 手机布局（单列）：`SingleChildScrollView(child: Column(children: [HomeHeader(), GroupOverviewBar(...), StatusFilterBar(...), TodayTimeline(...)]))`
  - 平板布局（双列）：`Row(children: [Expanded(flex: 1, child: Column(children: [HomeHeader(), GroupOverviewBar(...), StatusFilterBar(...)])), Expanded(flex: 1, child: TodayTimeline(...))])`
  - 数据为空 → 显示 `EmptyHomeView`
  - loading → `Center(child: CircularProgressIndicator())`
  - error → `Center(child: Column(children: [Text('加载失败'), ElevatedButton(onPressed: ref.invalidate, child: Text('重试'))]))`
  - Scaffold: `floatingActionButton: HomeFab()`
- **验收标准**：`flutter test test/unit/home/home_page_test.dart` 全部通过
- **涉及文件**：`lib/src/feature/home/code/home_page.dart`

### 步骤 10：HOME-10 — barrel file + 路由注册

- **内容**：
  - 创建 `lib/src/feature/home/home.dart`：
    ```dart
    library;
    export 'code/home_providers.dart';
    export 'code/home_header.dart';
    export 'code/group_overview_card.dart';
    export 'code/group_overview_bar.dart';
    export 'code/today_timeline.dart';
    export 'code/status_filter_bar.dart';
    export 'code/empty_home_view.dart';
    export 'code/home_fab.dart';
    export 'code/home_page.dart';
    ```
  - 在 `lib/src/router/app_router.dart` 中注册路由：
    - 添加 `import 'package:home_reminder/src/feature/home/home.dart';`
    - 确保首页路由为 `GoRoute(path: '/', builder: (_, state) => const HomePage())`
    - 添加 `/add` 和 `/voice` 占位路由（指向临时占位页面或 Navigator.pushNamed 检查）
- **验收标准**：`flutter analyze lib/src/feature/home/` 零 warning && 路由测试通过
- **涉及文件**：
  - `lib/src/feature/home/home.dart`
  - `lib/src/router/app_router.dart`（修改）

---

## 依赖

<!-- 外部库、工具、或必须先完成的模块 -->

| 依赖 | 类型 | 说明 |
|------|------|------|
| flutter_riverpod | 外部库（已存在） | 状态管理和 Provider |
| intl | 外部库（已存在） | 日期格式化 |
| core/common（F-01） | 模块（已完成） | Group/Reminder 模型、ReminderStatus 枚举 |
| core/database（F-02） | 模块（已完成） | GroupRepository、ReminderRepository |
| core/providers（F-03） | 模块（已完成） | groupRepositoryProvider、reminderRepositoryProvider |
| core/reminder（F-05） | 模块（已完成） | ReminderService（getTodayReminders） |
| router（F-04） | 模块（已完成） | GoRouter 路由注册 |

---

## 排除项

<!-- 明确本次不做，防止 overflow -->

1. **天气真实数据**：天气图标静态占位，不接入 API
2. **FAB 脉冲动画**：简单展开/收起，不做连续脉冲
3. **分组图标自定义**：Material Icons 预设映射，不提供选择器
4. **完成率动画**：环形进度条静态渲染，无数字变化动画
5. **列表项滑动操作**：留给 F-08
6. **通知点击跳转编辑页**：由 F-06 + router 处理
7. **暗黑模式**：仅 Material 默认主题
