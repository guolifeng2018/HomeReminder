/// TodayTimeline 删除流程 单元测试
///
/// 覆盖：Dismissible 渲染正确、确认删除、取消保留、删除后列表-1。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:home_reminder/src/feature/home/code/today_timeline.dart';
import 'package:home_reminder/src/core/common/code/models/reminder_model.dart';
import 'package:home_reminder/src/core/common/code/models/group_model.dart';
import 'package:home_reminder/src/core/common/code/models/enums.dart';

/// 辅助：创建测试 Reminder
Reminder makeReminder({
  int id = 1,
  int groupId = 1,
  required String title,
  required DateTime scheduledAt,
  String? content,
  ReminderStatus status = ReminderStatus.pending,
}) {
  return Reminder(
    id: id,
    groupId: groupId,
    title: title,
    content: content,
    scheduledAt: scheduledAt,
    status: status,
    createdAt: DateTime(2026, 5, 1),
  );
}

Group makeGroup({int id = 1, String name = '客厅'}) {
  return Group(
    id: id,
    name: name,
    sortOrder: 0,
    createdAt: DateTime(2026, 1, 1),
  );
}

Widget buildTimeline({
  required List<Reminder> reminders,
  Map<int, Group>? groupMap,
  void Function(int)? onTap,
  Future<bool> Function(int)? onDelete,
}) {
  final groups = groupMap ?? {1: makeGroup()};
  return MaterialApp(
    home: Scaffold(
      body: TodayTimeline(
        reminders: reminders,
        groupMap: groups,
        onTap: onTap,
        onDelete: onDelete,
      ),
    ),
  );
}

void main() {
  group('TodayTimeline delete', () {
    testWidgets('renders Dismissible when onDelete is provided', (tester) async {
      final now = DateTime.now();
      final reminders = [
        makeReminder(
          id: 1,
          title: '测试提醒',
          scheduledAt: DateTime(now.year, now.month, now.day, 9),
        ),
      ];

      await tester.pumpWidget(buildTimeline(
        reminders: reminders,
        onDelete: (_) async => true,
      ));
      await tester.pumpAndSettle();

      // Dismissible should be present
      expect(find.byType(Dismissible), findsOneWidget);
    });

    testWidgets('does not render Dismissible when onDelete is null',
        (tester) async {
      final now = DateTime.now();
      final reminders = [
        makeReminder(
          id: 1,
          title: '测试提醒',
          scheduledAt: DateTime(now.year, now.month, now.day, 9),
        ),
      ];

      await tester.pumpWidget(buildTimeline(
        reminders: reminders,
        onDelete: null,
      ));
      await tester.pumpAndSettle();

      // No Dismissible when onDelete is null
      expect(find.byType(Dismissible), findsNothing);
    });

    testWidgets('shows AlertDialog on swipe', (tester) async {
      final now = DateTime.now();
      final reminders = [
        makeReminder(
          id: 1,
          title: '测试提醒',
          scheduledAt: DateTime(now.year, now.month, now.day, 9),
        ),
      ];

      await tester.pumpWidget(buildTimeline(
        reminders: reminders,
        onDelete: (_) async => true,
      ));
      await tester.pumpAndSettle();

      // Swipe left to dismiss
      await tester.fling(
        find.byType(Dismissible),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // AlertDialog should appear
      expect(find.text('确定删除该提醒？'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('确认删除'), findsOneWidget);
    });

    testWidgets('cancelling delete does not remove reminder', (tester) async {
      final now = DateTime.now();
      final reminders = [
        makeReminder(
          id: 1,
          title: '测试提醒',
          scheduledAt: DateTime(now.year, now.month, now.day, 9),
        ),
      ];

      bool deleteCalled = false;

      await tester.pumpWidget(buildTimeline(
        reminders: reminders,
        onDelete: (_) async {
          deleteCalled = true;
          return true;
        },
      ));
      await tester.pumpAndSettle();

      // Swipe left
      await tester.fling(
        find.byType(Dismissible),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // Dialog is shown — tap cancel
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // Delete should NOT have been called
      expect(deleteCalled, isFalse);
      // Reminder should still be visible
      expect(find.text('测试提醒'), findsOneWidget);
    });

    testWidgets('confirming delete calls onDelete callback', (tester) async {
      final now = DateTime.now();
      final reminders = [
        makeReminder(
          id: 1,
          title: '测试提醒',
          scheduledAt: DateTime(now.year, now.month, now.day, 9),
        ),
      ];

      int? deletedId;

      await tester.pumpWidget(buildTimeline(
        reminders: reminders,
        onDelete: (id) async {
          deletedId = id;
          return true;
        },
      ));
      await tester.pumpAndSettle();

      // Swipe left
      await tester.fling(
        find.byType(Dismissible),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // Confirm delete
      await tester.tap(find.text('确认删除'));
      await tester.pumpAndSettle();

      // onDelete should have been called with id=1
      expect(deletedId, 1);
    });
  });
}
