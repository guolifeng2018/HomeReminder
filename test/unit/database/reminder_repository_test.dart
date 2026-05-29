/// ReminderRepository 单元测试
///
/// 覆盖：insert 必填字段校验、CRUD 主路径、getByGroupId、getByStatus、
/// getByDateRange（含边界）、getToday、getOverdue、batchUpdateStatus、
/// FK 级联删除。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:home_reminder/src/core/database/code/database.dart';
import 'package:home_reminder/src/core/database/code/group_repository.dart';
import 'package:home_reminder/src/core/database/code/reminder_repository.dart';
import 'package:home_reminder/src/core/common/code/models/group_model.dart';
import 'package:home_reminder/src/core/common/code/models/reminder_model.dart';
import 'package:home_reminder/src/core/common/code/models/enums.dart';

void main() {
  late AppDatabase db;
  late GroupRepository groupRepo;
  late ReminderRepository reminderRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON');
      },
    ));
    groupRepo = GroupRepository(db);
    reminderRepo = ReminderRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<Group> _createGroup(String name) async {
    return groupRepo.insert(
      Group(name: name, sortOrder: 0, createdAt: DateTime(2026, 1, 1)),
    );
  }

  group('insert', () {
    test('empty title → throws ArgumentError', () async {
      final reminder = Reminder(
        groupId: 1,
        title: '',
        scheduledAt: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 1, 1),
      );
      expect(
        () => reminderRepo.insert(reminder),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('invalid groupId (<=0) → throws ArgumentError', () async {
      final reminder = Reminder(
        groupId: 0,
        title: 'Test',
        scheduledAt: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 1, 1),
      );
      expect(
        () => reminderRepo.insert(reminder),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('invalid scheduledAt → throws ArgumentError', () async {
      final reminder = Reminder(
        groupId: 1,
        title: 'Test',
        scheduledAt: DateTime(1999, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      );
      expect(
        () => reminderRepo.insert(reminder),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('valid reminder → getById retrieves it', () async {
      final group = await _createGroup('TestGroup');
      final reminder = Reminder(
        groupId: group.id,
        title: 'Buy milk',
        content: '2 cartons',
        scheduledAt: DateTime(2026, 6, 15, 10),
        createdAt: DateTime(2026, 1, 1),
        status: ReminderStatus.pending,
        frequency: ReminderFrequency.weekly,
      );
      final inserted = await reminderRepo.insert(reminder);

      expect(inserted.id, greaterThan(0));
      expect(inserted.title, 'Buy milk');
      expect(inserted.content, '2 cartons');
      expect(inserted.status, ReminderStatus.pending);
      expect(inserted.frequency, ReminderFrequency.weekly);

      final fetched = await reminderRepo.getById(inserted.id);
      expect(fetched, isNotNull);
      expect(fetched!.id, inserted.id);
      expect(fetched.title, 'Buy milk');
    });
  });

  group('getById', () {
    test('returns null for non-existent id', () async {
      final result = await reminderRepo.getById(999);
      expect(result, isNull);
    });
  });

  group('getAll', () {
    test('returns all reminders ordered by scheduledAt', () async {
      final group = await _createGroup('G');
      await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'Second',
        scheduledAt: DateTime(2026, 6, 16),
        createdAt: DateTime(2026, 1, 1),
      ));
      await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'First',
        scheduledAt: DateTime(2026, 6, 15),
        createdAt: DateTime(2026, 1, 1),
      ));

      final all = await reminderRepo.getAll();
      expect(all.length, greaterThanOrEqualTo(2));
      expect(all.first.title, 'First');
    });
  });

  group('getByGroupId', () {
    test('returns correct subset', () async {
      final g1 = await _createGroup('G1');
      final g2 = await _createGroup('G2');

      await reminderRepo.insert(Reminder(
        groupId: g1.id, title: 'R1',
        scheduledAt: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 1, 1),
      ));
      await reminderRepo.insert(Reminder(
        groupId: g2.id, title: 'R2',
        scheduledAt: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 1, 1),
      ));

      final g1Reminders = await reminderRepo.getByGroupId(g1.id);
      expect(g1Reminders.length, 1);
      expect(g1Reminders.first.title, 'R1');

      final g2Reminders = await reminderRepo.getByGroupId(g2.id);
      expect(g2Reminders.length, 1);
      expect(g2Reminders.first.title, 'R2');
    });
  });

  group('getByStatus', () {
    test('filters by status correctly', () async {
      final group = await _createGroup('G');
      await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'Pending',
        scheduledAt: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 1, 1),
        status: ReminderStatus.pending,
      ));
      await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'Completed',
        scheduledAt: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 1, 1),
        status: ReminderStatus.completed,
      ));

      final pending = await reminderRepo.getByStatus(ReminderStatus.pending);
      expect(pending.length, 1);
      expect(pending.first.title, 'Pending');

      final completed = await reminderRepo.getByStatus(ReminderStatus.completed);
      expect(completed.length, 1);
      expect(completed.first.title, 'Completed');
    });
  });

  group('getByDateRange', () {
    test('returns reminders within range inclusive of boundaries', () async {
      final group = await _createGroup('G');
      await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'Exact',
        scheduledAt: DateTime(2026, 6, 15),
        createdAt: DateTime(2026, 1, 1),
      ));

      // Exact boundary match
      final result = await reminderRepo.getByDateRange(
        DateTime(2026, 6, 15),
        DateTime(2026, 6, 15, 23, 59, 59),
      );
      expect(result.length, 1);
      expect(result.first.title, 'Exact');
    });

    test('excludes reminders outside range', () async {
      final group = await _createGroup('G');
      await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'Before',
        scheduledAt: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 1, 1),
      ));
      await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'After',
        scheduledAt: DateTime(2026, 6, 30),
        createdAt: DateTime(2026, 1, 1),
      ));

      final result = await reminderRepo.getByDateRange(
        DateTime(2026, 6, 10),
        DateTime(2026, 6, 20),
      );
      expect(result.length, 0);
    });
  });

  group('getToday', () {
    test('returns only today reminders', () async {
      final group = await _createGroup('G');
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'Today',
        scheduledAt: todayStart.add(const Duration(hours: 12)),
        createdAt: DateTime(2026, 1, 1),
      ));
      await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'Yesterday',
        scheduledAt: todayStart.subtract(const Duration(days: 1)),
        createdAt: DateTime(2026, 1, 1),
      ));
      await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'Tomorrow',
        scheduledAt: todayStart.add(const Duration(days: 1)),
        createdAt: DateTime(2026, 1, 1),
      ));

      final today = await reminderRepo.getToday();
      expect(today.length, 1);
      expect(today.first.title, 'Today');
    });
  });

  group('getOverdue', () {
    test('returns only overdue pending reminders', () async {
      final group = await _createGroup('G');
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final twoDaysAgo = now.subtract(const Duration(days: 2));

      // Overdue + pending → included
      await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'OverduePending',
        scheduledAt: twoDaysAgo,
        createdAt: DateTime(2026, 1, 1),
        status: ReminderStatus.pending,
      ));
      // Overdue + completed → excluded
      await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'OverdueCompleted',
        scheduledAt: yesterday,
        createdAt: DateTime(2026, 1, 1),
        status: ReminderStatus.completed,
      ));
      // Future + pending → excluded
      await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'FuturePending',
        scheduledAt: now.add(const Duration(days: 1)),
        createdAt: DateTime(2026, 1, 1),
        status: ReminderStatus.pending,
      ));

      final overdue = await reminderRepo.getOverdue();
      expect(overdue.length, 1);
      expect(overdue.first.title, 'OverduePending');
    });
  });

  group('update', () {
    test('modifies fields → getById verifies', () async {
      final group = await _createGroup('G');
      final inserted = await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'Old',
        scheduledAt: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 1, 1),
      ));

      final updated = inserted.copyWith(
        title: 'New',
        status: ReminderStatus.completed,
      );
      await reminderRepo.update(updated);

      final fetched = await reminderRepo.getById(inserted.id);
      expect(fetched!.title, 'New');
      expect(fetched.status, ReminderStatus.completed);
    });
  });

  group('delete', () {
    test('after delete → getById returns null', () async {
      final group = await _createGroup('G');
      final inserted = await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'DeleteMe',
        scheduledAt: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 1, 1),
      ));
      await reminderRepo.delete(inserted.id);

      final fetched = await reminderRepo.getById(inserted.id);
      expect(fetched, isNull);
    });
  });

  group('batchUpdateStatus', () {
    test('updates status for all given ids', () async {
      final group = await _createGroup('G');
      final r1 = await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'R1',
        scheduledAt: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 1, 1),
      ));
      final r2 = await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'R2',
        scheduledAt: DateTime(2026, 6, 2),
        createdAt: DateTime(2026, 1, 1),
      ));

      await reminderRepo.batchUpdateStatus(
        [r1.id, r2.id],
        ReminderStatus.completed,
      );

      final updated1 = await reminderRepo.getById(r1.id);
      final updated2 = await reminderRepo.getById(r2.id);
      expect(updated1!.status, ReminderStatus.completed);
      expect(updated2!.status, ReminderStatus.completed);
    });
  });

  group('FK cascade delete', () {
    test('deleting group → associated reminders disappear', () async {
      final group = await _createGroup('ToDelete');
      await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'Orphan',
        scheduledAt: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 1, 1),
      ));
      await reminderRepo.insert(Reminder(
        groupId: group.id, title: 'Orphan2',
        scheduledAt: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 1, 1),
      ));

      // Before delete: 2 reminders
      final before = await reminderRepo.getByGroupId(group.id);
      expect(before.length, 2);

      await groupRepo.delete(group.id);

      // After delete: 0 reminders
      final after = await reminderRepo.getByGroupId(group.id);
      expect(after.length, 0);
    });
  });

  group('transaction', () {
    test('generic transaction wrapper works', () async {
      final group = await _createGroup('G');
      final result = await reminderRepo.transaction(() async {
        final r = await reminderRepo.insert(Reminder(
          groupId: group.id, title: 'TxReminder',
          scheduledAt: DateTime(2026, 6, 1),
          createdAt: DateTime(2026, 1, 1),
        ));
        return r.id;
      });

      final fetched = await reminderRepo.getById(result);
      expect(fetched, isNotNull);
      expect(fetched!.title, 'TxReminder');
    });
  });
}
