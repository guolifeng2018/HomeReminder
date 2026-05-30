/// StatusFilterBar 单元测试
///
/// 覆盖：4 个选项渲染、选中态切换、回调触发。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:home_reminder/src/feature/home/code/status_filter_bar.dart';
import 'package:home_reminder/src/core/common/code/models/enums.dart';

void main() {
  group('StatusFilterBar', () {
    testWidgets('renders all 4 filter options', (tester) async {
      ReminderStatus? selectedValue;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatusFilterBar(
            selected: null,
            onChanged: (v) => selectedValue = v,
          ),
        ),
      ));

      expect(find.text('全部'), findsOneWidget);
      expect(find.text('待处理'), findsOneWidget);
      expect(find.text('已过期'), findsOneWidget);
      expect(find.text('已完成'), findsOneWidget);
    });

    testWidgets('全部 is selected by default when selected=null',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatusFilterBar(
            selected: null,
            onChanged: (_) {},
          ),
        ),
      ));

      final allChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '全部'),
      );
      expect(allChip.selected, isTrue);
    });

    testWidgets('待处理 is selected when selected=ReminderStatus.pending',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatusFilterBar(
            selected: ReminderStatus.pending,
            onChanged: (_) {},
          ),
        ),
      ));

      final pendingChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '待处理'),
      );
      expect(pendingChip.selected, isTrue);

      final allChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '全部'),
      );
      expect(allChip.selected, isFalse);
    });

    testWidgets('calls onChanged with correct value when chip tapped',
        (tester) async {
      ReminderStatus? selectedValue;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatusFilterBar(
            selected: null,
            onChanged: (v) => selectedValue = v,
          ),
        ),
      ));

      await tester.tap(find.text('已完成'));
      expect(selectedValue, ReminderStatus.completed);
    });

    testWidgets('calls onChanged with null when 全部 tapped',
        (tester) async {
      ReminderStatus? selectedValue = ReminderStatus.pending;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatusFilterBar(
            selected: ReminderStatus.pending,
            onChanged: (v) => selectedValue = v,
          ),
        ),
      ));

      await tester.tap(find.text('全部'));
      expect(selectedValue, isNull);
    });
  });
}
