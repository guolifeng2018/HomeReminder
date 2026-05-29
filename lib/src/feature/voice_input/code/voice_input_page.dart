import 'package:flutter/material.dart';

/// 语音录入占位页面
///
/// F-10 负责实现完整录音 + ASR UI。
class VoiceInputPage extends StatelessWidget {
  const VoiceInputPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('语音录入')),
      body: const Center(child: Text('语音录入')),
    );
  }
}
