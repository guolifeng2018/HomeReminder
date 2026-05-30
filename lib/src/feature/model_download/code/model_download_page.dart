/// 模型下载管理页
///
/// 展示两个模型卡片的下载状态、进度、操作按钮。
/// 替换原有的占位符页面。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/common/code/download/download_providers.dart';
import '../../../core/common/code/download/model_registry.dart';
import '../../../core/common/code/download/download_state.dart';

/// 模型下载管理页
class ModelDownloadPage extends ConsumerStatefulWidget {
  const ModelDownloadPage({super.key});

  @override
  ConsumerState<ModelDownloadPage> createState() =>
      _ModelDownloadPageState();
}

class _ModelDownloadPageState extends ConsumerState<ModelDownloadPage> {
  @override
  void initState() {
    super.initState();
    // 初始化下载服务
    ref.read(downloadServiceProvider);
  }

  @override
  Widget build(BuildContext context) {
    final models = ref.watch(modelListProvider);
    final service = ref.read(downloadServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('模型下载'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: models.length,
        itemBuilder: (context, index) {
          final model = models[index];
          final progressAsync =
              ref.watch(modelDownloadProgressProvider(model.id));

          return progressAsync.when(
            data: (progress) => _ModelCard(
              model: model,
              progress: progress,
              onDownload: () => service.download(model.id),
              onPause: () => service.pause(model.id),
              onResume: () => service.resume(model.id),
              onCancel: () => service.cancel(model.id),
            ),
            loading: () => _ModelCard(
              model: model,
              progress: DownloadProgress.idle(model.id, model.fileSize),
              onDownload: () => service.download(model.id),
              onPause: () => service.pause(model.id),
              onResume: () => service.resume(model.id),
              onCancel: () => service.cancel(model.id),
            ),
            error: (err, _) => _ModelCard(
              model: model,
              progress: DownloadProgress(
                modelId: model.id,
                state: DownloadState.failed,
                errorMessage: err.toString(),
              ),
              onDownload: () => service.download(model.id),
              onPause: () => service.pause(model.id),
              onResume: () => service.resume(model.id),
              onCancel: () => service.cancel(model.id),
            ),
          );
        },
      ),
    );
  }
}

/// 单个模型卡片
class _ModelCard extends StatelessWidget {
  final DownloadableModel model;
  final DownloadProgress progress;
  final VoidCallback onDownload;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  const _ModelCard({
    required this.model,
    required this.progress,
    required this.onDownload,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 模型名称 + 状态
            Row(
              children: [
                _buildStateIcon(progress.state),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${model.formattedSize} · v${model.version}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 进度条
            if (progress.state == DownloadState.downloading ||
                progress.state == DownloadState.paused) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.progressPercent / 100,
                  minHeight: 8,
                  backgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progress.progressPercent}%',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    progress.formattedSize,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],

            // 错误信息
            if (progress.state == DownloadState.failed &&
                progress.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                progress.errorMessage!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ],

            const SizedBox(height: 12),

            // 操作按钮行
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _buildActions(progress.state),
            ),
          ],
        ),
      ),
    );
  }

  /// 状态图标
  Widget _buildStateIcon(DownloadState state) {
    return switch (state) {
      DownloadState.idle => const Icon(Icons.cloud_download_outlined,
          color: Colors.grey, size: 32),
      DownloadState.downloading => const Icon(Icons.downloading,
          color: Colors.blue, size: 32),
      DownloadState.paused => const Icon(Icons.pause_circle,
          color: Colors.orange, size: 32),
      DownloadState.completed => const Icon(Icons.check_circle,
          color: Colors.green, size: 32),
      DownloadState.failed =>
        const Icon(Icons.error, color: Colors.red, size: 32),
    };
  }

  /// 根据状态构建操作按钮
  List<Widget> _buildActions(DownloadState state) {
    return switch (state) {
      DownloadState.idle => [
          FilledButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('下载'),
          ),
        ],
      DownloadState.downloading => [
          OutlinedButton.icon(
            onPressed: onPause,
            icon: const Icon(Icons.pause, size: 18),
            label: const Text('暂停'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('取消'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      DownloadState.paused => [
          FilledButton.icon(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('继续'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('取消'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      DownloadState.completed => [
          Chip(
            avatar: const Icon(Icons.check, size: 16),
            label: const Text('已完成'),
            backgroundColor: Colors.green.shade50,
          ),
        ],
      DownloadState.failed => [
          OutlinedButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重试'),
          ),
        ],
    };
  }
}
