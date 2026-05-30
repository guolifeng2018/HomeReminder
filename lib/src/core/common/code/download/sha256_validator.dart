/// SHA256 校验器
///
/// 计算文件 SHA256 并与预期值比对。
/// 校验失败时删除文件，支持重试。
library;

import 'dart:io';

import 'package:crypto/crypto.dart';

/// SHA256 校验结果
class Sha256Result {
  final bool match;
  final String? actualHash;
  final String? expectedHash;

  const Sha256Result({
    required this.match,
    this.actualHash,
    this.expectedHash,
  });
}

/// SHA256 校验器
class Sha256Validator {
  /// 最大重试次数
  static const int maxRetries = 3;

  /// 校验文件 SHA256
  ///
  /// 返回 [Sha256Result]。
  /// 校验不匹配时删除文件。
  static Future<Sha256Result> validate({
    required String filePath,
    required String expectedSha256,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return const Sha256Result(match: false, actualHash: null);
    }

    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    final actualHash = digest.toString();

    final match = actualHash == expectedSha256.toLowerCase();

    if (!match) {
      // 删除校验失败的文件
      await file.delete();
    }

    return Sha256Result(
      match: match,
      actualHash: actualHash,
      expectedHash: expectedSha256,
    );
  }

  /// 带重试的校验（与下载协同使用）
  ///
  /// [onRetryNeeded] 回调在每次需要重试时调用（用于触发重新下载）。
  /// 返回 true 表示校验最终通过，false 表示 maxRetries 次全部失败。
  static Future<bool> validateWithRetry({
    required String filePath,
    required String expectedSha256,
    required Future<bool> Function(int attempt) onRetryNeeded,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final result = await validate(
        filePath: filePath,
        expectedSha256: expectedSha256,
      );

      if (result.match) {
        return true;
      }

      // 最后一次尝试失败则不再重试
      if (attempt < maxRetries) {
        final shouldContinue = await onRetryNeeded(attempt);
        if (!shouldContinue) {
          return false;
        }
      }
    }

    return false;
  }
}
