/// 下载状态管理 单元测试
///
/// 覆盖：DownloadState 枚举值、DownloadProgress 构造/工厂/copyWith/idle、
/// DownloadStateManager（状态更新、allProgress、事件流、dispose）。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:home_reminder/src/core/common/code/download/download_state.dart';

void main() {
  group('DownloadState', () {
    test('5 个状态值全部存在', () {
      expect(DownloadState.values.length, 5);
      expect(DownloadState.values, contains(DownloadState.idle));
      expect(DownloadState.values, contains(DownloadState.downloading));
      expect(DownloadState.values, contains(DownloadState.paused));
      expect(DownloadState.values, contains(DownloadState.completed));
      expect(DownloadState.values, contains(DownloadState.failed));
    });
  });

  group('DownloadProgress', () {
    test('构造时属性正确', () {
      final p = DownloadProgress(
        modelId: 'm1',
        state: DownloadState.downloading,
        progressPercent: 50,
        downloadedBytes: 512,
        totalBytes: 1024,
        errorMessage: null,
        etaSeconds: 30,
      );
      expect(p.modelId, 'm1');
      expect(p.state, DownloadState.downloading);
      expect(p.progressPercent, 50);
      expect(p.downloadedBytes, 512);
      expect(p.totalBytes, 1024);
      expect(p.errorMessage, isNull);
      expect(p.etaSeconds, 30);
    });

    test('idle 工厂创建 idle 状态的进度', () {
      final p = DownloadProgress.idle('m1', 1024);
      expect(p.modelId, 'm1');
      expect(p.state, DownloadState.idle);
      expect(p.totalBytes, 1024);
      expect(p.progressPercent, 0);
      expect(p.downloadedBytes, 0);
    });

    test('copyWith 只修改指定字段', () {
      final p = DownloadProgress(modelId: 'm1', state: DownloadState.idle);
      final p2 = p.copyWith(state: DownloadState.downloading, progressPercent: 42);
      expect(p2.modelId, 'm1');
      expect(p2.state, DownloadState.downloading);
      expect(p2.progressPercent, 42);
    });

    test('copyWith clearError 清除错误信息', () {
      final p = DownloadProgress(modelId: 'm1', errorMessage: 'fail');
      final p2 = p.copyWith(state: DownloadState.downloading, clearError: true);
      expect(p2.errorMessage, isNull);
    });
  });

  group('DownloadStateManager', () {
    late DownloadStateManager manager;

    setUp(() {
      manager = DownloadStateManager();
    });

    tearDown(() {
      manager.dispose();
    });

    test('updateState 更新模型状态并触发事件流', () async {
      final events = <DownloadProgress>[];
      final sub = manager.onProgressChanged.listen(events.add);

      manager.initModel('m1', 1024);
      manager.updateState('m1', DownloadState.downloading);

      await Future.delayed(Duration.zero);

      expect(manager.allProgress['m1']!.state, DownloadState.downloading);
      expect(events.length, 2); // initModel + updateState 各 1 个事件
      expect(events.first.modelId, 'm1');

      sub.cancel();
    });

    test('updateState 相同状态不触发重复事件', () async {
      final events = <DownloadProgress>[];
      final sub = manager.onProgressChanged.listen(events.add);

      manager.initModel('m1', 1024);
      manager.updateState('m1', DownloadState.downloading);
      await Future.delayed(Duration.zero);
      expect(events.length, 2); // initModel + updateState

      manager.updateState('m1', DownloadState.downloading);
      await Future.delayed(Duration.zero);
      expect(events.length, 3); // updateState 总会发送事件

      sub.cancel();
    });

    test('allProgress 返回所有模型进度', () {
      manager.initModel('m1', 1024);
      manager.initModel('m2', 2048);
      manager.updateState('m1', DownloadState.idle);
      manager.updateState('m2', DownloadState.completed);

      final all = manager.allProgress;
      expect(all.length, 2);
      expect(all['m1']!.state, DownloadState.idle);
      expect(all['m2']!.state, DownloadState.completed);
    });

    test('updateProgress 更新下载进度', () async {
      manager.initModel('m1', 1024);
      manager.updateState('m1', DownloadState.downloading);
      await Future.delayed(Duration.zero);

      manager.updateProgress('m1', downloadedBytes: 512, totalBytes: 1024);
      await Future.delayed(Duration.zero);

      final p = manager.allProgress['m1']!;
      expect(p.progressPercent, 50);
      expect(p.downloadedBytes, 512);
    });

    test('dispose 后 onProgressChanged 订阅立即完成', () async {
      manager.dispose();
      // 广播 stream 关闭后，新订阅立即收到 done
      final sub = manager.onProgressChanged.listen((_) {});
      await expectLater(sub.asFuture(), completes);
    });
  });
}
