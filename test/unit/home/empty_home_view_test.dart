/// EmptyHomeView 单元测试
///
/// 覆盖：图标、主文案、副文案、FAB 留白渲染。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:home_reminder/src/feature/home/code/empty_home_view.dart';

void main() {
  group('EmptyHomeView', () {
    testWidgets('renders home icon', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EmptyHomeView()),
      ));

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('renders primary text', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EmptyHomeView()),
      ));

      expect(find.text('还没有提醒'), findsOneWidget);
    });

    testWidgets('renders secondary text', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EmptyHomeView()),
      ));

      expect(find.text('点击下方 + 添加'), findsOneWidget);
    });

    testWidgets('has FAB spacing (SizedBox height: 80)', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EmptyHomeView()),
      ));

      // Find the SizedBox with height 80
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      bool found80 = false;
      for (final box in sizedBoxes) {
        if (box.height == 80) {
          found80 = true;
          break;
        }
      }
      expect(found80, isTrue);
    });
  });
}
