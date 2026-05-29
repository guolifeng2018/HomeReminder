/// 枚举定义
///
/// 包含提醒状态和重复频率两个核心枚举，
/// 提供序列化/反序列化、显示名称等功能。
library;

/// 提醒状态枚举
enum ReminderStatus {
  /// 待处理
  pending,

  /// 已过期
  overdue,

  /// 已完成
  completed,

  /// 已忽略
  dismissed;

  /// 从字符串反序列化（大小写不敏感）
  static ReminderStatus fromString(String value) {
    final lower = value.toLowerCase().trim();
    for (final status in ReminderStatus.values) {
      if (status.name.toLowerCase() == lower) {
        return status;
      }
    }
    return ReminderStatus.pending; // 默认值
  }

  /// 中文显示名称
  String get displayName {
    switch (this) {
      case ReminderStatus.pending:
        return '待处理';
      case ReminderStatus.overdue:
        return '已过期';
      case ReminderStatus.completed:
        return '已完成';
      case ReminderStatus.dismissed:
        return '已忽略';
    }
  }
}

/// 提醒重复频率枚举
enum ReminderFrequency {
  /// 一次性
  once,

  /// 每天
  daily,

  /// 每周
  weekly,

  /// 隔周
  biweekly,

  /// 每月
  monthly;

  /// 从字符串反序列化（大小写不敏感）
  static ReminderFrequency fromString(String value) {
    final lower = value.toLowerCase().trim();
    for (final freq in ReminderFrequency.values) {
      if (freq.name.toLowerCase() == lower) {
        return freq;
      }
    }
    return ReminderFrequency.once; // 默认值
  }

  /// 中文显示名称
  String get displayName {
    switch (this) {
      case ReminderFrequency.once:
        return '一次性';
      case ReminderFrequency.daily:
        return '每天';
      case ReminderFrequency.weekly:
        return '每周';
      case ReminderFrequency.biweekly:
        return '隔周';
      case ReminderFrequency.monthly:
        return '每月';
    }
  }
}
