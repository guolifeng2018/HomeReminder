/// 模型下载 Riverpod Provider
///
/// 提供下载服务和各模型进度的 Provider。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'model_registry.dart';
import 'model_download_service.dart';
import 'download_state.dart';

/// 下载服务单例 Provider
///
/// 维护全局唯一的 ModelDownloadService 实例。
final downloadServiceProvider = Provider<ModelDownloadService>((ref) {
  final service = ModelDownloadService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

/// 单个模型的下载进度 StreamProvider
///
/// 按 modelId 返回 DownloadProgress 流。
/// 使用方式：`ref.watch(modelDownloadProgressProvider('sensevoice-tiny-v1'))`
final modelDownloadProgressProvider =
    StreamProvider.family<DownloadProgress, String>((ref, modelId) {
  final service = ref.watch(downloadServiceProvider);
  return service.progressStream.where((p) => p.modelId == modelId);
});

/// 所有模型进度的 StreamProvider
///
/// 返回全部模型的 DownloadProgress Map。
/// 每次任一模型进度变更时自动推送全量快照。
final allModelsProgressProvider =
    StreamProvider<Map<String, DownloadProgress>>((ref) {
  final service = ref.watch(downloadServiceProvider);
  return service.progressStream.map((_) => service.allProgress);
});

/// 模型列表 Provider（静态数据）
final modelListProvider = Provider<List<DownloadableModel>>((ref) {
  return ModelRegistry.models;
});