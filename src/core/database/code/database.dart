/// Drift 数据库表定义
///
/// 定义 groups 和 reminders 两个核心表的列、索引、外键约束，
/// 以及 AppDatabase 数据库实例类。
library;

import 'package:drift/drift.dart';

part 'database.g.dart';

/// groups 表 — 分组实体
@TableIndex(name: 'idx_groups_sort_order', columns: {#sortOrder})
@DataClassName('GroupData')
class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1)();
  TextColumn get icon => text().nullable()();
  BoolColumn get isPreset => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

}

/// reminders 表 — 提醒实体
@TableIndex(name: 'idx_reminders_scheduled_at', columns: {#scheduledAt})
@TableIndex(name: 'idx_reminders_group_id', columns: {#groupId})
@TableIndex(name: 'idx_reminders_status', columns: {#status})
@DataClassName('ReminderData')
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId =>
      integer().references(Groups, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1)();
  TextColumn get content => text().nullable()();
  IntColumn get scheduledAt => integer()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get frequency => text().withDefault(const Constant('once'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer().nullable()();
}

/// AppDatabase — Drift 数据库实例
///
/// 构造时接受 [QueryExecutor]，实例管理由上层（F-03）负责。
@DriftDatabase(tables: [Groups, Reminders])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
