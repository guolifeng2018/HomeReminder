import 'package:flutter/material.dart';

/// 首页占位页面
///
/// F-07 负责实现完整业务 UI。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('居净清单')),
      body: const Center(child: Text('首页')),
    );
  }
}
