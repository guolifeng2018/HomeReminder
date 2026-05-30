/// SHA256 校验器 单元测试
///
/// 覆盖：Sha256Result、Sha256Validator.validate（匹配/不匹配/文件不存在）、
/// validateWithRetry（3 次重试逻辑）。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_reminder/src/core/common/code/download/sha256_validator.dart';

void main() {
  group('Sha256Result', () {
    test('match=true 时属性正确', () {
      final r = Sha256Result(match: true, actualHash: 'abc', expectedHash: 'abc');
      expect(r.match, true);
      expect(r.actualHash, 'abc');
      expect(r.expectedHash, 'abc');
    });

    test('match=false 时属性正确', () {
      final r = Sha256Result(match: false, actualHash: 'xyz');
      expect(r.match, false);
      expect(r.actualHash, 'xyz');
      expect(r.expectedHash, isNull);
    });
  });

  group('Sha256Validator.validate', () {
    late Directory tmpDir;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('sha256_test_');
    });

    tearDown(() {
      tmpDir.deleteSync(recursive: true);
    });

    test('文件不存在返回 match=false', () async {
      final result = await Sha256Validator.validate(
        filePath: '${tmpDir.path}/nonexistent.bin',
        expectedSha256: 'a' * 64,
      );
      expect(result.match, false);
      expect(result.actualHash, isNull);
    });

    test('SHA256 匹配返回 match=true', () async {
      final file = File('${tmpDir.path}/test.bin');
      await file.writeAsString('hello world');

      final result = await Sha256Validator.validate(
        filePath: file.path,
        expectedSha256:
            'b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9',
      );
      expect(result.match, true);
      expect(result.actualHash,
          'b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9');
    });

    test('SHA256 不匹配删除文件', () async {
      final file = File('${tmpDir.path}/test.bin');
      await file.writeAsString('hello world');

      final result = await Sha256Validator.validate(
        filePath: file.path,
        expectedSha256: 'b' * 64,
      );
      expect(result.match, false);
      expect(await file.exists(), false);
    });
  });

  group('Sha256Validator.validateWithRetry', () {
    late Directory tmpDir;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('sha256_retry_');
    });

    tearDown(() {
      tmpDir.deleteSync(recursive: true);
    });

    test('第一次校验通过直接返回 true', () async {
      final file = File('${tmpDir.path}/test.bin');
      await file.writeAsString('data');

      final passed = await Sha256Validator.validateWithRetry(
        filePath: file.path,
        expectedSha256:
            '3a6eb0790f39ac87c94f3856b2dd2c5d110e6811602261a9a923d3bb23adc8b7',
        onRetryNeeded: (_) async => false,
      );
      expect(passed, true);
    });

    test('maxRetries 次全部失败返回 false', () async {
      final file = File('${tmpDir.path}/test.bin');
      await file.writeAsString('wrong data');

      int retryCount = 0;
      final passed = await Sha256Validator.validateWithRetry(
        filePath: file.path,
        expectedSha256: 'a' * 64,
        onRetryNeeded: (_) async {
          retryCount++;
          return true; // 继续重试
        },
      );
      expect(passed, false);
      expect(retryCount, 2); // maxRetries=3，第 1 次失败 + 2 次重试
    });
  });
}
