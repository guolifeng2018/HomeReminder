/// 通知内容模板构建器
///
/// 根据 Reminder 实体和分组名构建平台特定的通知内容详情。
/// 处理 title 降级、body 截断、空值安全等边界场景。
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../common/code/models/reminder_model.dart';
import 'notification_initializer.dart';

/// 通知内容构建器
///
/// 纯函数工具类，无状态。输入 Reminder + 分组名，
/// 输出 AndroidNotificationDetails / DarwinNotificationDetails。
class NotificationContentBuilder {
  /// 空标题时的降级文案
  static const String fallbackTitle = '未命名提醒';

  /// 构建 Android 通知详情
  ///
  /// [reminder] 提醒实体
  /// [groupName] 分组名称（用于 title 前缀格式化）
  AndroidNotificationDetails buildAndroid(
      Reminder reminder, String groupName) {
    final title = _buildTitle(reminder.title);
    final formattedTitle = '[$groupName] $title';

    return AndroidNotificationDetails(
      NotificationInitializer.channelId,
      NotificationInitializer.channelName,
      channelDescription: NotificationInitializer.channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: formattedTitle,
    );
  }

  /// 构建 iOS 通知详情
  ///
  /// [reminder] 提醒实体
  /// [groupName] 分组名称（用于 title 前缀格式化）
  DarwinNotificationDetails buildDarwin(
      Reminder reminder, String groupName) {
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: reminder.title.isNotEmpty ? reminder.title : null,
    );
  }

  /// 构建通知标题（含降级处理）
  String _buildTitle(String title) {
    if (title.isEmpty) return fallbackTitle;
    return title;
  }

}
