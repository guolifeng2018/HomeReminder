/// 空状态组件
///
/// 首页无数据时显示的空状态：图标 + 引导文案 + FAB 留白。
library;

import 'package:flutter/material.dart';

/// 首页空状态组件
///
/// 居中显示 house 图标 + 提示文本，底部留出 FAB 空间。
class EmptyHomeView extends StatelessWidget {
  const EmptyHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有提醒',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方 + 添加',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
