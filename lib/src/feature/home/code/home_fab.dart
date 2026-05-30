/// FAB 展开菜单
///
/// 主按钮点击展开/收起两个子项（手动添加 + 语音录入），
/// 展开时主按钮旋转 45° 动画。
library;

import 'package:flutter/material.dart';

/// FAB 展开菜单
///
/// StatefulWidget，管理展开/收起状态和动画。
class HomeFab extends StatefulWidget {
  /// 手动添加路由
  final String addRoute;

  /// 语音录入路由
  final String voiceRoute;

  const HomeFab({
    super.key,
    this.addRoute = '/add',
    this.voiceRoute = '/voice',
  });

  @override
  State<HomeFab> createState() => _HomeFabState();
}

class _HomeFabState extends State<HomeFab>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _navigate(String route) {
    // 收起菜单再导航
    _toggle();
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 子项：语音录入
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 标签
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _isExpanded ? 1.0 : 0.0,
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '语音录入',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      FloatingActionButton.small(
                        heroTag: 'voice',
                        onPressed: () => _navigate(widget.voiceRoute),
                        child: const Icon(Icons.mic),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // 子项：手动添加
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _isExpanded ? 1.0 : 0.0,
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '手动添加',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      FloatingActionButton.small(
                        heroTag: 'add',
                        onPressed: () => _navigate(widget.addRoute),
                        child: const Icon(Icons.edit_note),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // 主按钮
        FloatingActionButton(
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
