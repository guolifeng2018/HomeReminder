/// NotificationService 真实实现
///
/// 使用 flutter_local_notifications 提供通知调度、取消和角标联动。
/// 实现 NotificationService 抽象接口。
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../providers/code/notification_service.dart';
import '../../common/code/models/reminder_model.dart';
import 'notification_initializer.dart';
import 'notification_content_builder.dart';
import 'notification_payload_handler.dart';
import 'badge_manager.dart';

/// 通知服务真实实现
///
/// 封装通知初始化和调度流程：
/// 1. 确保初始化
/// 2. 构建平台通知内容
/// 3. 生成点击 payload
/// 4. 调度通知
/// 5. 更新角标
class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationInitializer _initializer;
  final NotificationContentBuilder _contentBuilder;
  final BadgeManager _badgeManager;

  /// 创建 [NotificationServiceImpl]
  ///
  /// 所有参数均可选，便于测试注入。
  NotificationServiceImpl({
    FlutterLocalNotificationsPlugin? plugin,
    NotificationInitializer? initializer,
    NotificationContentBuilder? contentBuilder,
    BadgeManager? badgeManager,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _initializer = initializer ??
            NotificationInitializer(plugin:
                plugin ?? FlutterLocalNotificationsPlugin()),
        _contentBuilder = contentBuilder ?? NotificationContentBuilder(),
        _badgeManager = badgeManager ?? BadgeManager();

  /// 调度通知（完整流程，接收 Reminder + 分组名）
  ///
  /// [reminder] 提醒实体
  /// [groupName] 分组名称
  /// [pendingCount] 当前待处理总数（用于角标更新）
  /// [overdueCount] 当前过期总数（用于角标更新）
  Future<void> show(
    Reminder reminder,
    String groupName, {
    int pendingCount = 0,
    int overdueCount = 0,
  }) async {
    try {
      await _initializer.ensureInitialized();

      // 如果初始化失败（降级为 no-op），跳过通知
      if (_initializer.initFailed) return;

      final androidDetails =
          _contentBuilder.buildAndroid(reminder, groupName);
      final iosDetails =
          _contentBuilder.buildDarwin(reminder, groupName);

      final payload =
          NotificationPayloadHandler.encodePayload(reminder.id);

      final title = _contentBuilder.buildAndroid(reminder, groupName)
          .ticker;

      await _plugin.show(
        reminder.id,
        title,
        _buildBodyText(reminder),
        NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: payload,
      );

      await _badgeManager.updateBadge(pendingCount, overdueCount);
    } catch (e, stack) {
      debugPrint('NotificationServiceImpl: 通知调度失败: $e\n$stack');
    }
  }

  /// 取消指定 ID 的通知
  Future<void> cancelReminderNotification(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e, stack) {
      debugPrint(
          'NotificationServiceImpl: 取消通知失败 (id=$id): $e\n$stack');
    }
  }

  /// 更新已存在的提醒（先取消再重新调度）
  ///
  /// [reminder] 更新后的提醒实体
  /// [groupName] 分组名称
  Future<void> updateNotification(
    Reminder reminder,
    String groupName, {
    int pendingCount = 0,
    int overdueCount = 0,
  }) async {
    await cancelReminderNotification(reminder.id);
    await show(
      reminder,
      groupName,
      pendingCount: pendingCount,
      overdueCount: overdueCount,
    );
  }

  // ---- NotificationService 接口实现 ----

  @override
  Future<void> showNotification(String title, String body) async {
    // 简化接口：仅显示基本通知（无分组名、无 payload）
    try {
      await _initializer.ensureInitialized();
      if (_initializer.initFailed) return;

      await _plugin.show(
        0, // 使用固定 ID 0
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            NotificationInitializer.channelId,
            NotificationInitializer.channelName,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e, stack) {
      debugPrint('NotificationServiceImpl: showNotification 失败: $e\n$stack');
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      await _badgeManager.updateBadge(0, 0);
    } catch (e, stack) {
      debugPrint('NotificationServiceImpl: cancelAll 失败: $e\n$stack');
    }
  }

  /// 构建 body 文本
  String _buildBodyText(Reminder reminder) {
    if (reminder.content != null && reminder.content!.isNotEmpty) {
      return '${reminder.title} — ${reminder.content}';
    }
    return reminder.title;
  }
}
