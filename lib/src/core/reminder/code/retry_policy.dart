/// RetryPolicy — 重试机制
///
/// 3 次指数退避：5 分钟 → 15 分钟 → 45 分钟。
/// 超过 3 次不再重试（返回 null）。
library;

class RetryPolicy {
  const RetryPolicy();

  /// 退避间隔配置（分钟）
  static const _backoffMinutes = [5, 15, 45];

  /// 最大重试次数
  static const maxRetries = 3;

  /// 计算第 [attemptNumber] 次重试的时间
  ///
  /// [attemptNumber] 从 1 开始（第 1 次失败后）。
  /// [originalTime] 原始调度时间。
  ///
  /// 返回下次重试时间，超过 3 次返回 `null`。
  DateTime? nextRetryTime(int attemptNumber, DateTime originalTime) {
    if (attemptNumber < 1 || attemptNumber > maxRetries) {
      return null;
    }
    final minutes = _backoffMinutes[attemptNumber - 1];
    return originalTime.add(Duration(minutes: minutes));
  }

  /// 获取指定尝试次数的退避分钟数
  static int backoffMinutes(int attemptNumber) {
    if (attemptNumber < 1 || attemptNumber > maxRetries) return 0;
    return _backoffMinutes[attemptNumber - 1];
  }
}
