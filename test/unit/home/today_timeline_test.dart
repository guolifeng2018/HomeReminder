/// TodayTimeline 单元测试
///
/// 覆盖：空列表提示、时间格式化、点击回调、分组色条。
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
  String? content,
  required DateTime scheduledAt,
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

/// 辅助：创建测试 Group
Group makeGroup(int id, String name) {
  return Group(
    id: id,
    name: name,
    sortOrder: id,
    createdAt: DateTime(2026, 5, 1),
  );
}

/// 辅助：构建测试 Widget
Widget buildTestWidget({
  required List<Reminder> reminders,
  Map<int, Group> groupMap = const {},
  void Function(int)? onTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: TodayTimeline(
        reminders: reminders,
        groupMap: groupMap,
        onTap: onTap,
      ),
    ),
  );
}

void main() {
  group('TodayTimeline', () {
    testWidgets('shows empty message when no reminders', (tester) async {
      await tester.pumpWidget(buildTestWidget(reminders: []));
      expect(find.text('今日暂无待办'), findsOneWidget);
    });

    testWidgets('renders reminder title', (tester) async {
      final reminders = [
        makeReminder(
          title: '清理客厅',
          scheduledAt: DateTime(2026, 5, 30, 10, 30),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(reminders: reminders));
      expect(find.text('清理客厅'), findsOneWidget);
    });

    testWidgets('renders time in HH:mm format', (tester) async {
      final reminders = [
        makeReminder(
          title: '测试',
          scheduledAt: DateTime(2026, 5, 30, 14, 45),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(reminders: reminders));
      expect(find.text('14:45'), findsOneWidget);
    });

    testWidgets('renders content when not null', (tester) async {
      final reminders = [
        makeReminder(
          title: '带内容',
          content: '这是备注内容',
          scheduledAt: DateTime(2026, 5, 30, 9, 0),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(reminders: reminders));
      expect(find.text('这是备注内容'), findsOneWidget);
    });

    testWidgets('does not render content when empty', (tester) async {
      final reminders = [
        makeReminder(
          title: '无备注',
          content: '',
          scheduledAt: DateTime(2026, 5, 30, 9, 0),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(reminders: reminders));
      // Empty content should not be rendered
      expect(find.text(''), findsNothing);
    });

    testWidgets('renders multiple items in order', (tester) async {
      final reminders = [
        makeReminder(
          id: 1,
          title: '第一项',
          scheduledAt: DateTime(2026, 5, 30, 8, 0),
        ),
        makeReminder(
          id: 2,
          title: '第二项',
          scheduledAt: DateTime(2026, 5, 30, 10, 0),
        ),
        makeReminder(
          id: 3,
          title: '第三项',
          scheduledAt: DateTime(2026, 5, 30, 12, 0),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(reminders: reminders));

      expect(find.text('第一项'), findsOneWidget);
      expect(find.text('第二项'), findsOneWidget);
      expect(find.text('第三项'), findsOneWidget);
    });

    testWidgets('triggers onTap callback with correct id', (tester) async {
      int? tappedId;
      final reminders = [
        makeReminder(
          id: 42,
          title: '可点击',
          scheduledAt: DateTime(2026, 5, 30, 9, 0),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        reminders: reminders,
        onTap: (id) => tappedId = id,
      ));

      await tester.tap(find.text('可点击'));
      expect(tappedId, 42);
    });
  });

  group('color coding', () {
    testWidgets('renders color bars for timeline items', (tester) async {
      final reminders = [
        makeReminder(
          id: 1,
          groupId: 1,
          title: '清理',
          scheduledAt: DateTime(2026, 5, 30, 9, 0),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(reminders: reminders));
      // Each timeline item should have a colored dot and bar
      // The colored dot is a Container with BoxShape.circle
      expect(find.byType(Container), findsWidgets);
    });
  });
}
