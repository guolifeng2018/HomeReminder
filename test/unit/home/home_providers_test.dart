/// 首页 Provider 单元测试
///
/// 覆盖：groupsProvider、todayRemindersProvider、filterProvider、
/// filteredRemindersProvider 的基本行为。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:home_reminder/src/feature/home/code/home_providers.dart';
import 'package:home_reminder/src/core/providers/providers.dart';
import 'package:home_reminder/src/core/common/code/models/group_model.dart';
import 'package:home_reminder/src/core/common/code/models/reminder_model.dart';
import 'package:home_reminder/src/core/common/code/models/enums.dart';
import 'package:home_reminder/src/core/database/code/group_repository.dart';
import 'package:home_reminder/src/core/database/code/reminder_repository.dart';
import 'package:home_reminder/src/core/database/code/database.dart';
import 'package:drift/native.dart';

/// 辅助函数：创建内存数据库 + Repository
void main() {
  late AppDatabase db;
  late GroupRepository groupRepo;
  late ReminderRepository reminderRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    groupRepo = GroupRepository(db);
    reminderRepo = ReminderRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(overrides: [
      groupRepositoryProvider.overrideWith((ref) => groupRepo),
      reminderRepositoryProvider.overrideWith((ref) => reminderRepo),
    ]);
  }

  group('groupsProvider', () {
    test('returns empty list when no groups', () async {
      final container = createContainer();
      final result = await container.read(groupsProvider.future);
      expect(result, isEmpty);
    });

    test('returns groups sorted by sortOrder ASC', () async {
      await groupRepo.insert(Group(
        id: 1,
        name: 'C',
        icon: null,
        isPreset: false,
        sortOrder: 30,
        createdAt: DateTime(2026, 5, 1),
      ));
      await groupRepo.insert(Group(
        id: 2,
        name: 'A',
        icon: null,
        isPreset: false,
        sortOrder: 10,
        createdAt: DateTime(2026, 5, 1),
      ));
      await groupRepo.insert(Group(
        id: 3,
        name: 'B',
        icon: null,
        isPreset: false,
        sortOrder: 20,
        createdAt: DateTime(2026, 5, 1),
      ));

      final container = createContainer();
      final result = await container.read(groupsProvider.future);

      expect(result.length, 3);
      expect(result[0].name, 'A');
      expect(result[1].name, 'B');
      expect(result[2].name, 'C');
    });
  });

  group('todayRemindersProvider', () {
    test('returns empty list when no reminders', () async {
      final container = createContainer();
      final result = await container.read(todayRemindersProvider.future);
      expect(result, isEmpty);
    });

    test('returns today reminders sorted by scheduledAt ASC', () async {
      final now = DateTime.now();
      final today8am = DateTime(now.year, now.month, now.day, 8, 0);
      final today10am = DateTime(now.year, now.month, now.day, 10, 0);
      final today6am = DateTime(now.year, now.month, now.day, 6, 0);

      await reminderRepo.insert(Reminder(
        groupId: 1,
        title: 'Late',
        scheduledAt: today10am,
        createdAt: DateTime(2026, 5, 1),
      ));
      await reminderRepo.insert(Reminder(
        groupId: 1,
        title: 'Early',
        scheduledAt: today6am,
        createdAt: DateTime(2026, 5, 1),
      ));
      await reminderRepo.insert(Reminder(
        groupId: 1,
        title: 'Mid',
        scheduledAt: today8am,
        createdAt: DateTime(2026, 5, 1),
      ));

      final container = createContainer();
      final result = await container.read(todayRemindersProvider.future);

      expect(result.length, 3);
      // Should be sorted ASC
      expect(result[0].title, 'Early');
      expect(result[1].title, 'Mid');
      expect(result[2].title, 'Late');
    });
  });

  group('filterProvider', () {
    test('initial value is null (show all)', () {
      final container = createContainer();
      expect(container.read(filterProvider), isNull);
    });

    test('can set filter to a specific status', () {
      final container = createContainer();
      container.read(filterProvider.notifier).state =
          ReminderStatus.pending;
      expect(container.read(filterProvider), ReminderStatus.pending);
    });

    test('can reset filter back to null', () {
      final container = createContainer();
      container.read(filterProvider.notifier).state =
          ReminderStatus.completed;
      container.read(filterProvider.notifier).state = null;
      expect(container.read(filterProvider), isNull);
    });
  });

  group('filteredRemindersProvider', () {
    test('returns all reminders when filter is null', () async {
      final now = DateTime.now();
      await reminderRepo.insert(Reminder(
        groupId: 1,
        title: 'Pending',
        scheduledAt: DateTime(now.year, now.month, now.day, 8),
        status: ReminderStatus.pending,
        createdAt: DateTime(2026, 5, 1),
      ));
      await reminderRepo.insert(Reminder(
        groupId: 1,
        title: 'Completed',
        scheduledAt: DateTime(now.year, now.month, now.day, 9),
        status: ReminderStatus.completed,
        createdAt: DateTime(2026, 5, 1),
      ));

      final container = createContainer();
      // Load todayRemindersProvider first
      await container.read(todayRemindersProvider.future);

      final result = container.read(filteredRemindersProvider);
      expect(result.value, isNotNull);
      expect(result.value!.length, 2);
    });

    test('filters to only pending reminders when filter is pending',
        () async {
      final now = DateTime.now();
      await reminderRepo.insert(Reminder(
        groupId: 1,
        title: 'Pending',
        scheduledAt: DateTime(now.year, now.month, now.day, 8),
        status: ReminderStatus.pending,
        createdAt: DateTime(2026, 5, 1),
      ));
      await reminderRepo.insert(Reminder(
        groupId: 1,
        title: 'Completed',
        scheduledAt: DateTime(now.year, now.month, now.day, 9),
        status: ReminderStatus.completed,
        createdAt: DateTime(2026, 5, 1),
      ));

      final container = createContainer();
      // Set filter to pending
      container.read(filterProvider.notifier).state =
          ReminderStatus.pending;
      // Load todayRemindersProvider
      await container.read(todayRemindersProvider.future);

      final result = container.read(filteredRemindersProvider);
      expect(result.value, isNotNull);
      expect(result.value!.length, 1);
      expect(result.value![0].title, 'Pending');
      expect(result.value![0].status, ReminderStatus.pending);
    });

    test('returns empty list when no reminders match filter', () async {
      final now = DateTime.now();
      await reminderRepo.insert(Reminder(
        groupId: 1,
        title: 'Pending',
        scheduledAt: DateTime(now.year, now.month, now.day, 8),
        status: ReminderStatus.pending,
        createdAt: DateTime(2026, 5, 1),
      ));

      final container = createContainer();
      container.read(filterProvider.notifier).state =
          ReminderStatus.completed;
      await container.read(todayRemindersProvider.future);

      final result = container.read(filteredRemindersProvider);
      expect(result.value, isNotNull);
      expect(result.value!.length, 0);
    });
  });
}
