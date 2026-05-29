/// 数据库层 Provider
///
/// 提供 Drift AppDatabase 实例及 Repository 的依赖注入。
/// F-03 阶段使用 NativeDatabase.memory()，后续模块可 override。
library;

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/code/database.dart';
import '../../database/code/group_repository.dart';
import '../../database/code/reminder_repository.dart';

/// 数据库实例 Provider（单例，dispose 时 close）
///
/// 使用内存数据库用于开发和测试阶段。
/// 后续模块通过 ProviderScope.overrides 替换为文件持久化数据库。
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(NativeDatabase.memory());
  ref.onDispose(() => db.close());
  return db;
});

/// 分组仓库 Provider
///
/// 依赖 [databaseProvider] 获取数据库实例。
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return GroupRepository(db);
});

/// 提醒仓库 Provider
///
/// 依赖 [databaseProvider] 获取数据库实例。
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ReminderRepository(db);
});
