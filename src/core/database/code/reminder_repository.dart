/// ReminderRepository — 提醒数据仓库
///
/// 封装 reminders 表的所有 CRUD 操作，负责 Drift DataClass 与
/// domain 模型 Reminder 之间的双向转换。
library;

import 'package:drift/drift.dart';

import '../../common/code/models/reminder_model.dart';
import '../../common/code/models/enums.dart';
import 'database.dart';

/// 提醒数据仓库
class ReminderRepository {
  final AppDatabase _db;

  ReminderRepository(this._db);

  /// 插入提醒
  ///
  /// [reminder.title] 为空时抛出 [ArgumentError]。
  /// [reminder.groupId] ≤ 0 时抛出 [ArgumentError]。
  /// [reminder.scheduledAt] 早于 2000-01-01 时抛出 [ArgumentError]。
  Future<Reminder> insert(Reminder reminder) {
    _validateReminder(reminder);
    return _db.into(_db.reminders).insertReturning(
      RemindersCompanion.insert(
        groupId: reminder.groupId,
        title: reminder.title,
        content: Value(reminder.content),
        scheduledAt: reminder.scheduledAt.millisecondsSinceEpoch,
        status: Value(reminder.status.name),
        frequency: Value(reminder.frequency.name),
        createdAt: reminder.createdAt.millisecondsSinceEpoch,
        updatedAt: Value(reminder.updatedAt?.millisecondsSinceEpoch),
      ),
    ).then(_reminderDataToReminder);
  }

  /// 按 ID 获取提醒，不存在返回 null
  Future<Reminder?> getById(int id) {
    final query = _db.select(_db.reminders)
      ..where((t) => t.id.equals(id));
    return query.getSingleOrNull().then(
        (row) => row != null ? _reminderDataToReminder(row) : null);
  }

  /// 获取全部提醒
  Future<List<Reminder>> getAll() {
    final query = _db.select(_db.reminders)
      ..orderBy([(t) => OrderingTerm(expression: t.scheduledAt)]);
    return query.get().then((rows) => rows.map(_reminderDataToReminder).toList());
  }

  /// 按分组 ID 获取提醒
  Future<List<Reminder>> getByGroupId(int groupId) {
    final query = _db.select(_db.reminders)
      ..where((t) => t.groupId.equals(groupId))
      ..orderBy([(t) => OrderingTerm(expression: t.scheduledAt)]);
    return query.get().then((rows) => rows.map(_reminderDataToReminder).toList());
  }

  /// 按状态筛选提醒
  Future<List<Reminder>> getByStatus(ReminderStatus status) {
    final query = _db.select(_db.reminders)
      ..where((t) => t.status.equals(status.name))
      ..orderBy([(t) => OrderingTerm(expression: t.scheduledAt)]);
    return query.get().then((rows) => rows.map(_reminderDataToReminder).toList());
  }

  /// 按日期范围获取提醒（含边界，BETWEEN）
  Future<List<Reminder>> getByDateRange(DateTime start, DateTime end) {
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;
    final query = _db.select(_db.reminders)
      ..where((t) => t.scheduledAt.isBetweenValues(startMs, endMs))
      ..orderBy([(t) => OrderingTerm(expression: t.scheduledAt)]);
    return query.get().then((rows) => rows.map(_reminderDataToReminder).toList());
  }

  /// 获取今日提醒（当日 00:00:00 ~ 23:59:59.999）
  Future<List<Reminder>> getToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1)).subtract(
        const Duration(milliseconds: 1));
    return getByDateRange(start, end);
  }

  /// 获取过期提醒（scheduledAt < now AND status = 'pending'）
  Future<List<Reminder>> getOverdue() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final query = _db.select(_db.reminders)
      ..where((t) =>
          t.scheduledAt.isSmallerThanValue(nowMs) &
          t.status.equals(ReminderStatus.pending.name))
      ..orderBy([(t) => OrderingTerm(expression: t.scheduledAt)]);
    return query.get().then((rows) => rows.map(_reminderDataToReminder).toList());
  }

  /// 更新提醒（全字段覆盖）
  ///
  /// [reminder.id] 为 0 时抛出 [ArgumentError]。
  Future<void> update(Reminder reminder) {
    if (reminder.id == 0) {
      throw ArgumentError('Cannot update reminder with id=0 (not persisted)');
    }
    return _db.update(_db.reminders).replace(
      ReminderData(
        id: reminder.id,
        groupId: reminder.groupId,
        title: reminder.title,
        content: reminder.content,
        scheduledAt: reminder.scheduledAt.millisecondsSinceEpoch,
        status: reminder.status.name,
        frequency: reminder.frequency.name,
        createdAt: reminder.createdAt.millisecondsSinceEpoch,
        updatedAt: reminder.updatedAt?.millisecondsSinceEpoch,
      ),
    );
  }

  /// 删除提醒
  Future<void> delete(int id) {
    final query = _db.delete(_db.reminders)
      ..where((t) => t.id.equals(id));
    return query.go();
  }

  /// 批量更新提醒状态（事务内）
  Future<void> batchUpdateStatus(
      List<int> ids, ReminderStatus status) {
    return _db.transaction(() async {
      for (final id in ids) {
        final query = _db.update(_db.reminders)
          ..where((t) => t.id.equals(id));
        await query.write(RemindersCompanion(
          status: Value(status.name),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ));
      }
    });
  }

  /// 通用事务包装
  ///
  /// 在单个事务内执行 [action]。
  Future<T> transaction<T>(Future<T> Function() action) {
    return _db.transaction(action);
  }

  /// 插入前校验
  void _validateReminder(Reminder reminder) {
    if (reminder.title.isEmpty) {
      throw ArgumentError('Reminder title must not be empty');
    }
    if (reminder.groupId <= 0) {
      throw ArgumentError('Reminder groupId must be > 0');
    }
    final minValid = DateTime(2000);
    if (reminder.scheduledAt.isBefore(minValid)) {
      throw ArgumentError(
          'Reminder scheduledAt must be >= 2000-01-01, got ${reminder.scheduledAt}');
    }
  }

  /// ReminderData → Reminder 转换
  Reminder _reminderDataToReminder(ReminderData data) {
    return Reminder(
      id: data.id,
      groupId: data.groupId,
      title: data.title,
      content: data.content,
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(data.scheduledAt),
      status: ReminderStatus.fromString(data.status),
      frequency: ReminderFrequency.fromString(data.frequency),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAt),
      updatedAt: data.updatedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(data.updatedAt!)
          : null,
    );
  }
}
