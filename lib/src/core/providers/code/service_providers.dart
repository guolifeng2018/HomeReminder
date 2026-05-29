/// 服务层 Provider
///
/// 提供 ReminderService / NotificationService / VoiceService 的依赖注入。
/// 默认注入 stub 实现，后续模块通过 ProviderScope.overrides 替换为真实实现。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reminder_service.dart';
import 'notification_service.dart';
import 'voice_service.dart';

/// 提醒服务 Provider
///
/// 默认注入 [StubReminderService]，F-05（core/reminder）通过
/// ProviderScope.overrides 替换为真实实现。
final reminderServiceProvider = Provider<ReminderService>((ref) {
  return StubReminderService();
});

/// 通知服务 Provider
///
/// 默认注入 [StubNotificationService]，F-06（core/notification）通过
/// ProviderScope.overrides 替换为真实实现。
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return StubNotificationService();
});

/// 语音服务 Provider
///
/// 默认注入 [StubVoiceService]，F-10（core/voice）通过
/// ProviderScope.overrides 替换为真实实现。
final voiceServiceProvider = Provider<VoiceService>((ref) {
  return StubVoiceService();
});
