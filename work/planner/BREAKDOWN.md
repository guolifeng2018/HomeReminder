# 功能拆分

<!-- 由 planner 填写。implementer 据此分配工作单元。 -->

---

## 基本信息

- **功能 ID**：F-07
- **功能名称**：feature/home 首页
- **涉及模块**：feature/home（新建）、router（修改路由注册）

---

## 工作单元

<!-- 每个单元 = 单一行为 + 可执行验证命令 + 依赖关系 -->

| # | 单元名称 | 描述 | 验证命令 | 依赖 | 状态 |
|---|---------|------|---------|------|------|
| 1 | HOME-01：首页 Riverpod Provider | 创建 `home_providers.dart`：`groupsProvider`（FutureProvider 从 GroupRepository 获取分组列表，按 sort_order ASC），`todayRemindersProvider`（FutureProvider 从 ReminderRepository 获取今日待办，按 scheduled_at ASC），`filterProvider`（StateProvider<ReminderStatus?>，null=全部，否则按 status 筛选），`filteredRemindersProvider`（派生 provider，根据 filterProvider 过滤 todayRemindersProvider） | `flutter analyze lib/src/feature/home/` 零 warning | F-02, F-03 | pending |
| 2 | HOME-02：页面头部组件 | 创建 `home_header.dart`：StatelessWidget，显示当前日期（intl DateFormat 'yyyy年M月d日' + 中文星期映射 '星期X'），右侧天气图标占位（Icon+文字 '--°'），使用 `Padding + Row` 布局 | `flutter test test/unit/home/home_header_test.dart` | 无 | pending |
| 3 | HOME-03：分组概览卡片 | 创建 `group_overview_card.dart`：StatelessWidget，接收 Group + pendingCount + completedCount，卡片内显示分组名+图标（Icons 映射）+ 待办数量 Badge + 完成率环形进度（CustomPainter 画圆弧，半径 24，完成率 = completedCount / total > 0 ? completedCount / total : 0），卡片宽度 140，使用 `Card + Column` | `flutter test test/unit/home/group_overview_card_test.dart` | HOME-01 | pending |
| 4 | HOME-04：分组卡片横向列表 | 创建 `group_overview_bar.dart`：StatelessWidget，接收 `AsyncValue<List<Group>>`，使用 `SizedBox(height: 130, child: ListView.builder(scrollDirection: Axis.horizontal))`，每个卡片调用 `GroupOverviewCard`，如果分组列表为空则显示占位卡片 '暂无分组' | `flutter test test/unit/home/group_overview_bar_test.dart` | HOME-01, HOME-03 | pending |
| 5 | HOME-05：今日待办时间线列表 | 创建 `today_timeline.dart`：StatelessWidget，接收 `List<Reminder> + Map<int, Group>`（groupId → Group 映射），使用 `ListView.builder`，每项左边时间轴（竖线+圆点，按 scheduled_at 提取 HH:mm）+ 右边卡片（标题+分组色条，色条颜色根据 groupId hash 取 hue），点击回调 `onTap(reminderId)` | `flutter test test/unit/home/today_timeline_test.dart` | HOME-01 | pending |
| 6 | HOME-06：状态筛选 TabBar | 创建 `status_filter_bar.dart`：StatelessWidget，接收当前 `ReminderStatus?` 和 `onChanged` 回调，4 个 `ChoiceChip`（全部/待处理/已过期/已完成），横向排列，选中态蓝色高亮 | `flutter test test/unit/home/status_filter_bar_test.dart` | 无 | pending |
| 7 | HOME-07：空状态组件 | 创建 `empty_home_view.dart`：StatelessWidget，居中显示 Icon(house, size: 64, color: grey)、文本 '还没有提醒'、副文本 '点击下方 + 添加'，底部留出 FAB 空间（SizedBox height: 80） | `flutter test test/unit/home/empty_home_view_test.dart` | 无 | pending |
| 8 | HOME-08：FAB 展开菜单 | 创建 `home_fab.dart`：StatefulWidget，使用 `Scaffold.floatingActionButton` 集成，主按钮点击展开/收起两个子项（Icons.add → '/add', Icons.mic → '/voice'），展开时主按钮旋转 45° 动画，使用 `AnimatedContainer + Transform.rotate` | `flutter test test/unit/home/home_fab_test.dart` | 无 | pending |
| 9 | HOME-09：首页组装 + 响应式布局 | 创建 `home_page.dart`：ConsumerStatefulWidget，组合 HOME-02~08 所有子组件，使用 `RefreshIndicator` 包裹整体（onRefresh 触发 provider invalidate），`LayoutBuilder` 判断 `maxWidth > 600` → 平板双列（左侧分组卡片+筛选，右侧时间线），否则手机单列（垂直排列分组卡片→筛选→时间线），loading 态显示 `CircularProgressIndicator`，error 态显示错误文本+重试按钮 | `flutter test test/unit/home/home_page_test.dart` | HOME-02~08 | pending |
| 10 | HOME-10：barrel file + 路由注册 | 创建 `lib/src/feature/home/home.dart` barrel file（导出 HOME-01~09 公开 API）；在 `lib/src/router/app_router.dart` 中注册首页路由（`GoRoute(path: '/', builder: (_, __) => const HomePage())`），确保首页为默认路由 | `flutter analyze lib/src/feature/home/` 零 warning && `flutter test test/unit/router/` 首页路由测试通过 | HOME-09 | pending |

---

## 依赖拓扑

```
HOME-02（页面头部）────────────┐
HOME-03（分组卡片）────┐       │
HOME-04（卡片列表）←──┘       │
HOME-05（时间线列表）          │
HOME-06（状态筛选）            ├──→ HOME-09（首页组装）──→ HOME-10（barrel + 路由）
HOME-07（空状态组件）          │
HOME-08（FAB 展开菜单）────────┘
HOME-01（Provider）──── 数据源 ┘
```

- HOME-02/06/07/08 可并行开发（无相互依赖）
- HOME-03 可独立开发（接收参数即可测试）
- HOME-04 依赖 HOME-01 + HOME-03
- HOME-05 依赖 HOME-01
- HOME-09 需等 HOME-02~08 全部完成
- HOME-10 需等 HOME-09 完成

---

## 排除项

<!-- 本次明确不做的内容，防止 implementer overreach -->

1. **不实现天气真实数据**：天气图标为静态占位（Icon cloud + 文字 '--°'），不接入天气 API
2. **不实现 FAB 脉冲动画**：首次实现用简单展开/收起动画，脉冲动画（连续放大缩小）留给后续优化
3. **不实现分组图标自定义**：图标使用 Material Icons 预设映射表（按 group.icon 字段映射），不做图标选择器
4. **不实现完成率动画**：环形进度条为静态渲染，不做数字变化动画
5. **不实现列表项滑动操作**：滑动删除/完成留给 F-08（手动录入流程）统一处理
6. **不实现深层链接通知跳转**：通知点击跳转编辑页的逻辑由 F-06 的 `onSelectNotification` + router 处理，不在 F-07 范围
7. **不实现暗黑模式**：F-07 仅实现 Material 默认主题，暗黑模式适配留给后续
