/// 权限管理抽象接口
///
/// 定义权限类型、状态枚举和抽象权限管理器。
/// 不包含任何平台原生实现，具体实现见 F-10 (Android) / F-11 (iOS)。
library;

/// 权限类型枚举
enum PermissionType {
  /// 麦克风权限（用于语音输入）
  microphone,

  /// 通知权限（用于提醒推送）
  notification,

  /// 存储权限（用于模型文件下载和缓存）
  storage;
}

/// 权限状态枚举
enum PermissionStatus {
  /// 已授权
  granted,

  /// 已拒绝（可再次请求）
  denied,

  /// 永久拒绝（需引导用户前往系统设置）
  permanentlyDenied,

  /// 受限（如家长控制等系统级限制）
  restricted,

  /// 未知状态（尚未请求或无法确定）
  unknown;

  /// 是否已授权
  bool get isGranted => this == PermissionStatus.granted;

  /// 是否需要引导用户前往系统设置
  bool get shouldOpenSettings =>
      this == PermissionStatus.permanentlyDenied ||
      this == PermissionStatus.restricted;
}

/// 权限管理器抽象类
///
/// 各平台（Android / iOS）实现自己的子类，
/// 通过 Method Channel 调用原生权限 API。
abstract class PermissionManager {
  /// 检查指定权限的当前状态
  Future<PermissionStatus> checkPermission(PermissionType type);

  /// 请求指定权限
  ///
  /// 返回请求后的权限状态。
  Future<PermissionStatus> requestPermission(PermissionType type);

  /// 打开系统应用设置页面
  ///
  /// 返回 `true` 表示成功跳转。
  Future<bool> openSettings();
}
