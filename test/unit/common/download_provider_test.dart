/// 下载 Provider 单元测试
///
/// 覆盖：downloadServiceProvider、modelDownloadProgressProvider、
/// modelListProvider 的基本行为。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_reminder/src/core/common/code/download/download_providers.dart';

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

    // 确保服务初始化
    container.read(downloadServiceProvider);

    // 等待 stream 首次发射
    await Future.delayed(Duration.zero);

    // 订阅进度
    final asyncProgress =
        container.read(modelDownloadProgressProvider('sensevoice-tiny-v1'));
    expect(asyncProgress, isNotNull);
    // AsyncValue 可能仍在 loading，使用 requireValue 或检查状态
    expect(asyncProgress.hasValue || asyncProgress.isLoading, isTrue);
  });

  test('allModelsProgressProvider 返回非空 Map', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(downloadServiceProvider);

    await Future.delayed(Duration.zero);

    final asyncProgress = container.read(allModelsProgressProvider);
    expect(asyncProgress, isNotNull);
    expect(asyncProgress.hasValue || asyncProgress.isLoading, isTrue);
  });
}
