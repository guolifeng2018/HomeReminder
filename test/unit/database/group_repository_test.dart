/// GroupRepository 单元测试
///
/// 覆盖：insert 正常/getById 可取出、insert 空 name 抛异常、
/// getAll 按 sort_order 排序、update 验证、delete 后 getById 返回 null、
/// initPresetGroups 幂等调用。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:home_reminder/src/core/database/code/database.dart';
import 'package:home_reminder/src/core/database/code/group_repository.dart';
import 'package:home_reminder/src/core/common/code/models/group_model.dart';

void main() {
  late AppDatabase db;
  late GroupRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = GroupRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('insert', () {
    test('valid group → getById retrieves it', () async {
      final group = Group(
        name: 'Kitchen',
        icon: 'kitchen',
        sortOrder: 1,
        createdAt: DateTime(2026, 1, 1),
      );
      final inserted = await repo.insert(group);

      expect(inserted.id, greaterThan(0));
      expect(inserted.name, 'Kitchen');
      expect(inserted.icon, 'kitchen');
      expect(inserted.sortOrder, 1);
      expect(inserted.isPreset, false);

      final fetched = await repo.getById(inserted.id);
      expect(fetched, isNotNull);
      expect(fetched!.id, inserted.id);
      expect(fetched.name, 'Kitchen');
    });

    test('empty name → throws ArgumentError', () async {
      final group = Group(
        name: '',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(
        () => repo.insert(group),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('getAll', () {
    test('returns groups ordered by sort_order ASC', () async {
      await repo.insert(Group(name: 'C', sortOrder: 3, createdAt: DateTime(2026, 1, 1)));
      await repo.insert(Group(name: 'A', sortOrder: 1, createdAt: DateTime(2026, 1, 1)));
      await repo.insert(Group(name: 'B', sortOrder: 2, createdAt: DateTime(2026, 1, 1)));

      final groups = await repo.getAll();

      expect(groups.length, 3);
      expect(groups[0].sortOrder, 1);
      expect(groups[1].sortOrder, 2);
      expect(groups[2].sortOrder, 3);
      expect(groups[0].name, 'A');
      expect(groups[2].name, 'C');
    });
  });

  group('getById', () {
    test('returns null for non-existent id', () async {
      final result = await repo.getById(999);
      expect(result, isNull);
    });
  });

  group('update', () {
    test('modifies fields → getById verifies', () async {
      final inserted = await repo.insert(
        Group(name: 'Old', sortOrder: 1, createdAt: DateTime(2026, 1, 1)),
      );

      final updated = inserted.copyWith(name: 'New', sortOrder: 99, icon: 'updated');
      await repo.update(updated);

      final fetched = await repo.getById(inserted.id);
      expect(fetched!.name, 'New');
      expect(fetched.sortOrder, 99);
      expect(fetched.icon, 'updated');
    });

    test('with id=0 throws ArgumentError', () async {
      final group = Group(
        id: 0,
        name: 'NoId',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(
        () => repo.update(group),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('delete', () {
    test('after delete → getById returns null', () async {
      final inserted = await repo.insert(
        Group(name: 'DeleteMe', createdAt: DateTime(2026, 1, 1)),
      );
      await repo.delete(inserted.id);

      final fetched = await repo.getById(inserted.id);
      expect(fetched, isNull);
    });
  });

  group('initPresetGroups', () {
    test('two calls → exactly 6 records (idempotent)', () async {
      await repo.initPresetGroups();
      var groups = await repo.getAll();
      expect(groups.length, 6);

      // Second call should not insert duplicates
      await repo.initPresetGroups();
      groups = await repo.getAll();
      expect(groups.length, 6);

      // Verify all groups are preset
      for (final g in groups) {
        expect(g.isPreset, true);
      }
    });
  });
}
