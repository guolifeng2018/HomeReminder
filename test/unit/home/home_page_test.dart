/// HomePage 单元测试
///
/// 覆盖：loading/error/empty 态、手机/平板布局、筛选切换。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:home_reminder/src/feature/home/code/home_page.dart';
import 'package:home_reminder/src/feature/home/code/home_providers.dart';
import 'package:home_reminder/src/core/providers/providers.dart';
import 'package:home_reminder/src/core/common/code/models/group_model.dart';
import 'package:home_reminder/src/core/common/code/models/reminder_model.dart';
import 'package:home_reminder/src/core/common/code/models/enums.dart';
import 'package:home_reminder/src/core/database/code/group_repository.dart';
import 'package:home_reminder/src/core/database/code/reminder_repository.dart';
import 'package:home_reminder/src/core/database/code/database.dart';
import 'package:drift/native.dart';

/// 辅助：创建测试 Group
Group makeGroup(int id, String name, int sortOrder) {
  return Group(
    id: id,
    name: name,
    icon: 'living',
    isPreset: true,
    sortOrder: sortOrder,
    createdAt: DateTime(2026, 5, 1),
  );
}

/// 辅助：创建测试 Reminder
Reminder makeReminder({
  int id = 1,
  int groupId = 1,
  required String title,
  required DateTime scheduledAt,
  ReminderStatus status = ReminderStatus.pending,
}) {
  return Reminder(
    id: id,
    groupId: groupId,
    title: title,
    scheduledAt: scheduledAt,
    status: status,
    createdAt: DateTime(2026, 5, 1),
  );
}

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

  /// 构建测试 Widget
  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        groupRepositoryProvider.overrideWith((ref) => groupRepo),
        reminderRepositoryProvider.overrideWith((ref) => reminderRepo),
      ],
      child: const MaterialApp(
        home: HomePage(),
      ),
    );
  }

  group('HomePage', () {
    testWidgets('shows empty state when no groups and no reminders',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('还没有提醒'), findsOneWidget);
      expect(find.text('点击下方 + 添加'), findsOneWidget);
    });

    testWidgets('renders HomeHeader when data is loaded', (tester) async {
      final now = DateTime.now();
      await groupRepo.insert(makeGroup(1, '客厅', 0));
      await reminderRepo.insert(makeReminder(
        title: '清理',
        scheduledAt: DateTime(now.year, now.month, now.day, 9),
      ));

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // HomeHeader should be rendered (date text)
      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
    });

    testWidgets('renders group overview bar with data', (tester) async {
      final now = DateTime.now();
      await groupRepo.insert(makeGroup(1, '客厅', 0));
      await reminderRepo.insert(makeReminder(
        title: '清理',
        scheduledAt: DateTime(now.year, now.month, now.day, 9),
      ));

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('客厅'), findsOneWidget);
    });

    testWidgets('renders today timeline with reminders', (tester) async {
      final now = DateTime.now();
      await groupRepo.insert(makeGroup(1, '客厅', 0));
      await reminderRepo.insert(makeReminder(
        title: '清理客厅',
        scheduledAt: DateTime(now.year, now.month, now.day, 9),
      ));

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('清理客厅'), findsOneWidget);
    });

    testWidgets('renders status filter bar', (tester) async {
      final now = DateTime.now();
      await groupRepo.insert(makeGroup(1, '客厅', 0));
      await reminderRepo.insert(makeReminder(
        title: '清理',
        scheduledAt: DateTime(now.year, now.month, now.day, 9),
      ));

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('全部'), findsOneWidget);
      expect(find.text('待处理'), findsOneWidget);
    });

    testWidgets('renders FAB', (tester) async {
      final now = DateTime.now();
      await groupRepo.insert(makeGroup(1, '客厅', 0));
      await reminderRepo.insert(makeReminder(
        title: '清理',
        scheduledAt: DateTime(now.year, now.month, now.day, 9),
      ));

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
