/// ReminderService 抽象接口 + Stub 实现
///
/// 提醒相关服务：创建/更新/删除提醒、时间解析、推迟、重试。
/// 真实实现由 F-05（core/reminder）的 ReminderServiceImpl 提供。
library;

import '../../common/code/models/enums.dart';
import '../../common/code/models/reminder_model.dart';
import '../../reminder/code/postpone_logic.dart';

/// 提醒服务抽象接口
///
/// F-05 扩展了 F-03 的原始接口，新增时间解析、推迟、重试等方法。
abstract class ReminderService {
  /// 调度提醒（F-03 旧接口，保留兼容）
  Future<void> scheduleReminder(dynamic reminder);

  /// 取消提醒（F-03 旧接口，保留兼容）
  Future<void> cancelReminder(int id);

  /// 解析口语时间字符串
  DateTime? parseTime(String input, {DateTime? referenceDate});

  /// 创建提醒并写入数据库
  Future<Reminder> createReminder({
    required int groupId,
    required String title,
    String? content,
    required DateTime scheduledAt,
    ReminderStatus status = ReminderStatus.pending,
    ReminderFrequency frequency = ReminderFrequency.once,
  });

  /// 推迟提醒
  Future<void> postponeReminder(int id, PostponePreset preset,
      {Duration? custom});

  /// 获取下次重试时间
  DateTime? getNextRetryTime(int attemptNumber, DateTime originalTime);

  /// 扫描并标记过期提醒，返回更新数量
  Future<int> checkOverdue();
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

  @override
  DateTime? parseTime(String input, {DateTime? referenceDate}) {
    throw UnimplementedError('F-03 stub: ReminderService.parseTime');
  }

  @override
  Future<Reminder> createReminder({
    required int groupId,
    required String title,
    String? content,
    required DateTime scheduledAt,
    ReminderStatus status = ReminderStatus.pending,
    ReminderFrequency frequency = ReminderFrequency.once,
  }) {
    throw UnimplementedError('F-03 stub: ReminderService.createReminder');
  }

  @override
  Future<void> postponeReminder(int id, PostponePreset preset,
      {Duration? custom}) {
    throw UnimplementedError('F-03 stub: ReminderService.postponeReminder');
  }

  @override
  DateTime? getNextRetryTime(int attemptNumber, DateTime originalTime) {
    throw UnimplementedError('F-03 stub: ReminderService.getNextRetryTime');
  }

  @override
  Future<int> checkOverdue() {
    throw UnimplementedError('F-03 stub: ReminderService.checkOverdue');
  }
}
