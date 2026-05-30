/// 应用路由配置
///
/// GoRouter 路由表 + 首次启动→模型下载 redirect 守卫。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/providers.dart';
import '../../feature/home/code/reminder_form_page.dart';
import 'placeholder_pages.dart';

/// 路由 redirect 守卫
///
/// 规则：当 isFirstLaunch == true 且 modelDownloadStatus != completed 时，
/// 将除 /download 外的所有路由重定向到 /download。
String? _guardRedirect(BuildContext context, GoRouterState state) {
  final container = ProviderScope.containerOf(context);
  final appConfig = container.read(appConfigProvider);
  final location = state.uri.toString();

  // 已在下载页 → 不拦截（避免无限重定向循环）
  if (location == '/download') {
    return null;
  }

  // 首次启动且模型未就绪 → 重定向到下载页
  if (appConfig.isFirstLaunch &&
      appConfig.modelDownloadStatus != ModelDownloadStatus.completed) {
    return '/download';
  }

  return null; // 放行
}

/// 全局 GoRouter Provider
///
/// 7 条路由平铺，无嵌套 ShellRoute。
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: _guardRedirect,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/add',
        builder: (context, state) => const ReminderFormPage(),
      ),
      GoRoute(
        path: '/voice',
        builder: (context, state) => const VoiceInputPage(),
      ),
      GoRoute(
        path: '/groups',
        builder: (context, state) => const GroupManagePage(),
      ),
      GoRoute(
        path: '/group/:id',
        builder: (context, state) => GroupDetailPage(
          groupId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/cleanup',
        builder: (context, state) => const CleanupPage(),
      ),
      GoRoute(
        path: '/download',
        builder: (context, state) => const ModelDownloadPage(),
      ),
    ],
  );
});
