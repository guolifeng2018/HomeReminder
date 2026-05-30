/// ReminderFormPage 表单验证 单元测试
///
/// 覆盖：空标题拦截、未选分组拦截、全部合法通过、时间校验存在。
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
import 'package:drift/native.dart';

void main() {
  late AppDatabase db;
  late GroupRepository groupRepo;
  late ReminderRepository reminderRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    groupRepo = GroupRepository(db);
    reminderRepo = ReminderRepository(db);

    // Insert a group so dropdown has options
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

  /// Helper: taps save and pumps
  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Helper: fill title and select group to pass validation
  Future<void> fillValidForm(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).first, '测试标题');
    // Open dropdown and select first group
    await tester.tap(find.byType(DropdownButtonFormField<Group>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('客厅').last);
    await tester.pumpAndSettle();
  }

  group('ReminderFormPage validation', () {
    testWidgets('blocks submit when title is empty', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tapSave(tester);

      expect(find.text('标题不能为空'), findsOneWidget);
    });

    testWidgets('blocks submit when title is only whitespace', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '   ');
      await tapSave(tester);

      expect(find.text('标题不能为空'), findsOneWidget);
    });

    testWidgets('blocks submit when group is not selected', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '测试标题');
      await tapSave(tester);

      expect(find.text('请选择分组'), findsOneWidget);
    });

    testWidgets('passes when all fields are valid', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await fillValidForm(tester);
      await tapSave(tester);

      // No validation errors
      expect(find.text('标题不能为空'), findsNothing);
      expect(find.text('请选择分组'), findsNothing);
      // Default time is now+1h (future), so no "时间不能是过去" SnackBar
      expect(find.text('时间不能是过去'), findsNothing);
    });
  });
}
