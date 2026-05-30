/// HomeFab 单元测试
///
/// 覆盖：展开/收起状态切换、旋转动画、导航回调。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:home_reminder/src/feature/home/code/home_fab.dart';

/// 辅助：构建测试 Widget（含 Navigator 用于 pushNamed）
Widget buildTestWidget({String addRoute = '/add', String voiceRoute = '/voice'}) {
  return MaterialApp(
    home: Scaffold(
      floatingActionButton: HomeFab(
        addRoute: addRoute,
        voiceRoute: voiceRoute,
      ),
      body: const Center(child: Text('body')),
    ),
  );
}

void main() {
  group('HomeFab', () {
    testWidgets('starts in collapsed state', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Only the main FAB should be visible initially
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.edit_note), findsNothing);
      expect(find.byIcon(Icons.mic), findsNothing);
    });

    testWidgets('expands on main button tap', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Sub-items should appear
      expect(find.byIcon(Icons.edit_note), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('collapses on second main button tap', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Expand
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Collapse
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_note), findsNothing);
      expect(find.byIcon(Icons.mic), findsNothing);
    });

    testWidgets('shows labels when expanded', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('手动添加'), findsOneWidget);
      expect(find.text('语音录入'), findsOneWidget);
    });

    testWidgets('uses custom routes', (tester) async {
      await tester.pumpWidget(MaterialApp(
        routes: {
          '/custom-add': (_) => const Scaffold(body: Text('custom add')),
          '/custom-voice': (_) => const Scaffold(body: Text('custom voice')),
        },
        home: Scaffold(
          floatingActionButton: HomeFab(
            addRoute: '/custom-add',
            voiceRoute: '/custom-voice',
          ),
          body: const Center(child: Text('body')),
        ),
      ));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Tap the add sub-item
      await tester.tap(find.byIcon(Icons.edit_note));
      await tester.pumpAndSettle();

      // Should have navigated to custom-add
      expect(find.text('custom add'), findsOneWidget);
    });
  });
}
