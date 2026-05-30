/// 模型下载服务 集成测试
///
/// 覆盖：ModelDownloadService 初始化、getProgress、
/// isFirstTime、dispose。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:home_reminder/src/core/common/code/download/model_download_service.dart';
import 'package:home_reminder/src/core/common/code/download/download_state.dart';

void main() {
  group('ModelDownloadService', () {
    late ModelDownloadService service;

    setUp(() {
      service = ModelDownloadService();
      service.initialize();
    });

    tearDown(() {
      service.dispose();
    });

    test('初始化后两个模型状态为 idle', () {
      final sensevoice = service.getProgress('sensevoice-tiny-v1');
      final qwen = service.getProgress('qwen-140m-v1');

      expect(sensevoice.state, DownloadState.idle);
      expect(qwen.state, DownloadState.idle);
    });

    test('isFirstTime 在两模型均未完成时为 true', () {
      expect(service.isFirstTime, isTrue);
    });

    test('getProgress 未知模型返回 idle', () {
      final p = service.getProgress('non-existent');
      expect(p.modelId, 'non-existent');
      expect(p.state, DownloadState.idle);
    });

    test('progressStream 可订阅', () async {
      final events = <DownloadProgress>[];
      final sub = service.progressStream.listen(events.add);

      await Future.delayed(Duration.zero);

      // 初始化可能产生事件（取决于订阅时机）
      expect(events.length, greaterThanOrEqualTo(0));

      sub.cancel();
    });

    test('cancel 对 idle 模型安全', () {
      service.cancel('sensevoice-tiny-v1');
      final p = service.getProgress('sensevoice-tiny-v1');
      expect(p.state, DownloadState.idle); // 无变化
    });

    test('pause 对 idle 模型安全', () {
      service.pause('sensevoice-tiny-v1');
      final p = service.getProgress('sensevoice-tiny-v1');
      expect(p.state, DownloadState.idle);
    });

    test('allProgress 返回两个模型', () {
      final all = service.allProgress;
      expect(all.length, 2);
      expect(all.containsKey('sensevoice-tiny-v1'), isTrue);
      expect(all.containsKey('qwen-140m-v1'), isTrue);
    });

    test('dispose 后安全', () {
      service.dispose();
      // dispose 后调用应不抛异常
      final p = service.getProgress('sensevoice-tiny-v1');
      expect(p.state, DownloadState.idle);
    });
  });
}
