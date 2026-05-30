/// 今日待办时间线列表
///
/// 垂直时间轴 + 分组色条的待办列表，按 scheduledAt ASC 排列。
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/common/code/models/reminder_model.dart';
import '../../../core/common/code/models/group_model.dart';

/// 今日待办时间线列表
///
/// 接收 reminders、分组映射、可选 onTap 回调。
class TodayTimeline extends StatelessWidget {
  /// 待办列表
  final List<Reminder> reminders;

  /// 分组 ID → 分组 映射
  final Map<int, Group> groupMap;

  /// 点击回调
  final void Function(int reminderId)? onTap;

  const TodayTimeline({
    super.key,
    required this.reminders,
    required this.groupMap,
    this.onTap,
  });

  /// 根据 groupId 生成 HSL 颜色
  static Color _colorForGroup(int groupId) {
    return HSLColor.fromAHSL(1.0, (groupId * 47) % 360, 0.6, 0.5).toColor();
  }

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Text(
            '今日暂无待办',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        final isFirst = index == 0;
        final isLast = index == reminders.length - 1;
        return _TimelineItem(
          reminder: reminder,
          groupColor: _colorForGroup(reminder.groupId),
          isFirst: isFirst,
          isLast: isLast,
          onTap: onTap != null ? () => onTap!(reminder.id) : null,
        );
      },
    );
  }
}

/// 单条时间线项
class _TimelineItem extends StatelessWidget {
  final Reminder reminder;
  final Color groupColor;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  const _TimelineItem({
    required this.reminder,
    required this.groupColor,
    required this.isFirst,
    required this.isLast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(reminder.scheduledAt);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧时间轴
          SizedBox(
            width: 64,
            child: Column(
              children: [
                // 上线段（首项隐藏）
                if (isFirst)
                  const SizedBox(height: 12)
                else
                  Container(
                    width: 2,
                    height: 12,
                    color: Colors.grey.shade300,
                  ),
                // 时间文本 + 圆点（纵向排列节省水平空间）
                SizedBox(
                  height: 36,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: groupColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // 下线段（末项隐藏）
                if (isLast)
                  const SizedBox(height: 12)
                else
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),
          // 右侧卡片
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 4, top: 4),
              child: Material(
                color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                elevation: 1,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                reminder.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (reminder.content != null &&
                                  reminder.content!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  reminder.content!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // 分组色条
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: groupColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
