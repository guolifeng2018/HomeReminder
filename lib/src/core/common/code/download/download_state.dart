/// 下载状态管理
///
/// 定义下载状态枚举、进度数据类和状态管理器。
library;

import 'dart:async';

/// 下载状态
enum DownloadState {
  /// 空闲（未开始）
  idle,

  /// 下载中
  downloading,

  /// 已暂停
  paused,

  /// 已完成
  completed,

  /// 失败
  failed,
}

/// 下载进度
class DownloadProgress {
  /// 模型 ID
  final String modelId;

  /// 当前状态
  final DownloadState state;

  /// 进度百分比 0 ~ 100
  final int progressPercent;

  /// 已下载字节数
  final int downloadedBytes;

  /// 总字节数
  final int totalBytes;

  /// 错误信息（仅 failed 状态有意义）
  final String? errorMessage;

  /// 预计剩余时间（秒），null 表示无法估算
  final int? etaSeconds;

  const DownloadProgress({
    required this.modelId,
    this.state = DownloadState.idle,
    this.progressPercent = 0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
    this.etaSeconds,
  });

  /// 创建初始进度
  factory DownloadProgress.idle(String modelId, int totalBytes) {
    return DownloadProgress(
      modelId: modelId,
      state: DownloadState.idle,
      totalBytes: totalBytes,
    );
  }

  /// 复制并修改
  DownloadProgress copyWith({
    DownloadState? state,
    int? progressPercent,
    int? downloadedBytes,
    int? totalBytes,
    String? errorMessage,
    int? etaSeconds,
    bool clearError = false,
  }) {
    return DownloadProgress(
      modelId: modelId,
      state: state ?? this.state,
      progressPercent: progressPercent ?? this.progressPercent,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
      etaSeconds: etaSeconds ?? this.etaSeconds,
    );
  }

  /// 格式化已下载/总大小（人类可读）
  String get formattedSize {
    final d = _formatBytes(downloadedBytes);
    final t = _formatBytes(totalBytes);
    return '$d / $t';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() =>
      'DownloadProgress($modelId, $state, $progressPercent%, $formattedSize)';
}

/// 下载状态管理器
///
/// 管理所有模型的下载状态，通过 Stream 推送变更。
class DownloadStateManager {
  final Map<String, DownloadProgress> _progressMap = {};

  final StreamController<DownloadProgress> _controller =
      StreamController<DownloadProgress>.broadcast();

  /// 状态变更流
  Stream<DownloadProgress> get onProgressChanged => _controller.stream;

  /// 获取指定模型进度
  DownloadProgress getProgress(String modelId) {
    return _progressMap[modelId] ?? DownloadProgress.idle(modelId, 0);
  }

  /// 获取所有模型进度
  Map<String, DownloadProgress> get allProgress =>
      Map.unmodifiable(_progressMap);

  /// 初始化模型进度
  void initModel(String modelId, int totalBytes) {
    _progressMap[modelId] = DownloadProgress.idle(modelId, totalBytes);
    _controller.add(_progressMap[modelId]!);
  }

  /// 更新状态
  void updateState(String modelId, DownloadState state) {
    final current = _progressMap[modelId];
    if (current != null) {
      _progressMap[modelId] = current.copyWith(state: state);
      _controller.add(_progressMap[modelId]!);
    }
  }

  /// 更新进度
  void updateProgress(
    String modelId, {
    required int downloadedBytes,
    required int totalBytes,
  }) {
    final progress =
        totalBytes > 0 ? ((downloadedBytes / totalBytes) * 100).round() : 0;
    _progressMap[modelId] = DownloadProgress(
      modelId: modelId,
      state: DownloadState.downloading,
      progressPercent: progress,
      downloadedBytes: downloadedBytes,
      totalBytes: totalBytes,
    );
    _controller.add(_progressMap[modelId]!);
  }

  /// 标记失败
  void markFailed(String modelId, String error) {
    final current = _progressMap[modelId];
    if (current != null) {
      _progressMap[modelId] = current.copyWith(
        state: DownloadState.failed,
        errorMessage: error,
      );
    } else {
      _progressMap[modelId] = DownloadProgress(
        modelId: modelId,
        state: DownloadState.failed,
        errorMessage: error,
      );
    }
    _controller.add(_progressMap[modelId]!);
  }

  /// 标记完成
  void markCompleted(String modelId) {
    final current = _progressMap[modelId];
    if (current != null) {
      _progressMap[modelId] = current.copyWith(
        state: DownloadState.completed,
        progressPercent: 100,
        downloadedBytes: current.totalBytes,
      );
    }
    _controller.add(_progressMap[modelId]!);
  }

  /// 资源释放
  void dispose() {
    _controller.close();
  }
}
