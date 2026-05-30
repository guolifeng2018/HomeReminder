/// 状态筛选 TabBar
///
/// 使用 ChoiceChip 横向排列 4 个筛选选项（全部/待处理/已过期/已完成）。
library;

import 'package:flutter/material.dart';

import '../../../core/common/code/models/enums.dart';

/// 状态筛选组件
///
/// 接收当前选中的状态和 onChanged 回调。
class StatusFilterBar extends StatelessWidget {
  /// 当前选中的状态（null = 全部）
  final ReminderStatus? selected;

  /// 选中变化回调
  final void Function(ReminderStatus?) onChanged;

  const StatusFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// 选项定义：[(标签, 值)]
  static const _options = <(String, ReminderStatus?)>[
    ('全部', null),
    ('待处理', ReminderStatus.pending),
    ('已过期', ReminderStatus.overdue),
    ('已完成', ReminderStatus.completed),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: _options.map((option) {
          final (label, value) = option;
          final isSelected = selected == value;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            selectedColor: Colors.blue.shade100,
            onSelected: (_) => onChanged(value),
          );
        }).toList(),
      ),
    );
  }
}
