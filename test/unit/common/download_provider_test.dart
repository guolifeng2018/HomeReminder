/// 下载 Provider 单元测试
///
/// 覆盖：downloadServiceProvider、modelDownloadProgressProvider、
/// modelListProvider 的基本行为。
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_reminder/src/core/common/code/download/download_providers.dart';
import 'package:home_reminder/src/core/common/code/download/download_state.dart';

void main() {
  test('downloadServiceProvider 可解析', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final service = container.read(downloadServiceProvider);
    expect(service, isNotNull);
  });

  test('modelListProvider 返回 2 个模型', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final models = container.read(modelListProvider);
    expect(models.length, 2);
  });

  test('modelDownloadProgressProvider 返回非空进度', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 先订阅再触发事件，确保 stream 事件被捕获
    final completer = Completer<DownloadProgress>();
    final sub = container.listen(
      modelDownloadProgressProvider('sensevoice-tiny-v1'),
      (prev, next) {
        if (next.hasValue && !completer.isCompleted) {
          completer.complete(next.value);
        }
      },
    );

    // 重新触发 initialize 以向已激活的 stream 订阅者推送事件
    final service = container.read(downloadServiceProvider);
    service.initialize();

    final progress = await completer.future;
    sub.close();

    expect(progress, isNotNull);
    expect(progress.modelId, 'sensevoice-tiny-v1');
    expect(progress.state, DownloadState.idle);
  });

  test('allModelsProgressProvider 返回非空 Map', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 先订阅再触发事件
    final completer = Completer<Map<String, DownloadProgress>>();
    final sub = container.listen(
      allModelsProgressProvider,
      (prev, next) {
        if (next.hasValue && !completer.isCompleted) {
          completer.complete(next.value);
        }
      },
    );

    // 重新触发 initialize 以推送事件
    final service = container.read(downloadServiceProvider);
    service.initialize();

    final allProgress = await completer.future;
    sub.close();

    expect(allProgress, isNotNull);
    expect(allProgress, isA<Map<String, DownloadProgress>>());
    expect(allProgress.length, 2);
  });
}
