import 'package:flutter/material.dart';

/// 模型下载占位页面
///
/// F-09 负责实现完整下载管理 UI。
class ModelDownloadPage extends StatelessWidget {
  const ModelDownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模型下载')),
      body: const Center(child: Text('模型下载')),
    );
  }
}
