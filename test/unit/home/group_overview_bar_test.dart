/// GroupOverviewBar 单元测试
///
/// 覆盖：loading/empty/data/error 四态渲染，横向滚动列表。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:home_reminder/src/feature/home/code/group_overview_bar.dart';
import 'package:home_reminder/src/core/common/code/models/group_model.dart';

/// 辅助：创建测试 Group
Group makeGroup(int id, String name, String? icon, int sortOrder) {
  return Group(
    id: id,
    name: name,
    icon: icon,
    isPreset: true,
    sortOrder: sortOrder,
    createdAt: DateTime(2026, 5, 1),
  );
}

/// 辅助：构建测试 Widget
Widget buildTestWidget(GroupOverviewBar bar) {
  return MaterialApp(
    home: Scaffold(
      body: bar,
    ),
  );
}

void main() {
  group('GroupOverviewBar', () {
    testWidgets('shows loading placeholder when AsyncValue.loading',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(GroupOverviewBar(
        groups: const AsyncValue.loading(),
      )));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty placeholder when group list is empty',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(GroupOverviewBar(
        groups: const AsyncValue.data([]),
      )));

      expect(find.text('暂无分组'), findsOneWidget);
    });

    testWidgets('renders GroupOverviewCard for each group', (tester) async {
      final groups = [
        makeGroup(1, '客厅', 'living', 0),
        makeGroup(2, '卧室', 'bedroom', 1),
        makeGroup(3, '厨房', 'kitchen', 2),
      ];

      await tester.pumpWidget(buildTestWidget(GroupOverviewBar(
        groups: AsyncValue.data(groups),
      )));

      // 每个分组名都出现
      expect(find.text('客厅'), findsOneWidget);
      expect(find.text('卧室'), findsOneWidget);
      expect(find.text('厨房'), findsOneWidget);

      // 水平滚动列表
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.horizontal);
    });

    testWidgets('passes pending and completed counts to cards',
        (tester) async {
      final groups = [makeGroup(1, '测试', 'living', 0)];

      await tester.pumpWidget(buildTestWidget(GroupOverviewBar(
        groups: AsyncValue.data(groups),
        pendingCounts: {1: 3},
        completedCounts: {1: 7},
      )));

      // 70% = 7/10
      expect(find.text('70%'), findsOneWidget);
      // Badge shows 3
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows error placeholder on error', (tester) async {
      await tester.pumpWidget(buildTestWidget(GroupOverviewBar(
        groups: AsyncValue.error('test error', StackTrace.empty),
      )));

      expect(find.text('加载失败'), findsOneWidget);
    });

    testWidgets('uses count 0 for groups not in mapping', (tester) async {
      final groups = [makeGroup(1, '测试', 'living', 0)];

      await tester.pumpWidget(buildTestWidget(GroupOverviewBar(
        groups: AsyncValue.data(groups),
        pendingCounts: {}, // group 1 not mapped
        completedCounts: {},
      )));

      // Should show 0% (no badge since pendingCount=0, no counts mapped)
      expect(find.text('0%'), findsOneWidget);
    });
  });
}
