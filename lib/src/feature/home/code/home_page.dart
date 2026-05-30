/// 首页
///
/// ConsumerStatefulWidget，组装所有首页子组件，支持响应式布局和下拉刷新。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/common/code/models/group_model.dart';
import '../../../core/common/code/models/reminder_model.dart';
import '../../../core/common/code/models/enums.dart';
import 'home_providers.dart';
import 'home_header.dart';
import 'group_overview_bar.dart';
import 'today_timeline.dart';
import 'status_filter_bar.dart';
import 'empty_home_view.dart';
import 'home_fab.dart';
import 'reminder_form_page.dart';
import '../../../core/providers/providers.dart';

/// 首页
///
/// 组合 HOME-02~08 所有子组件，响应式布局（手机单列 / 平板双列）。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// 下拉刷新
  Future<void> _onRefresh() async {
    ref.invalidate(groupsProvider);
    ref.invalidate(todayRemindersProvider);
    // 等待数据重新加载
    await ref.read(groupsProvider.future);
    // 不等待 todayRemindersProvider 以避免阻塞 UI
  }

  /// 从今日待办计算每分组 pending/completed 计数
  Map<int, int> _computePendingCounts(List<Reminder> reminders) {
    final counts = <int, int>{};
    for (final r in reminders) {
      if (r.status == ReminderStatus.pending || r.status == ReminderStatus.overdue) {
        counts[r.groupId] = (counts[r.groupId] ?? 0) + 1;
      }
    }
    return counts;
  }

  Map<int, int> _computeCompletedCounts(List<Reminder> reminders) {
    final counts = <int, int>{};
    for (final r in reminders) {
      if (r.status == ReminderStatus.completed) {
        counts[r.groupId] = (counts[r.groupId] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// 处理删除提醒
  Future<bool> _onDelete(int reminderId) async {
    try {
      final repo = ref.read(reminderRepositoryProvider);
      await repo.delete(reminderId);
      ref.invalidate(todayRemindersProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);
    final remindersAsync = ref.watch(filteredRemindersProvider);
    final filter = ref.watch(filterProvider);

    return Scaffold(
      floatingActionButton: const HomeFab(),
      body: _buildBody(groupsAsync, remindersAsync, filter),
    );
  }

  Widget _buildBody(
    AsyncValue<List<Group>> groupsAsync,
    AsyncValue<List<Reminder>> remindersAsync,
    ReminderStatus? filter,
  ) {
    // 同时加载中
    if (groupsAsync.isLoading && remindersAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 任一出错
    if (groupsAsync.hasError || remindersAsync.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '加载失败',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(groupsProvider);
                ref.invalidate(todayRemindersProvider);
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final groups = groupsAsync.valueOrNull ?? [];
    final reminders = remindersAsync.valueOrNull ?? [];

    // 空数据
    if (groups.isEmpty && reminders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          children: const [EmptyHomeView()],
        ),
      );
    }

    // 计算分组映射和计数
    final groupMap = {for (final g in groups) g.id: g};
    // 从今日全部待办计算计数（而非筛选后）
    final allRemindersAsync = ref.watch(todayRemindersProvider);
    final allReminders = allRemindersAsync.valueOrNull ?? [];
    final pendingCounts = _computePendingCounts(allReminders);
    final completedCounts = _computeCompletedCounts(allReminders);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return _buildTabletLayout(
              groupsAsync,
              reminders,
              groupMap,
              pendingCounts,
              completedCounts,
              filter,
            );
          } else {
            return _buildPhoneLayout(
              groupsAsync,
              reminders,
              groupMap,
              pendingCounts,
              completedCounts,
              filter,
            );
          }
        },
      ),
    );
  }

  /// 手机布局：单列垂直排列
  Widget _buildPhoneLayout(
    AsyncValue<List<Group>> groupsAsync,
    List<Reminder> reminders,
    Map<int, Group> groupMap,
    Map<int, int> pendingCounts,
    Map<int, int> completedCounts,
    ReminderStatus? filter,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeHeader(),
          GroupOverviewBar(
            groups: groupsAsync,
            pendingCounts: pendingCounts,
            completedCounts: completedCounts,
          ),
          StatusFilterBar(
            selected: filter,
            onChanged: (v) => ref.read(filterProvider.notifier).state = v,
          ),
          TodayTimeline(
            reminders: reminders,
            groupMap: groupMap,
            onTap: (reminderId) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReminderFormPage(reminderId: reminderId),
                ),
              );
            },
            onDelete: _onDelete,
          ),
        ],
      ),
    );
  }

  /// 平板布局：双列（左侧分组 + 筛选，右侧时间线）
  Widget _buildTabletLayout(
    AsyncValue<List<Group>> groupsAsync,
    List<Reminder> reminders,
    Map<int, Group> groupMap,
    Map<int, int> pendingCounts,
    Map<int, int> completedCounts,
    ReminderStatus? filter,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧列：头部 + 分组卡片 + 筛选
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeHeader(),
                GroupOverviewBar(
                  groups: groupsAsync,
                  pendingCounts: pendingCounts,
                  completedCounts: completedCounts,
                ),
                StatusFilterBar(
                  selected: filter,
                  onChanged: (v) =>
                      ref.read(filterProvider.notifier).state = v,
                ),
              ],
            ),
          ),
        ),
        // 分割线
        const VerticalDivider(width: 1),
        // 右侧列：时间线
        Expanded(
          flex: 1,
          child: TodayTimeline(
            reminders: reminders,
            groupMap: groupMap,
            onTap: (reminderId) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReminderFormPage(reminderId: reminderId),
                ),
              );
            },
            onDelete: _onDelete,
          ),
        ),
      ],
    );
  }
}
