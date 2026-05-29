/// 路由单元测试
///
/// 覆盖：7 条路由映射、4 场景 redirect 守卫、深层链接、导航栈、download 页不拦截。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:home_reminder/src/router/router.dart';
import 'package:home_reminder/src/core/providers/providers.dart';

/// 辅助函数：构建已配置 ProviderScope + MaterialApp.router 的 widget。
///
/// 通过 [overrides] 传入预配置的 appConfigProvider 来模拟不同状态。
Widget buildTestApp({
  required GoRouter router,
  required AppConfigNotifier configNotifier,
}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWith((ref) => configNotifier),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

/// 辅助函数：创建预配置状态的 AppConfigNotifier
AppConfigNotifier createNotifier({
  bool isFirstLaunch = false,
  ModelDownloadStatus modelDownloadStatus = ModelDownloadStatus.completed,
}) {
  final notifier = AppConfigNotifier();
  notifier.setFirstLaunch(isFirstLaunch);
  notifier.setModelDownloadStatus(modelDownloadStatus);
  return notifier;
}

void main() {
  group('路由映射（7 条）', () {
    testWidgets('GET / 路由到 HomePage', (tester) async {
      final notifier = createNotifier();
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWith((ref) => notifier),
      ]);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(buildTestApp(
        router: router,
        configNotifier: notifier,
      ));

      router.go('/');
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/');
    });

    testWidgets('GET /add 路由到 AddReminderPage', (tester) async {
      final notifier = createNotifier();
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWith((ref) => notifier),
      ]);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(buildTestApp(
        router: router,
        configNotifier: notifier,
      ));

      router.go('/add');
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/add');
    });

    testWidgets('GET /voice 路由到 VoiceInputPage', (tester) async {
      final notifier = createNotifier();
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWith((ref) => notifier),
      ]);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(buildTestApp(
        router: router,
        configNotifier: notifier,
      ));

      router.go('/voice');
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/voice');
    });

    testWidgets('GET /groups 路由到 GroupManagePage', (tester) async {
      final notifier = createNotifier();
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWith((ref) => notifier),
      ]);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(buildTestApp(
        router: router,
        configNotifier: notifier,
      ));

      router.go('/groups');
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/groups');
    });

    testWidgets('GET /group/:id 路由到 GroupDetailPage', (tester) async {
      final notifier = createNotifier();
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWith((ref) => notifier),
      ]);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(buildTestApp(
        router: router,
        configNotifier: notifier,
      ));

      router.go('/group/3');
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/group/3');
      expect(router.state.pathParameters['id'], '3');
    });

    testWidgets('GET /cleanup 路由到 CleanupPage', (tester) async {
      final notifier = createNotifier();
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWith((ref) => notifier),
      ]);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(buildTestApp(
        router: router,
        configNotifier: notifier,
      ));

      router.go('/cleanup');
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/cleanup');
    });

    testWidgets('GET /download 路由到 ModelDownloadPage', (tester) async {
      final notifier = createNotifier();
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWith((ref) => notifier),
      ]);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(buildTestApp(
        router: router,
        configNotifier: notifier,
      ));

      router.go('/download');
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/download');
    });
  });

  group('redirect 守卫（4 场景）', () {
    testWidgets('首次+未就绪 → redirect /download', (tester) async {
      final notifier = createNotifier(
        isFirstLaunch: true,
        modelDownloadStatus: ModelDownloadStatus.idle,
      );
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWith((ref) => notifier),
      ]);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(buildTestApp(
        router: router,
        configNotifier: notifier,
      ));

      router.go('/');
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/download');
    });

    testWidgets('首次+已就绪 → 放行（不重定向）', (tester) async {
      final notifier = createNotifier(
        isFirstLaunch: true,
        modelDownloadStatus: ModelDownloadStatus.completed,
      );
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWith((ref) => notifier),
      ]);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(buildTestApp(
        router: router,
        configNotifier: notifier,
      ));

      router.go('/');
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/');
    });

    testWidgets('非首次+未就绪 → 放行（不重定向）', (tester) async {
      final notifier = createNotifier(
        isFirstLaunch: false,
        modelDownloadStatus: ModelDownloadStatus.idle,
      );
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWith((ref) => notifier),
      ]);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(buildTestApp(
        router: router,
        configNotifier: notifier,
      ));

      router.go('/');
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/');
    });

    testWidgets('非首次+已就绪 → 放行（不重定向）', (tester) async {
      final notifier = createNotifier(
        isFirstLaunch: false,
        modelDownloadStatus: ModelDownloadStatus.completed,
      );
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWith((ref) => notifier),
      ]);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(buildTestApp(
        router: router,
        configNotifier: notifier,
      ));

      router.go('/');
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/');
    });
  });

  group('深层链接', () {
    testWidgets('/group/3 → pathParameters[\'id\'] == \'3\'', (tester) async {
      final notifier = createNotifier();
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWith((ref) => notifier),
      ]);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(buildTestApp(
        router: router,
        configNotifier: notifier,
      ));

      router.go('/group/3');
      await tester.pumpAndSettle();

      expect(router.state.pathParameters['id'], '3');
    });
  });

  group('导航栈', () {
    testWidgets('go → push → canPop == true', (tester) async {
      final notifier = createNotifier();
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWith((ref) => notifier),
      ]);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(buildTestApp(
        router: router,
        configNotifier: notifier,
      ));

      router.go('/');
      await tester.pumpAndSettle();

      // push 到 /add
      router.push('/add');
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/add');
      // 有上一页可返回
      expect(router.canPop(), isTrue);
    });
  });

  group('download 页不拦截', () {
    testWidgets('在 /download 时守卫不重定向', (tester) async {
      final notifier = createNotifier(
        isFirstLaunch: true,
        modelDownloadStatus: ModelDownloadStatus.idle,
      );
      final container = ProviderContainer(overrides: [
        appConfigProvider.overrideWith((ref) => notifier),
      ]);
      final router = container.read(appRouterProvider);

      await tester.pumpWidget(buildTestApp(
        router: router,
        configNotifier: notifier,
      ));

      router.go('/download');
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/download');
    });
  });
}
