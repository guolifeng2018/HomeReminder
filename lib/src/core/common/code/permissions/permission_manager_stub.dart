/// 权限管理器 Stub 实现
///
/// 所有权限检查均返回 [PermissionStatus.granted]。
/// 用于测试环境和尚未实现原生权限的平台。
///
/// STUB — 真实实现见 F-10 (Android) / F-11 (iOS)。
library;

import 'permission_manager.dart';

/// 权限管理器 Stub
///
/// 在未接入原生权限 API 前，默认所有权限已授权，
/// 确保核心业务逻辑可独立测试和运行。
class PermissionManagerStub extends PermissionManager {
  @override
  Future<PermissionStatus> checkPermission(PermissionType type) async {
    return PermissionStatus.granted;
  }

  @override
  Future<PermissionStatus> requestPermission(PermissionType type) async {
    return PermissionStatus.granted;
  }

  @override
  Future<bool> openSettings() async {
    return true;
  }
}
