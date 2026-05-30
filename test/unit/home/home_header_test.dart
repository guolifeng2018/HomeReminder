/// HomeHeader 单元测试
///
/// 覆盖：日期格式化、中文星期映射、天气占位渲染。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:home_reminder/src/feature/home/code/home_header.dart';

void main() {
  group('HomeHeader', () {
    testWidgets('renders date with Chinese weekday', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeHeader(),
          ),
        ),
      );

      // 验证日期文本存在
      final now = DateTime.now();
      final expectedDate = DateFormat('yyyy年M月d日').format(now);
      final weekdayEn = DateFormat('EEEE').format(now);
      final weekdayMap = {
        'Monday': '星期一',
        'Tuesday': '星期二',
        'Wednesday': '星期三',
        'Thursday': '星期四',
        'Friday': '星期五',
        'Saturday': '星期六',
        'Sunday': '星期日',
      };
      final expectedWeekday = weekdayMap[weekdayEn] ?? weekdayEn;
      final expectedText = '$expectedDate $expectedWeekday';

      expect(find.text(expectedText), findsOneWidget);
    });

    testWidgets('renders weather placeholder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeHeader(),
          ),
        ),
      );

      // 验证天气占位图标和文本
      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
      expect(find.text('--°'), findsOneWidget);
    });

    testWidgets('layout uses Row with spaceBetween', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeHeader(),
          ),
        ),
      );

      // 验证 Row 存在
      final row = tester.widget<Row>(find.byType(Row).first);
      expect(row.mainAxisAlignment, MainAxisAlignment.spaceBetween);
    });

    testWidgets('padding is 16 on all sides', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeHeader(),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, const EdgeInsets.all(16));
    });
  });
}
