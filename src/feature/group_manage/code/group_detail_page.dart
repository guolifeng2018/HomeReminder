import 'package:flutter/material.dart';

/// 分组详情占位页面
///
/// 后续 F-xx 负责实现完整分组详情 UI。
class GroupDetailPage extends StatelessWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('分组详情 $groupId')),
      body: const Center(child: Text('分组详情')),
    );
  }
}
