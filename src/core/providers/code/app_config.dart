/// AppConfig 数据模型 + ModelDownloadStatus 枚举
///
/// 定义应用全局配置状态，包括首次启动标记和模型下载状态。
library;

/// 模型下载状态枚举
enum ModelDownloadStatus {
  /// 空闲（未开始下载）
  idle,

  /// 下载中
  downloading,

  /// 下载完成
  completed,

  /// 下载失败
  failed,
}

/// 应用全局配置
///
/// 使用 [copyWith] 创建不可变状态副本，配合 StateNotifier 驱动 UI 更新。
class AppConfig {
  /// 是否首次启动（默认 true）
  final bool isFirstLaunch;

  /// 模型下载状态（默认 idle）
  final ModelDownloadStatus modelDownloadStatus;

  const AppConfig({
    this.isFirstLaunch = true,
    this.modelDownloadStatus = ModelDownloadStatus.idle,
  });

  /// 创建副本（部分字段更新）
  AppConfig copyWith({
    bool? isFirstLaunch,
    ModelDownloadStatus? modelDownloadStatus,
  }) {
    return AppConfig(
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      modelDownloadStatus:
          modelDownloadStatus ?? this.modelDownloadStatus,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppConfig &&
        other.isFirstLaunch == isFirstLaunch &&
        other.modelDownloadStatus == modelDownloadStatus;
  }

  @override
  int get hashCode => Object.hash(isFirstLaunch, modelDownloadStatus);

  @override
  String toString() =>
      'AppConfig(isFirstLaunch: $isFirstLaunch, modelDownloadStatus: $modelDownloadStatus)';
}
