/// 页面头部组件
///
/// 显示当前日期（yyyy年M月d日 星期X）+ 天气图标占位。
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 页面头部组件
///
/// StatelessWidget，左侧日期（日期+星期），右侧天气占位。
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  /// 中文星期映射
  static const Map<String, String> _weekdayMap = {
    'Monday': '星期一',
    'Tuesday': '星期二',
    'Wednesday': '星期三',
    'Thursday': '星期四',
    'Friday': '星期五',
    'Saturday': '星期六',
    'Sunday': '星期日',
  };

  /// 格式化当前日期
  String _formattedDate(DateTime now) {
    final dateStr = DateFormat('yyyy年M月d日').format(now);
    final weekdayEn = DateFormat('EEEE').format(now);
    final weekdayCn = _weekdayMap[weekdayEn] ?? weekdayEn;
    return '$dateStr $weekdayCn';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateText = _formattedDate(now);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧：日期
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          // 右侧：天气占位
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_outlined,
                color: Colors.grey.shade500,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '--°',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
