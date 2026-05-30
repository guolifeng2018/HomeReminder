/// 断点续传下载器
///
/// 使用 dart:io HttpClient 实现 HTTP Range 下载，
/// 支持暂停/继续/取消，进度通过 Stream 推送。
library;

import 'dart:async';
import 'dart:io';

import 'model_registry.dart';

/// 下载进度事件
class DownloadProgressEvent {
  final String modelId;
  final int downloadedBytes;
  final int totalBytes;
  final double progress; // 0.0 ~ 1.0
  final DownloadEventType type;

  const DownloadProgressEvent({
    required this.modelId,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.progress,
    required this.type,
  });
}

/// 下载事件类型
enum DownloadEventType {
  started,
  progress,
  completed,
  paused,
  cancelled,
  error,
}

/// 下载器异常
class DownloadException implements Exception {
  final String message;
  final int? statusCode;
  final String? detail;

  const DownloadException(this.message, {this.statusCode, this.detail});

  @override
  String toString() =>
      'DownloadException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}${detail != null ? ' - $detail' : ''}';
}

/// 断点续传下载器
class Downloader {
  HttpClient? _client;
  bool _isPaused = false;
  bool _isCancelled = false;
  int _downloadedBytes = 0;

  /// 开始下载（自动检测断点）
  ///
  /// 如果 .part 文件已存在，从已有字节数 offset 继续下载。
  Stream<DownloadProgressEvent> startDownload(DownloadableModel model) async* {
    _isPaused = false;
    _isCancelled = false;

    try {
      _client = HttpClient();
      _client!.connectionTimeout = const Duration(seconds: 30);

      // 检查断点
      _downloadedBytes = 0;
      final partPath = await model.partPath;
      final partFile = File(partPath);
      if (await partFile.exists()) {
        _downloadedBytes = await partFile.length();
      }

      // 确保目标目录存在
      final targetDir = await model.targetDir;
      await Directory(targetDir).create(recursive: true);

      // 发起 HTTP Range 请求
      final uri = Uri.parse(model.url);
      final request = await _client!.getUrl(uri);

      if (_downloadedBytes > 0) {
        request.headers.set(
          HttpHeaders.rangeHeader,
          'bytes=$_downloadedBytes-',
        );
      }

      final response = await request.close();

      // 检查响应状态
      final statusCode = response.statusCode;
      if (statusCode != 200 && statusCode != 206) {
        throw DownloadException(
          '服务器返回异常状态',
          statusCode: statusCode,
        );
      }

      // 确定总大小
      final totalBytes = _downloadedBytes +
          (response.headers.contentLength > 0
              ? response.headers.contentLength
              : model.fileSize);

      yield DownloadProgressEvent(
        modelId: model.id,
        downloadedBytes: _downloadedBytes,
        totalBytes: totalBytes,
        progress: totalBytes > 0 ? _downloadedBytes / totalBytes : 0,
        type: DownloadEventType.started,
      );

      // 追加写入 .part 文件
      final sink = partFile.openWrite(mode: FileMode.append);

      await for (final chunk in response) {
        if (_isCancelled) break;

        while (_isPaused && !_isCancelled) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        if (_isCancelled) break;

        sink.add(chunk);
        _downloadedBytes += chunk.length;

        yield DownloadProgressEvent(
          modelId: model.id,
          downloadedBytes: _downloadedBytes,
          totalBytes: totalBytes,
          progress: totalBytes > 0 ? _downloadedBytes / totalBytes : 0,
          type: DownloadEventType.progress,
        );
      }

      await sink.close();

      if (_isCancelled) {
        yield DownloadProgressEvent(
          modelId: model.id,
          downloadedBytes: _downloadedBytes,
          totalBytes: totalBytes,
          progress: totalBytes > 0 ? _downloadedBytes / totalBytes : 0,
          type: DownloadEventType.cancelled,
        );
        return;
      }

      // 下载完成，重命名 .part → 目标文件
      final targetPath = await model.targetPath;
      await partFile.rename(targetPath);

      yield DownloadProgressEvent(
        modelId: model.id,
        downloadedBytes: _downloadedBytes,
        totalBytes: totalBytes,
        progress: 1.0,
        type: DownloadEventType.completed,
      );
    } on DownloadException {
      rethrow;
    } catch (e) {
      yield DownloadProgressEvent(
        modelId: model.id,
        downloadedBytes: _downloadedBytes,
        totalBytes: model.fileSize,
        progress: model.fileSize > 0 ? _downloadedBytes / model.fileSize : 0,
        type: DownloadEventType.error,
      );
      throw DownloadException('下载失败: $e');
    } finally {
      _client?.close();
      _client = null;
    }
  }

  /// 暂停下载
  void pause() {
    _isPaused = true;
  }

  /// 继续下载（通过重新调用 startDownload 实现）
  void resume() {
    _isPaused = false;
  }

  /// 取消下载（清理 .part 文件）
  void cancel() {
    _isCancelled = true;
    _isPaused = false;
  }

  /// 取消并清理指定模型的 .part 文件
  Future<void> cancelAndCleanup(DownloadableModel model) async {
    cancel();
    final partPath = await model.partPath;
    final partFile = File(partPath);
    if (await partFile.exists()) {
      await partFile.delete();
    }
  }

  /// 资源释放
  void dispose() {
    _client?.close();
    _client = null;
  }
}