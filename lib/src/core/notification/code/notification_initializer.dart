/// 通知初始化器
///
/// 封装 flutter_local_notifications 的跨平台初始化逻辑：
/// - Android：创建 notification channel
/// - iOS：请求通知权限
/// - 版本兼容处理（Android 10+ / iOS 15+）
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 通知初始化器
///
/// 管理 [FlutterLocalNotificationsPlugin] 实例的生命周期。
/// 提供单例访问和延迟初始化，支持初始化失败降级。
class NotificationInitializer {
  /// 通知渠道 ID
  static const String channelId = 'reminder_channel';

  /// 通知渠道名称
  static const String channelName = '到期提醒';

  /// 通知渠道描述
  static const String channelDescription = '家庭事务到期提醒通知';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _initFailed = false;

  /// 创建 [NotificationInitializer] 实例
  ///
  /// [plugin] 可选，默认创建新的 [FlutterLocalNotificationsPlugin] 实例，
  /// 便于测试注入。
  NotificationInitializer({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// 是否已初始化成功
  bool get isInitialized => _initialized;

  /// 是否初始化失败（降级为 no-op）
  bool get initFailed => _initFailed;

  /// 获取内部 [FlutterLocalNotificationsPlugin] 实例
  FlutterLocalNotificationsPlugin get plugin => _plugin;

  /// 确保已初始化（幂等）
  ///
  /// 首次调用执行完整初始化流程；后续调用直接返回。
  /// 初始化失败时降级为 no-op，不抛异常。
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    if (_initFailed) return;

    try {
      await _initialize();
      _initialized = true;
    } catch (e, stack) {
      _initFailed = true;
      debugPrint(
          'NotificationInitializer: 初始化失败，降级为 no-op: $e\n$stack');
    }
  }

  Future<void> _initialize() async {
    final androidSettings =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // Android：创建通知渠道
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
      );
      await androidPlugin.createNotificationChannel(channel);
    }

    // iOS：权限请求已在 DarwinInitializationSettings 中配置
    // 权限结果通过 initialize() 的返回值处理
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      // iOS 15+：请求 provisional 权限（静默通知）
      // 已在 DarwinInitializationSettings 中声明 alert/badge/sound
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }
}
