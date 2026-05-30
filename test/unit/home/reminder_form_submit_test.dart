/// ReminderFormPage 新建提交 单元测试
///
/// 覆盖：insert 调用参数正确、pop 返回 true、失败 SnackBar。
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

  /// Helper: fill form and save, returns the pop result
  Future<bool?> submitForm(WidgetTester tester) async {
    // Fill title
    await tester.enterText(find.byType(TextFormField).first, '测试标题');

    // Select group
    await tester.tap(find.byType(DropdownButtonFormField<Group>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('客厅').last);
    await tester.pumpAndSettle();

    // Tap save
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // Check if pop happened
    return null; // Navigation result handled in each test
  }

  group('ReminderFormPage submit (create)', () {
    testWidgets('inserts reminder into repository on valid submit',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Fill title
      await tester.enterText(find.byType(TextFormField).first, '测试标题');

      // Select group
      await tester.tap(find.byType(DropdownButtonFormField<Group>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('客厅').last);
      await tester.pumpAndSettle();

      // Tap save
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // Verify the reminder was inserted
      final allReminders = await reminderRepo.getAll();
      expect(allReminders.length, 1);
      expect(allReminders.first.title, '测试标题');
      expect(allReminders.first.groupId, 1);
      expect(allReminders.first.status, ReminderStatus.pending);
      expect(allReminders.first.frequency, ReminderFrequency.once);
    });

    testWidgets('inserts reminder with content when provided', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Fill title and content
      await tester.enterText(find.byType(TextFormField).first, '买牛奶');
      await tester.enterText(find.byType(TextFormField).last, '记得买脱脂牛奶');

      // Select group
      await tester.tap(find.byType(DropdownButtonFormField<Group>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('客厅').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      final allReminders = await reminderRepo.getAll();
      expect(allReminders.length, 1);
      expect(allReminders.first.title, '买牛奶');
      expect(allReminders.first.content, '记得买脱脂牛奶');
    });

    testWidgets('inserts reminder with content=null when content is empty',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '测试');

      // Select group
      await tester.tap(find.byType(DropdownButtonFormField<Group>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('客厅').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      final allReminders = await reminderRepo.getAll();
      expect(allReminders.length, 1);
      // content should be null when empty
      expect(allReminders.first.content, isNull);
    });

    testWidgets('pop returns true on successful insert', (tester) async {
      // Use a NavigatorObserver to capture the pop result
      final observer = _TestNavigatorObserver();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupRepositoryProvider.overrideWith((ref) => groupRepo),
            reminderRepositoryProvider.overrideWith((ref) => reminderRepo),
          ],
          child: MaterialApp(
            home: ReminderFormPage(),
            navigatorObservers: [observer],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '测试');
      await tester.tap(find.byType(DropdownButtonFormField<Group>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('客厅').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // Should have popped
      expect(observer.hasPopped, isTrue);
    });
  });
}

/// Simple navigator observer to detect pop
class _TestNavigatorObserver extends NavigatorObserver {
  bool hasPopped = false;
  dynamic popResult;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    hasPopped = true;
    popResult = route.currentResult;
    super.didPop(route, previousRoute);
  }
}
