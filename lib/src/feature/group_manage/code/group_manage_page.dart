import 'package:flutter/material.dart';

/// 分组管理占位页面
///
/// 后续 F-xx 负责实现完整分组 CRUD UI。
class GroupManagePage extends StatelessWidget {
  const GroupManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分组管理')),
      body: const Center(child: Text('分组管理')),
    );
  }
}
