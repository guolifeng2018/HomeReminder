/// GroupOverviewCard 单元测试
///
/// 覆盖：卡片渲染、图标映射、Badge 显示、完成率计算、环形进度。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:home_reminder/src/feature/home/code/group_overview_card.dart';
import 'package:home_reminder/src/core/common/code/models/group_model.dart';

/// 辅助函数：构建测试 Widget
Widget buildTestWidget({
  required Group group,
  int pendingCount = 0,
  int completedCount = 0,
}) {
  return MaterialApp(
    home: Scaffold(
      body: GroupOverviewCard(
        group: group,
        pendingCount: pendingCount,
        completedCount: completedCount,
      ),
    ),
  );
}

void main() {
  final testGroup = Group(
    id: 1,
    name: '客厅',
    icon: 'living',
    isPreset: true,
    sortOrder: 0,
    createdAt: DateTime(2026, 5, 1),
  );

  group('GroupOverviewCard', () {
    testWidgets('renders group name', (tester) async {
      await tester.pumpWidget(buildTestWidget(group: testGroup));
      expect(find.text('客厅'), findsOneWidget);
    });

    testWidgets('renders icon based on icon name', (tester) async {
      await tester.pumpWidget(buildTestWidget(group: testGroup));
      expect(find.byIcon(Icons.weekend), findsOneWidget);
    });

    testWidgets('renders default icon for unknown icon name', (tester) async {
      final unknownGroup = Group(
        id: 2,
        name: '未知',
        icon: 'unknown_icon_xyz',
        sortOrder: 1,
        createdAt: DateTime(2026, 5, 1),
      );
      await tester.pumpWidget(buildTestWidget(group: unknownGroup));
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
    });

    testWidgets('shows pending badge when count > 0', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        group: testGroup,
        pendingCount: 3,
      ));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('no badge when pending count is 0', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        group: testGroup,
        pendingCount: 0,
      ));
      // Badge text should not be present (no red badge)
      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows 100% when all completed', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        group: testGroup,
        pendingCount: 0,
        completedCount: 5,
      ));
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('shows 0% when none completed', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        group: testGroup,
        pendingCount: 5,
        completedCount: 0,
      ));
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('shows correct percentage for mixed counts', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        group: testGroup,
        pendingCount: 3,
        completedCount: 7,
      ));
      // 7/10 = 70%
      expect(find.text('70%'), findsOneWidget);
    });

    testWidgets('shows 0% when both counts are 0', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        group: testGroup,
        pendingCount: 0,
        completedCount: 0,
      ));
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('card has fixed width 140', (tester) async {
      await tester.pumpWidget(buildTestWidget(group: testGroup));
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 140);
    });
  });

  group('_iconFor mapping', () {
    testWidgets('maps kitchen to kitchen icon', (tester) async {
      final kitchenGroup = Group(
        id: 3,
        name: '厨房',
        icon: 'kitchen',
        sortOrder: 2,
        createdAt: DateTime(2026, 5, 1),
      );
      await tester.pumpWidget(buildTestWidget(group: kitchenGroup));
      expect(find.byIcon(Icons.kitchen), findsOneWidget);
    });

    testWidgets('maps bedroom to bed icon', (tester) async {
      final bedroomGroup = Group(
        id: 4,
        name: '卧室',
        icon: 'bedroom',
        sortOrder: 1,
        createdAt: DateTime(2026, 5, 1),
      );
      await tester.pumpWidget(buildTestWidget(group: bedroomGroup));
      expect(find.byIcon(Icons.bed), findsOneWidget);
    });

    testWidgets('maps vacuum to cleaning_services icon', (tester) async {
      final vacuumGroup = Group(
        id: 5,
        name: '扫地机',
        icon: 'vacuum',
        sortOrder: 4,
        createdAt: DateTime(2026, 5, 1),
      );
      await tester.pumpWidget(buildTestWidget(group: vacuumGroup));
      expect(find.byIcon(Icons.cleaning_services), findsOneWidget);
    });
  });

  group('CompletionRingPainter', () {
    test('shouldRepaint returns true for different ratios', () {
      final painter1 = CompletionRingPainter(ratio: 0.5);
      final painter2 = CompletionRingPainter(ratio: 0.7);
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns false for same ratio', () {
      final painter1 = CompletionRingPainter(ratio: 0.5);
      final painter2 = CompletionRingPainter(ratio: 0.5);
      expect(painter1.shouldRepaint(painter2), isFalse);
    });
  });
}
