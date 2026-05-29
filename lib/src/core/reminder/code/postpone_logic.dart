/// PostponeLogic — 推迟逻辑
///
/// 支持四种推迟模式：1 小时 / 3 小时 / 明天 / 自定义 Duration。
library;

/// 推迟预设
enum PostponePreset {
  oneHour,
  threeHours,
  tomorrow,
  custom,
}

class PostponeLogic {
  const PostponeLogic();

  /// 计算推迟后的时间
  ///
  /// [original] 原始时间。
  /// [preset] 预设推迟模式。
  /// [custom] 自定义时长（仅 [PostponePreset.custom] 时使用）。
  DateTime postpone(DateTime original, {
    required PostponePreset preset,
    Duration? custom,
  }) {
    switch (preset) {
      case PostponePreset.oneHour:
        return original.add(const Duration(hours: 1));
      case PostponePreset.threeHours:
        return original.add(const Duration(hours: 3));
      case PostponePreset.tomorrow:
        return DateTime(
          original.year, original.month, original.day + 1,
          original.hour, original.minute,
        );
      case PostponePreset.custom:
        return original.add(custom ?? const Duration(hours: 1));
    }
  }
}
