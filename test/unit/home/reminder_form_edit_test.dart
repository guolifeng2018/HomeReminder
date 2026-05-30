/// ReminderFormPage 编辑流程 单元测试
///
/// 覆盖：预填充 5 字段、update 调用、字段一致性。
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
    await groupRepo.insert(Group(
      id: 2,
      name: '厨房',
      sortOrder: 1,
      createdAt: DateTime(2026, 1, 1),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildEditApp(int reminderId) {
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

  group('ReminderFormPage edit', () {
    testWidgets('pre-fills title field from existing reminder', (tester) async {
      final now = DateTime.now();
      await reminderRepo.insert(Reminder(
        id: 1,
        groupId: 1,
        title: '买牛奶',
        content: '脱脂牛奶',
        scheduledAt: DateTime(now.year, now.month, now.day, 9),
        frequency: ReminderFrequency.daily,
        status: ReminderStatus.pending,
        createdAt: now,
      ));

      await tester.pumpWidget(buildEditApp(1));
      await tester.pumpAndSettle();

      // Title should be pre-filled
      expect(find.text('买牛奶'), findsOneWidget);
      // The title TextFormField should contain the text
      final titleField = tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(titleField.controller!.text, '买牛奶');
    });

    testWidgets('pre-fills content field from existing reminder', (tester) async {
      final now = DateTime.now();
      await reminderRepo.insert(Reminder(
        id: 1,
        groupId: 1,
        title: '测试',
        content: '详细内容',
        scheduledAt: DateTime(now.year, now.month, now.day, 9),
        frequency: ReminderFrequency.once,
        status: ReminderStatus.pending,
        createdAt: now,
      ));

      await tester.pumpWidget(buildEditApp(1));
      await tester.pumpAndSettle();

      // Content should be pre-filled (second TextFormField)
      final fields = find.byType(TextFormField);
      final contentField = tester.widget<TextFormField>(fields.last);
      expect(contentField.controller!.text, '详细内容');
    });

    testWidgets('pre-fills group selection from existing reminder',
        (tester) async {
      final now = DateTime.now();
      await reminderRepo.insert(Reminder(
        id: 1,
        groupId: 2, // 厨房
        title: '洗碗',
        scheduledAt: DateTime(now.year, now.month, now.day, 14),
        frequency: ReminderFrequency.weekly,
        status: ReminderStatus.pending,
        createdAt: now,
      ));

      await tester.pumpWidget(buildEditApp(1));
      await tester.pumpAndSettle();

      // The dropdown should show '厨房' as selected
      expect(find.text('厨房'), findsWidgets);
    });

    testWidgets('pre-fills frequency from existing reminder', (tester) async {
      final now = DateTime.now();
      await reminderRepo.insert(Reminder(
        id: 1,
        groupId: 1,
        title: '每周任务',
        scheduledAt: DateTime(now.year, now.month, now.day, 9),
        frequency: ReminderFrequency.weekly,
        status: ReminderStatus.pending,
        createdAt: now,
      ));

      await tester.pumpWidget(buildEditApp(1));
      await tester.pumpAndSettle();

      // All 5 frequency options should be rendered, and '每周' should be visible
      expect(find.text('每周'), findsOneWidget);
    });

    testWidgets('edit submit updates reminder correctly', (tester) async {
      final now = DateTime.now();
      // Use a future time to pass time validation
      final scheduled = DateTime(now.year, now.month, now.day, 23, 59);
      await reminderRepo.insert(Reminder(
        id: 1,
        groupId: 1,
        title: '旧标题',
        content: '旧内容',
        scheduledAt: scheduled,
        frequency: ReminderFrequency.weekly,
        status: ReminderStatus.pending,
        createdAt: now,
      ));

      await tester.pumpWidget(buildEditApp(1));
      await tester.pumpAndSettle();

      // Verify pre-fill: title controller has correct text
      final titleFinder = find.byType(TextFormField).first;
      final controller = tester.widget<TextFormField>(titleFinder).controller!;
      expect(controller.text, '旧标题');

      // Directly modify controller text
      controller.text = '新标题';
      await tester.pump();
      expect(controller.text, '新标题');

      // Save using runAsync to allow real async DB operations
      await tester.runAsync(() async {
        await tester.tap(find.text('保存'));
        // Wait for async DB write to complete
        await Future.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();

      // Verify the reminder was updated
      final updated = await reminderRepo.getById(1);
      expect(updated, isNotNull);
      expect(updated!.title, '新标题');
      expect(updated.frequency, ReminderFrequency.weekly);
    });

    testWidgets('non-existent reminder in edit mode shows nothing special',
        (tester) async {
      // Edit with non-existent reminderId
      await tester.pumpWidget(buildEditApp(999));
      await tester.pumpAndSettle();

      // Should not crash — just shows the form in edit mode but empty
      expect(find.text('编辑提醒'), findsOneWidget);
    });
  });
}
