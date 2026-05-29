import 'package:flutter/material.dart';

/// 批量清理占位页面
///
/// 后续 F-xx 负责实现完整清理 UI。
class CleanupPage extends StatelessWidget {
  const CleanupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('清理')),
      body: const Center(child: Text('清理')),
    );
  }
}
