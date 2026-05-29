/// ReminderScheduler — 定时调度引擎
///
/// 核心职责：
/// 1. 根据频率计算下次触发时间
/// 2. 扫描并标记过期提醒
///
/// 纯时间计算，不注册系统闹钟（由 F-06 notification 使用计算结果执行）。
library;

import 'package:home_reminder/src/core/common/code/models/enums.dart';
import 'package:home_reminder/src/core/database/code/reminder_repository.dart';

class ReminderScheduler {
  const ReminderScheduler();

  /// 根据频率计算下次触发时间
  ///
  /// [scheduledAt] 当前调度时间。
  /// [frequency] 重复频率。
  ///
  /// - once: 返回原时间
  /// - daily: +1 天
  /// - weekly: +7 天
  /// - biweekly: +14 天
  /// - monthly: +1 月（安全处理月末溢出）
  DateTime nextTriggerTime(DateTime scheduledAt, ReminderFrequency frequency) {
    switch (frequency) {
      case ReminderFrequency.once:
        return scheduledAt;
      case ReminderFrequency.daily:
        return DateTime(
          scheduledAt.year, scheduledAt.month, scheduledAt.day + 1,
          scheduledAt.hour, scheduledAt.minute,
        );
      case ReminderFrequency.weekly:
        return DateTime(
          scheduledAt.year, scheduledAt.month, scheduledAt.day + 7,
          scheduledAt.hour, scheduledAt.minute,
        );
      case ReminderFrequency.biweekly:
        return DateTime(
          scheduledAt.year, scheduledAt.month, scheduledAt.day + 14,
          scheduledAt.hour, scheduledAt.minute,
        );
      case ReminderFrequency.monthly:
        return _addMonthSafe(scheduledAt, 1);
    }
  }

  /// 安全加月 — 处理月末溢出（如 1/31 → 2/28 或 2/29）
  DateTime _addMonthSafe(DateTime dt, int months) {
    final targetMonth = dt.month + months;
    final year = dt.year + (targetMonth - 1) ~/ 12;
    final month = (targetMonth - 1) % 12 + 1;
    final lastDay = _lastDayOfMonth(year, month);
    final safeDay = dt.day > lastDay ? lastDay : dt.day;
    return DateTime(year, month, safeDay, dt.hour, dt.minute);
  }

  int _lastDayOfMonth(int year, int month) {
    if (month == 12) return 31;
    return DateTime(year, month + 1, 0).day;
  }

  /// 判断提醒是否过期
  bool isOverdue(DateTime scheduledAt, {DateTime? now}) {
    final current = now ?? DateTime.now();
    return scheduledAt.isBefore(current);
  }

  /// 是否应跳过调度（已完成/dismissed 不参与调度）
  bool shouldSkip(ReminderStatus status) {
    return status == ReminderStatus.completed ||
        status == ReminderStatus.dismissed;
  }

  /// 扫描过期提醒并标记为 overdue
  ///
  /// 查询 status=pending 且 scheduledAt < now 的提醒，
  /// 批量更新状态为 overdue。返回更新的提醒数量。
  Future<int> findOverdue(ReminderRepository repo) async {
    final overdue = await repo.getOverdue();
    int count = 0;

    for (final r in overdue) {
      if (shouldSkip(r.status)) continue;

      if (r.status == ReminderStatus.pending) {
        final updated = r.copyWith(
          status: ReminderStatus.overdue,
          updatedAt: DateTime.now(),
        );
        await repo.update(updated);
        count++;
      }
    }

    return count;
  }
}
