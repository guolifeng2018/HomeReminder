/// 模型下载编排服务
///
/// 协调下载器、校验器、状态管理器，
/// 提供统一的模型下载接口。
library;

import 'dart:async';
import 'dart:io';

import 'model_registry.dart';
import 'downloader.dart';
import 'sha256_validator.dart';
import 'storage_checker.dart';
import 'download_state.dart';

/// 模型下载服务
///
/// 协调所有子组件完成模型下载、校验、状态管理。
class ModelDownloadService {
  final Downloader _downloader = Downloader();
  final DownloadStateManager _stateManager = DownloadStateManager();

  /// 当前下载的模型 ID（串行下载，同时只能有一个）
  String? _activeModelId;

  /// 下载取消器
  Completer<void>? _cancelCompleter;

  /// 状态变更流（供 UI 消费）
  Stream<DownloadProgress> get progressStream => _stateManager.onProgressChanged;

  /// 获取指定模型进度
  DownloadProgress getProgress(String modelId) =>
      _stateManager.getProgress(modelId);

  /// 获取所有模型进度
  Map<String, DownloadProgress> get allProgress => _stateManager.allProgress;

  /// 是否为首次下载（两模型均未完成）
  bool get isFirstTime {
    final all = _stateManager.allProgress;
    if (all.isEmpty) return true;
    return !all.values.any((p) => p.state == DownloadState.completed);
  }

  /// 初始化（注册所有模型）
  void initialize() {
    for (final model in ModelRegistry.models) {
      _stateManager.initModel(model.id, model.fileSize);
    }
  }

  /// 下载指定模型
  ///
  /// 流程：
  /// 1. 检查存储空间
  /// 2. 检查目标文件是否已存在且 SHA256 匹配
  /// 3. 开始下载（带断点续传）
  /// 4. SHA256 校验
  /// 5. 标记完成/失败
  Future<bool> download(String modelId) async {
    final model = ModelRegistry.getById(modelId);
    if (model == null) {
      _stateManager.markFailed(modelId, '未知模型: $modelId');
      return false;
    }

    // 检查是否已在下载
    if (_activeModelId != null && _activeModelId != modelId) {
      _stateManager.markFailed(
          modelId, '另一个模型正在下载中: $_activeModelId');
      return false;
    }

    _activeModelId = modelId;
    _cancelCompleter = Completer<void>();

    try {
      // 1. 存储空间检查
      _stateManager.updateState(modelId, DownloadState.downloading);
      final storageResult = await StorageChecker.check(model);
      if (storageResult == StorageCheckResult.insufficient) {
        _stateManager.markFailed(
          modelId,
          '存储空间不足，需要至少 ${StorageChecker.requiredBytes(model) ~/ (1024 * 1024)}MB',
        );
        return false;
      }
      if (storageResult == StorageCheckResult.error) {
        _stateManager.markFailed(modelId, '存储空间检查失败');
        return false;
      }

      // 2. 检查文件是否已存在且校验通过
      final targetPath = await model.targetPath;
      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        final shaResult = await Sha256Validator.validate(
          filePath: targetPath,
          expectedSha256: model.sha256,
        );
        if (shaResult.match) {
          _stateManager.markCompleted(modelId);
          return true;
        }
        // SHA256 不匹配，文件已被删除，继续下载
      }

      // 3. 下载（带重试）
      bool success = false;
      for (int attempt = 1; attempt <= 3 && !success; attempt++) {
        if (_cancelCompleter!.isCompleted) break;

        try {
          await for (final event
              in _downloader.startDownload(model)) {
            if (_cancelCompleter!.isCompleted) {
              _downloader.cancel();
              break;
            }

            switch (event.type) {
              case DownloadEventType.started:
                _stateManager.updateState(modelId, DownloadState.downloading);
                break;
              case DownloadEventType.progress:
                _stateManager.updateProgress(
                  modelId,
                  downloadedBytes: event.downloadedBytes,
                  totalBytes: event.totalBytes,
                );
                break;
              case DownloadEventType.completed:
                // 4. SHA256 校验
                final shaResult = await Sha256Validator.validate(
                  filePath: targetPath,
                  expectedSha256: model.sha256,
                );
                if (shaResult.match) {
                  _stateManager.markCompleted(modelId);
                  success = true;
                } else {
                  if (attempt < 3) {
                    // 校验失败，重试下载
                    _stateManager.updateState(
                        modelId, DownloadState.downloading);
                  } else {
                    _stateManager.markFailed(
                      modelId,
                      'SHA256 校验失败（已重试 $attempt 次）',
                    );
                  }
                }
                break;
              case DownloadEventType.cancelled:
                _stateManager.updateState(modelId, DownloadState.paused);
                break;
              case DownloadEventType.error:
                _stateManager.markFailed(modelId, '下载出错');
                break;
              case DownloadEventType.paused:
                _stateManager.updateState(modelId, DownloadState.paused);
                break;
            }
          }
        } on DownloadException catch (e) {
          if (attempt >= 3) {
            _stateManager.markFailed(modelId, e.toString());
          }
        }
      }

      return success;
    } catch (e) {
      _stateManager.markFailed(modelId, '未知错误: $e');
      return false;
    } finally {
      _activeModelId = null;
      _cancelCompleter = null;
    }
  }

  /// 暂停下载
  void pause(String modelId) {
    if (_activeModelId == modelId) {
      _downloader.pause();
      _stateManager.updateState(modelId, DownloadState.paused);
    }
  }

  /// 继续下载
  void resume(String modelId) {
    if (_activeModelId == modelId) {
      _downloader.resume();
    }
  }

  /// 取消下载（清理 .part 文件）
  Future<void> cancel(String modelId) async {
    if (_activeModelId == modelId) {
      _cancelCompleter?.complete();
      final model = ModelRegistry.getById(modelId);
      if (model != null) {
        await _downloader.cancelAndCleanup(model);
      }
      _stateManager.updateState(modelId, DownloadState.idle);
    }
  }

  /// 删除已下载的模型文件
  Future<bool> deleteModel(String modelId) async {
    final model = ModelRegistry.getById(modelId);
    if (model == null) return false;

    final targetPath = await model.targetPath;
    final file = File(targetPath);
    if (await file.exists()) {
      await file.delete();
    }

    // 也清理可能的 .part 文件
    final partPath = await model.partPath;
    final partFile = File(partPath);
    if (await partFile.exists()) {
      await partFile.delete();
    }

    _stateManager.initModel(modelId, model.fileSize);
    return true;
  }

  /// 资源释放
  void dispose() {
    _downloader.dispose();
    _stateManager.dispose();
  }
}
