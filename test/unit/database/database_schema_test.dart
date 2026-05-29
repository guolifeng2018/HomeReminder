/// 数据库 schema 验证测试
///
/// 覆盖：索引存在性验证（PRAGMA index_list）、EXPLAIN QUERY PLAN 索引命中、
/// 事务回滚边界测试。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';

import 'package:home_reminder/src/core/database/code/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory(
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON');
      },
    ));
  });

  tearDown(() async {
    await db.close();
  });

  group('index existence (PRAGMA index_list)', () {
    test('reminders table has all three expected indices', () async {
      final result = await db.customSelect(
        'PRAGMA index_list(reminders)',
      ).get();

      final indexNames = _extractColumn(result, 1);
      expect(
        indexNames.any((name) => name == 'idx_reminders_scheduled_at'),
        isTrue,
        reason: 'idx_reminders_scheduled_at index missing',
      );
      expect(
        indexNames.any((name) => name == 'idx_reminders_group_id'),
        isTrue,
        reason: 'idx_reminders_group_id index missing',
      );
      expect(
        indexNames.any((name) => name == 'idx_reminders_status'),
        isTrue,
        reason: 'idx_reminders_status index missing',
      );
    });

    test('groups table has sort_order index', () async {
      final result = await db.customSelect(
        'PRAGMA index_list(groups)',
      ).get();

      final indexNames = _extractColumn(result, 1);
      expect(
        indexNames.any((name) => name == 'idx_groups_sort_order'),
        isTrue,
        reason: 'idx_groups_sort_order index missing',
      );
    });
  });

  group('EXPLAIN QUERY PLAN with data', () {
    setUp(() async {
      // Insert a group to satisfy FK constraint
      await db.into(db.groups).insert(
        GroupsCompanion.insert(
          name: 'TestGroup',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      // Insert a few reminders so SQLite considers using indexes
      for (var i = 0; i < 10; i++) {
        await db.into(db.reminders).insert(
          RemindersCompanion.insert(
            groupId: 1,
            title: 'Reminder $i',
            scheduledAt: 1000000 + i * 86400000,
            status: Value(i.isEven ? 'pending' : 'completed'),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }
    });

    test('idx_reminders_scheduled_at used for scheduled_at > filter', () async {
      final result = await db.customSelect(
        'EXPLAIN QUERY PLAN SELECT * FROM reminders WHERE scheduled_at > ?',
        variables: [Variable.withInt(1000000)],
      ).get();

      final plan = _extractPlanText(result);
      expect(
        plan.any((row) => row.contains('idx_reminders_scheduled_at')),
        isTrue,
        reason: 'Expected idx_reminders_scheduled_at in plan:\n${plan.join('\n')}',
      );
    });

    test('idx_reminders_group_id used for group_id = filter', () async {
      final result = await db.customSelect(
        'EXPLAIN QUERY PLAN SELECT * FROM reminders WHERE group_id = ?',
        variables: [Variable.withInt(1)],
      ).get();

      final plan = _extractPlanText(result);
      expect(
        plan.any((row) => row.contains('idx_reminders_group_id')),
        isTrue,
        reason: 'Expected idx_reminders_group_id in plan:\n${plan.join('\n')}',
      );
    });

    test('idx_reminders_status used for status = filter', () async {
      final result = await db.customSelect(
        'EXPLAIN QUERY PLAN SELECT * FROM reminders WHERE status = ?',
        variables: [Variable.withString('pending')],
      ).get();

      final plan = _extractPlanText(result);
      expect(
        plan.any((row) => row.contains('idx_reminders_status')),
        isTrue,
        reason: 'Expected idx_reminders_status in plan:\n${plan.join('\n')}',
      );
    });
  });

  group('transaction rollback', () {
    test('batch insert with deliberate failure rolls back all changes', () async {
      bool threw = false;
      try {
        await db.transaction(() async {
          await db.into(db.groups).insert(
            GroupsCompanion.insert(
              name: 'ValidGroup',
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );

          // Deliberately violate CHECK(length(name) >= 1)
          await db.into(db.groups).insert(
            GroupsCompanion.insert(
              name: '',
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        });
      } catch (_) {
        threw = true;
      }

      expect(threw, isTrue);

      final groups = await db.select(db.groups).get();
      expect(groups.length, 0,
          reason: 'Transaction should have rolled back, but ${groups.length} groups found');
    });
  });
}

/// Extract values from a specific column index in QueryRow results.
List<String> _extractColumn(List<QueryRow> rows, int columnIndex) {
  return rows.map((row) {
    final values = row.data.values.toList();
    return columnIndex < values.length ? values[columnIndex].toString() : '';
  }).toList();
}

/// Extract full explain plan text from QueryRow results.
List<String> _extractPlanText(List<QueryRow> rows) {
  return rows.map((row) {
    return row.data.values.map((v) => v.toString()).join('|');
  }).toList();
}
