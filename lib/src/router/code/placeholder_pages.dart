/// 占位页面 stub
///
/// 为尚未实现的 feature 页面提供最小 StatelessWidget 替身，
/// 使 GoRouter 路由配置可正常编译。
///
/// 各页面将在对应功能开发时替换为真实实现：
/// - F-07: HomePage, AddReminderPage
/// - F-13: VoiceInputPage
/// - F-14: GroupManagePage, GroupDetailPage
/// - F-15: CleanupPage
/// - F-09: ModelDownloadPage
library;

import 'package:flutter/material.dart';

/// 首页占位
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('首页')),
    );
  }
}

/// 手动录入页占位
class AddReminderPage extends StatelessWidget {
  const AddReminderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('添加提醒')),
    );
  }
}

/// 语音录入页占位
class VoiceInputPage extends StatelessWidget {
  const VoiceInputPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('语音录入')),
    );
  }
}

/// 分组管理页占位
class GroupManagePage extends StatelessWidget {
  const GroupManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('分组管理')),
    );
  }
}

/// 分组详情页占位
class GroupDetailPage extends StatelessWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('分组详情: $groupId')),
    );
  }
}

/// 批量清理页占位
class CleanupPage extends StatelessWidget {
  const CleanupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('批量清理')),
    );
  }
}

/// 模型下载页占位
class ModelDownloadPage extends StatelessWidget {
  const ModelDownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('模型下载')),
    );
  }
}
