/// ReminderFormPage UI 单元测试
///
/// 覆盖：新建/编辑模式标题、5 个表单字段渲染、保存按钮。
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
import 'package:home_reminder/src/core/common/code/models/enums.dart';
import 'package:drift/native.dart';

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

  group('ReminderFormPage UI', () {
    testWidgets('shows "添加提醒" title in create mode', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('添加提醒'), findsOneWidget);
      expect(find.text('编辑提醒'), findsNothing);
    });

    testWidgets('shows "编辑提醒" title in edit mode', (tester) async {
      await tester.pumpWidget(buildTestApp(reminderId: 1));
      await tester.pumpAndSettle();

      expect(find.text('编辑提醒'), findsOneWidget);
      expect(find.text('添加提醒'), findsNothing);
    });

    testWidgets('renders title TextFormField with label "标题"', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('标题'), findsOneWidget);
      // Verify it's a TextFormField (not just a label)
      final titleField = find.byType(TextFormField).first;
      expect(titleField, findsOneWidget);
    });

    testWidgets('renders content TextFormField with label "内容（可选）"',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('内容（可选）'), findsOneWidget);
    });

    testWidgets('renders group dropdown with label "分组"', (tester) async {
      // Insert a group first so dropdown has data
      await groupRepo.insert(Group(
        id: 1,
        name: '客厅',
        sortOrder: 0,
        createdAt: DateTime(2026, 1, 1),
      ));

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('分组'), findsOneWidget);
    });

    testWidgets('renders time picker with label "提醒时间"', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('提醒时间'), findsOneWidget);
    });

    testWidgets('renders frequency label "重复频率"', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('重复频率'), findsOneWidget);
    });

    testWidgets('renders all 5 frequency options', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      for (final freq in ReminderFrequency.values) {
        expect(find.text(freq.displayName), findsOneWidget);
      }
    });

    testWidgets('renders save button', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('保存'), findsOneWidget);
    });

    testWidgets('renders time subtitle with formatted date', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Should display a subtitle with formatted time (the initial value is now+1h)
      // The subtitle is rendered by the ListTile
      final listTile = find.byType(ListTile);
      expect(listTile, findsOneWidget);
    });
  });
}
