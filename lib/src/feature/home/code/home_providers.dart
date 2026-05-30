/// 首页 Riverpod Provider
///
/// 提供首页所需的数据查询、状态筛选等 Provider。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/common/code/models/group_model.dart';
import '../../../core/common/code/models/reminder_model.dart';
import '../../../core/common/code/models/enums.dart';

/// 分组列表 Provider
///
/// 从 GroupRepository 获取全部分组，按 sortOrder ASC 排序。
final groupsProvider = FutureProvider.autoDispose<List<Group>>((ref) async {
  final repo = ref.watch(groupRepositoryProvider);
  final groups = await repo.getAll();
  // 按 sortOrder 升序排列（repository 已排序，此处确保）
  groups.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return groups;
});

/// 今日待办 Provider
///
/// 从 ReminderRepository 获取今日提醒，按 scheduledAt ASC 排序。
final todayRemindersProvider =
    FutureProvider.autoDispose<List<Reminder>>((ref) async {
  final repo = ref.watch(reminderRepositoryProvider);
  final reminders = await repo.getToday();
  reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  return reminders;
});

/// 筛选状态 Provider
///
/// null = 显示全部；非 null = 按指定状态筛选。
final filterProvider = StateProvider<ReminderStatus?>((ref) => null);

/// 筛选后的今日待办 Provider
///
/// 根据 [filterProvider] 的值过滤 [todayRemindersProvider] 结果。
final filteredRemindersProvider =
    Provider.autoDispose<AsyncValue<List<Reminder>>>((ref) {
  final filter = ref.watch(filterProvider);
  final remindersAsync = ref.watch(todayRemindersProvider);

  if (filter == null) {
    return remindersAsync;
  }

  return remindersAsync.whenData((reminders) {
    return reminders.where((r) => r.status == filter).toList();
  });
});
