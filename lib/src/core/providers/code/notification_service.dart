/// NotificationService 抽象接口 + Stub 实现
///
/// 通知推送服务：本地通知调度/取消。
/// 真实实现留给 F-06（core/notification）。
library;

/// 通知服务抽象接口
abstract class NotificationService {
  /// 显示通知
  Future<void> showNotification(String title, String body);

  /// 取消所有通知
  Future<void> cancelAll();
}

/// NotificationService stub 实现
///
/// 所有方法抛出 [UnimplementedError]，后续模块通过
/// ProviderScope.overrides 替换为真实实现。
class StubNotificationService implements NotificationService {
  @override
  Future<void> showNotification(String title, String body) {
    throw UnimplementedError(
        'F-03 stub: NotificationService.showNotification');
  }

  @override
  Future<void> cancelAll() {
    throw UnimplementedError('F-03 stub: NotificationService.cancelAll');
  }
}
