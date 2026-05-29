import 'package:flutter/material.dart';

/// 手动添加提醒占位页面
///
/// F-08 负责实现完整表单 UI。
class AddReminderPage extends StatelessWidget {
  const AddReminderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加提醒')),
      body: const Center(child: Text('添加提醒')),
    );
  }
}
