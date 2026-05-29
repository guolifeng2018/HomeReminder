/// GroupRepository — 分组数据仓库
///
/// 封装 groups 表的所有 CRUD 操作，负责 Drift DataClass 与
/// domain 模型 Group 之间的双向转换。
library;

import 'package:drift/drift.dart';

import '../../common/code/models/group_model.dart';
import '../../common/code/constants/app_constants.dart';
import 'database.dart';

/// 分组数据仓库
class GroupRepository {
  final AppDatabase _db;

  GroupRepository(this._db);

  /// 插入分组
  ///
  /// [group.name] 为空时抛出 [ArgumentError]。
  Future<Group> insert(Group group) {
    if (group.name.isEmpty) {
      throw ArgumentError('Group name must not be empty');
    }
    return _db.into(_db.groups).insertReturning(
      GroupsCompanion.insert(
        name: group.name,
        icon: Value(group.icon),
        isPreset: Value(group.isPreset),
        sortOrder: Value(group.sortOrder),
        createdAt: group.createdAt.millisecondsSinceEpoch,
      ),
    ).then(_groupDataToGroup);
  }

  /// 获取全部分组，按 sort_order 升序排列
  Future<List<Group>> getAll() {
    final query = _db.select(_db.groups)
      ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    return query.get().then((rows) => rows.map(_groupDataToGroup).toList());
  }

  /// 按 ID 获取分组，不存在返回 null
  Future<Group?> getById(int id) {
    final query = _db.select(_db.groups)
      ..where((t) => t.id.equals(id));
    return query.getSingleOrNull().then((row) => row != null ? _groupDataToGroup(row) : null);
  }

  /// 更新分组（全字段覆盖）
  ///
  /// [group.id] 为 0 时抛出 [ArgumentError]。
  Future<void> update(Group group) {
    if (group.id == 0) {
      throw ArgumentError('Cannot update group with id=0 (not persisted)');
    }
    return _db.update(_db.groups).replace(
      GroupData(
        id: group.id,
        name: group.name,
        icon: group.icon,
        isPreset: group.isPreset,
        sortOrder: group.sortOrder,
        createdAt: group.createdAt.millisecondsSinceEpoch,
      ),
    );
  }

  /// 删除分组（级联删除关联 reminders）
  Future<void> delete(int id) {
    final query = _db.delete(_db.groups)
      ..where((t) => t.id.equals(id));
    return query.go();
  }

  /// 初始化预设分组
  ///
  /// 在事务内先查询已有预设数量，仅当不存在预设分组时才批量插入。
  /// 保证幂等性：多次调用仅首次写入 6 条记录。
  Future<void> initPresetGroups() {
    return _db.transaction(() async {
      final existingCount = await (_db.select(_db.groups)
            ..where((t) => t.isPreset.equals(true)))
          .get()
          .then((rows) => rows.length);

      if (existingCount > 0) return;

      for (final preset in defaultGroups) {
        final name = preset['name'] as String;
        final icon = preset['icon'] as String?;
        final sortOrder = preset['sort_order'] as int;

        await _db.into(_db.groups).insert(
          GroupsCompanion.insert(
            name: name,
            icon: Value(icon),
            isPreset: const Value(true),
            sortOrder: Value(sortOrder),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  /// GroupData → Group 转换
  Group _groupDataToGroup(GroupData data) {
    return Group(
      id: data.id,
      name: data.name,
      icon: data.icon,
      isPreset: data.isPreset,
      sortOrder: data.sortOrder,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAt),
    );
  }
}
