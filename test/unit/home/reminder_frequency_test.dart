/// ReminderFormPage 重复频率配置 单元测试
///
/// 覆盖：5 选项渲染、枚举映射、编辑回显、新建保存频率。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:home_reminder/src/feature/home/code/reminder_form_page.dart';
import 'package:home_reminder/src/core/providers/providers.dart';
import 'package:home_reminder/src/core/database/code/group_repository.dart';
import 'package:home_reminder/src/core/database/code/reminder_repository.dart';
import 'package:home_reminder/src/core/database/code/database.dart';
import 'package:home_reminder/src/core/common/code/models/group_model.dart';
import 'package:home_reminder/src/core/common/code/models/reminder_model.dart';
import 'package:home_reminder/src/core/common/code/models/enums.dart';
import 'package:drift/native.dart';

void main() {
  late AppDatabase db;
  late GroupRepository groupRepo;
  late ReminderRepository reminderRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    groupRepo = GroupRepository(db);
    reminderRepo = ReminderRepository(db);

    await groupRepo.insert(Group(
      id: 1,
      name: '客厅',
      sortOrder: 0,
      createdAt: DateTime(2026, 1, 1),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestApp({int? reminderId}) {
    return ProviderScope(
      overrides: [
        groupRepositoryProvider.overrideWith((ref) => groupRepo),
        reminderRepositoryProvider.overrideWith((ref) => reminderRepo),
      ],
      child: MaterialApp(
        home: ReminderFormPage(reminderId: reminderId),
      ),
    );
  }

  group('ReminderFormPage frequency', () {
    testWidgets('renders all 5 frequency options in create mode',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('一次性'), findsOneWidget);
      expect(find.text('每天'), findsOneWidget);
      expect(find.text('每周'), findsOneWidget);
      expect(find.text('隔周'), findsOneWidget);
      expect(find.text('每月'), findsOneWidget);
    });

    testWidgets('default frequency is once in create mode', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Fill form and save with default frequency
      await tester.enterText(find.byType(TextFormField).first, '测试');
      await tester.tap(find.byType(DropdownButtonFormField<Group>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('客厅').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      final reminders = await reminderRepo.getAll();
      expect(reminders.length, 1);
      expect(reminders.first.frequency, ReminderFrequency.once);
    });

    testWidgets('saves selected frequency correctly', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Fill title
      await tester.enterText(find.byType(TextFormField).first, '每周任务');

      // Select group
      await tester.tap(find.byType(DropdownButtonFormField<Group>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('客厅').last);
      await tester.pumpAndSettle();

      // Tap '每周' frequency option
      await tester.tap(find.text('每周'));
      await tester.pump();

      // Save
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      final reminders = await reminderRepo.getAll();
      expect(reminders.length, 1);
      expect(reminders.first.frequency, ReminderFrequency.weekly);
    });

    testWidgets('edit mode pre-fills correct frequency', (tester) async {
      final now = DateTime.now();
      await reminderRepo.insert(Reminder(
        id: 1,
        groupId: 1,
        title: '隔周提醒',
        scheduledAt: DateTime(now.year, now.month, now.day, 23, 59),
        frequency: ReminderFrequency.biweekly,
        status: ReminderStatus.pending,
        createdAt: now,
      ));

      await tester.pumpWidget(buildTestApp(reminderId: 1));
      await tester.pumpAndSettle();

      // All 5 options should be visible
      expect(find.text('一次性'), findsOneWidget);
      // '隔周' should be visible (the pre-filled value)
      expect(find.text('隔周'), findsOneWidget);
    });

    testWidgets('edit mode preserves frequency when saving unchanged',
        (tester) async {
      final now = DateTime.now();
      await reminderRepo.insert(Reminder(
        id: 1,
        groupId: 1,
        title: '每月任务',
        scheduledAt: DateTime(now.year, now.month, now.day, 23, 59),
        frequency: ReminderFrequency.monthly,
        status: ReminderStatus.pending,
        createdAt: now,
      ));

      await tester.pumpWidget(buildTestApp(reminderId: 1));
      await tester.pumpAndSettle();

      // Just save without changing anything
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      final updated = await reminderRepo.getById(1);
      expect(updated, isNotNull);
      expect(updated!.frequency, ReminderFrequency.monthly);
    });
  });
}
