/// 下载器 单元测试
///
/// 覆盖：DownloadProgressEvent 构造、DownloadEventType 枚举、
/// DownloadException 构造、Downloader 实例化。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:home_reminder/src/core/common/code/download/downloader.dart';

void main() {
  group('DownloadProgressEvent', () {
    test('构造属性正确', () {
      final event = DownloadProgressEvent(
        modelId: 'm1',
        downloadedBytes: 512,
        totalBytes: 1024,
        progress: 0.5,
        type: DownloadEventType.progress,
      );
      expect(event.modelId, 'm1');
      expect(event.downloadedBytes, 512);
      expect(event.totalBytes, 1024);
      expect(event.progress, 0.5);
      expect(event.type, DownloadEventType.progress);
    });
  });

  group('DownloadEventType', () {
    test('6 个事件类型存在', () {
      expect(DownloadEventType.values.length, 6);
      expect(DownloadEventType.values, contains(DownloadEventType.started));
      expect(DownloadEventType.values, contains(DownloadEventType.progress));
      expect(DownloadEventType.values, contains(DownloadEventType.completed));
      expect(DownloadEventType.values, contains(DownloadEventType.paused));
      expect(DownloadEventType.values, contains(DownloadEventType.cancelled));
      expect(DownloadEventType.values, contains(DownloadEventType.error));
    });
  });

  group('DownloadException', () {
    test('message 正确', () {
      final e = DownloadException('test error');
      expect(e.message, 'test error');
      expect(e.statusCode, isNull);
      expect(e.toString(), contains('test error'));
    });

    test('带 statusCode 正确', () {
      final e = DownloadException('HTTP error', statusCode: 404);
      expect(e.statusCode, 404);
      expect(e.toString(), contains('HTTP 404'));
    });
  });

  group('Downloader', () {
    test('实例化成功', () {
      final downloader = Downloader();
      expect(downloader, isNotNull);
      downloader.dispose();
    });

    test('pause/resume 切换暂停状态', () {
      final downloader = Downloader();
      downloader.pause();
      downloader.resume();
      downloader.dispose();
    });

    test('cancel 后 dispose 正常', () {
      final downloader = Downloader();
      downloader.cancel();
      downloader.dispose();
    });
  });
}
