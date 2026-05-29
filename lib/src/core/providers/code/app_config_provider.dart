/// AppConfig StateNotifier + Provider
///
/// 提供应用全局配置状态管理，包括首次启动标记和模型下载状态。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';

/// AppConfig 状态管理器
///
/// 提供 [setFirstLaunch] 和 [setModelDownloadStatus] 方法驱动状态变更。
class AppConfigNotifier extends StateNotifier<AppConfig> {
  AppConfigNotifier() : super(const AppConfig());

  /// 设置首次启动标记
  void setFirstLaunch(bool value) {
    state = state.copyWith(isFirstLaunch: value);
  }

  /// 设置模型下载状态
  void setModelDownloadStatus(ModelDownloadStatus status) {
    state = state.copyWith(modelDownloadStatus: status);
  }
}

/// 应用配置 Provider
///
/// 默认值：isFirstLaunch=true, modelDownloadStatus=ModelDownloadStatus.idle
final appConfigProvider =
    StateNotifierProvider<AppConfigNotifier, AppConfig>((ref) {
  return AppConfigNotifier();
});
