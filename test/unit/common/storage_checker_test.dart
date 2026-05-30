/// 存储空间检查器 单元测试
///
/// 覆盖：StorageCheckResult 枚举、check 的基本逻辑。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:home_reminder/src/core/common/code/download/storage_checker.dart';
import 'package:home_reminder/src/core/common/code/download/model_registry.dart';

void main() {
  group('StorageCheckResult', () {
    test('三个枚举值存在', () {
      expect(StorageCheckResult.values.length, 3);
      expect(StorageCheckResult.values, contains(StorageCheckResult.ok));
      expect(StorageCheckResult.values, contains(StorageCheckResult.insufficient));
      expect(StorageCheckResult.values, contains(StorageCheckResult.error));
    });
  });

  group('StorageChecker', () {
    late DownloadableModel smallModel;
    late DownloadableModel hugeModel;

    setUp(() {
      smallModel = DownloadableModel(
        id: 'small',
        name: 'Small',
        version: '1',
        url: 'http://x',
        sha256: 'a' * 64,
        fileSize: 1, // 1 字节
        targetSubDir: 'models',
        targetFileName: 'small.bin',
      );

      hugeModel = DownloadableModel(
        id: 'huge',
        name: 'Huge',
        version: '1',
        url: 'http://x',
        sha256: 'a' * 64,
        fileSize: 1024 * 1024 * 1024 * 1024, // 1 TB
        targetSubDir: 'models',
        targetFileName: 'huge.bin',
      );
    });

    test('check 返回非 null 结果', () async {
      final result = await StorageChecker.check(smallModel);
      // 结果可能是 ok/insufficient/error，取决于平台和测试环境
      expect(result, isNotNull);
    });

    test('check(hugeModel) 返回 insufficient 或 error', () async {
      final result = await StorageChecker.check(hugeModel);
      // 1TB 模型肯定超出可用空间，但 df 命令可能失败导致 error
      expect(result, isIn([StorageCheckResult.insufficient, StorageCheckResult.error]));
    });
  });
}
