/// ReminderService 抽象接口 + Stub 实现
///
/// 提醒相关服务：创建/更新/删除提醒、时间解析。
/// 真实实现留给 F-05（core/reminder）。
library;

/// 提醒服务抽象接口
abstract class ReminderService {
  /// 调度提醒
  Future<void> scheduleReminder(dynamic reminder);

  /// 取消提醒
  Future<void> cancelReminder(int id);
}

/// ReminderService stub 实现
///
/// 所有方法抛出 [UnimplementedError]，后续模块通过
/// ProviderScope.overrides 替换为真实实现。
class StubReminderService implements ReminderService {
  @override
  Future<void> scheduleReminder(dynamic reminder) {
    throw UnimplementedError('F-03 stub: ReminderService.scheduleReminder');
  }

  @override
  Future<void> cancelReminder(int id) {
    throw UnimplementedError('F-03 stub: ReminderService.cancelReminder');
  }
}
