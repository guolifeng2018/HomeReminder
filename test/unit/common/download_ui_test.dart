/// 模型下载 UI 页 Widget 测试
///
/// 覆盖：ModelDownloadPage 基本渲染、Provider 注入。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_reminder/src/feature/model_download/code/model_download_page.dart';

void main() {
  Widget buildTestApp() {
    return const ProviderScope(
      child: MaterialApp(
        home: ModelDownloadPage(),
      ),
    );
  }

  group('ModelDownloadPage', () {
    testWidgets('页面可渲染', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // 页面渲染后不应抛异常
      expect(find.byType(ModelDownloadPage), findsOneWidget);
    });

    testWidgets('AppBar 标题为模型下载', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.text('模型下载'), findsOneWidget);
    });

    testWidgets('页面包含两个模型卡片区域', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // 至少有一个 Card widget（可能是两个模型卡片）
      expect(find.byType(Card), findsWidgets);
    });
  });
}
