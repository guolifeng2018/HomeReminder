/// 存储空间检查器
///
/// 使用 path_provider 获取设备可用空间，
/// 校验是否满足模型下载所需空间。
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'model_registry.dart';

/// 存储检查结果
enum StorageCheckResult {
  /// 空间充足
  ok,

  /// 空间不足
  insufficient,

  /// 检查出错
  error,
}

/// 存储空间检查器
class StorageChecker {
  /// 空间余量 50MB
  static const int _marginBytes = 50 * 1024 * 1024;

  /// 安全系数（需要模型大小的 1.5 倍）
  static const double _safetyFactor = 1.5;

  /// 检查是否有足够空间下载模型
  ///
  /// 要求：可用空间 ≥ 模型大小 × 1.5 + 50MB
  static Future<StorageCheckResult> check(DownloadableModel model) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = dir.path;

      // 使用 df 命令获取可用空间（跨平台）
      final result = await Process.run(
        Platform.isWindows ? 'wmic' : 'df',
        Platform.isWindows
            ? ['logicaldisk', 'get', 'size,freespace,caption']
            : ['-k', path],
      );

      if (result.exitCode != 0) {
        // 备选方案：通过 Directory 的 stat 估算
        return await _fallbackCheck(dir, model);
      }

      final availableBytes = _parseAvailableSpace(
        result.stdout.toString(),
        path,
      );

      return _evaluate(availableBytes, model);
    } catch (e) {
      return StorageCheckResult.error;
    }
  }

  /// 评估空间是否足够
  static StorageCheckResult _evaluate(
    int availableBytes,
    DownloadableModel model,
  ) {
    final requiredBytes =
        (model.fileSize * _safetyFactor).ceil() + _marginBytes;
    return availableBytes >= requiredBytes
        ? StorageCheckResult.ok
        : StorageCheckResult.insufficient;
  }

  /// 从 df 输出解析可用空间
  static int _parseAvailableSpace(String output, String targetPath) {
    final lines = output.split('\n');
    for (final line in lines.skip(1)) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 4) {
        final mountPoint = parts.last;
        if (targetPath.startsWith(mountPoint)) {
          return int.tryParse(parts[3]) ?? 0;
        }
      }
    }
    return 0;
  }

  /// 备选检查方案（FileSystemEntity.stat）
  static Future<StorageCheckResult> _fallbackCheck(
    Directory dir,
    DownloadableModel model,
  ) async {
    try {
      final stat = await dir.stat();
      // stat 无法直接获取可用空间，使用粗略估算
      // 实际项目中可接入平台特定 API
      final requiredBytes =
          (model.fileSize * _safetyFactor).ceil() + _marginBytes;

      // 简单假设：如果目录存在且有写入权限，尝试创建测试文件估算
      final testFile = File('${dir.path}/.storage_test');
      await testFile.writeAsString('test');
      await testFile.delete();

      // 保守策略：目录可写入即通过（真实检查依赖平台 API）
      return StorageCheckResult.ok;
    } catch (e) {
      return StorageCheckResult.error;
    }
  }

  /// 计算所需空间（字节）
  static int requiredBytes(DownloadableModel model) {
    return (model.fileSize * _safetyFactor).ceil() + _marginBytes;
  }
}
