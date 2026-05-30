/// 通知点击负载处理器
///
/// 负责通知点击 payload 的序列化与反序列化。
/// payload 格式为 JSON：`{"reminder_id": <int>}`
library;

import 'dart:convert';

/// 通知 payload 处理器
///
/// 纯静态工具类，无状态，仅在通知调度和点击回调中使用。
class NotificationPayloadHandler {
  /// 将 reminderId 编码为 JSON payload 字符串
  ///
  /// 示例：`encodePayload(42)` → `'{"reminder_id":42}'`
  static String encodePayload(int reminderId) {
    return '{"reminder_id":$reminderId}';
  }

  /// 从 JSON payload 字符串解码 reminderId
  ///
  /// 返回 `null` 的情况：
  /// - [payload] 为 `null`
  /// - [payload] 不是合法 JSON
  /// - JSON 中无 `reminder_id` 键
  /// - `reminder_id` 不是整数类型
  static int? decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;

    try {
      final map = jsonDecode(payload);
      if (map is! Map<String, dynamic>) return null;

      final rawId = map['reminder_id'];
      if (rawId is int) return rawId;
      if (rawId is double) return rawId.toInt();
      if (rawId is String) return int.tryParse(rawId);
      return null;
    } catch (_) {
      return null;
    }
  }
}
