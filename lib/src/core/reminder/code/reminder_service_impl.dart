/// ReminderServiceImpl — 提醒服务实现
///
/// 整合时间解析、调度、推迟、重试四个子引擎，通过 Provider 暴露。
/// 注入 GroupRepository + ReminderRepository，由 F-06 notification 层
/// 使用本模块计算结果执行系统闹钟注册。
library;

import '../../common/code/models/enums.dart';
import '../../common/code/models/reminder_model.dart';
import '../../database/code/reminder_repository.dart';
import '../../providers/code/reminder_service.dart';
import 'postpone_logic.dart';
import 'reminder_scheduler.dart';
import 'retry_policy.dart';
import 'spoken_time_parser.dart';

/// ReminderService 完整实现
///
/// 通过构造函数注入依赖，替代 F-03 的 [StubReminderService]。
class ReminderServiceImpl implements ReminderService {
  final ReminderRepository _reminderRepo;
  final ReminderScheduler _scheduler;
  final PostponeLogic _postponeLogic;
  final RetryPolicy _retryPolicy;

  ReminderServiceImpl({
    required ReminderRepository reminderRepo,
    ReminderScheduler? scheduler,
    PostponeLogic? postponeLogic,
    RetryPolicy? retryPolicy,
  })  : _reminderRepo = reminderRepo,
        _scheduler = scheduler ?? const ReminderScheduler(),
        _postponeLogic = postponeLogic ?? const PostponeLogic(),
        _retryPolicy = retryPolicy ?? const RetryPolicy();

  /// 解析口语时间字符串（委托静态解析器）
  DateTime? parseTime(String input, {DateTime? referenceDate}) {
    return SpokenTimeParser.parse(input, referenceDate: referenceDate);
  }

  /// 计算推迟后的时间
  DateTime postponeTime(DateTime original, PostponePreset preset,
      {Duration? custom}) {
    return _postponeLogic.postpone(original, preset: preset, custom: custom);
  }

  /// 获取下次重试时间
  DateTime? getNextRetry(int attemptNumber, DateTime originalTime) {
    return _retryPolicy.nextRetryTime(attemptNumber, originalTime);
  }

  /// 创建提醒并写入数据库
  ///
  /// [groupId] 为 0 时抛出 [ArgumentError]。
  /// [title] 为空时抛出 [ArgumentError]。
  Future<Reminder> createReminder({
    required int groupId,
    required String title,
    String? content,
    required DateTime scheduledAt,
    ReminderStatus status = ReminderStatus.pending,
    ReminderFrequency frequency = ReminderFrequency.once,
  }) async {
    if (groupId == 0) {
      throw ArgumentError('groupId must not be 0');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('title must not be empty');
    }

    final reminder = Reminder(
      groupId: groupId,
      title: title.trim(),
      content: content?.trim(),
      scheduledAt: scheduledAt,
      status: status,
      frequency: frequency,
      createdAt: DateTime.now(),
    );

    return _reminderRepo.insert(reminder);
  }

  /// 扫描并标记过期提醒
  ///
  /// 查询 status=pending + scheduledAt < now 的提醒，
  /// 批量标记为 overdue，返回已更新的提醒列表。
  Future<List<Reminder>> checkOverdue() async {
    final overdue = await _reminderRepo.getOverdue();
    final updated = <Reminder>[];

    for (final r in overdue) {
      if (_scheduler.shouldSkip(r.status)) continue;

      // 标记为 overdue
      if (r.status == ReminderStatus.pending) {
        final updatedReminder = r.copyWith(
          status: ReminderStatus.overdue,
          updatedAt: DateTime.now(),
        );
        await _reminderRepo.update(updatedReminder);
        updated.add(updatedReminder);
      }
    }

    return updated;
  }

  /// 推迟提醒
  ///
  /// 更新 scheduledAt，重置状态为 pending。
  Future<void> postponeReminder(int id, PostponePreset preset,
      {Duration? custom}) async {
    final reminder = await _reminderRepo.getById(id);
    if (reminder == null) return;

    final newTime = _postponeLogic.postpone(
      reminder.scheduledAt,
      preset: preset,
      custom: custom,
    );

    final updated = reminder.copyWith(
      scheduledAt: newTime,
      status: ReminderStatus.pending,
      updatedAt: DateTime.now(),
    );

    await _reminderRepo.update(updated);
  }

  /// 计算提醒的下次触发时间（基于频率）
  DateTime nextTriggerTime(Reminder reminder) {
    return _scheduler.nextTriggerTime(
        reminder.scheduledAt, reminder.frequency);
  }

  /// 取消提醒
  @override
  Future<void> cancelReminder(int id) async {
    final reminder = await _reminderRepo.getById(id);
    if (reminder == null) return;

    final updated = reminder.copyWith(
      status: ReminderStatus.dismissed,
      updatedAt: DateTime.now(),
    );
    await _reminderRepo.update(updated);
  }

  /// 调度提醒（兼容 F-03 抽象接口）
  @override
  Future<void> scheduleReminder(dynamic reminder) async {
    if (reminder is! Reminder) return;
    await _reminderRepo.insert(reminder);
  }
}
