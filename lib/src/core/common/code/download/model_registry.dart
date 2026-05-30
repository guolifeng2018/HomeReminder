/// 模型注册表
///
/// 定义可下载模型元数据和注册表。
/// 所有模型 URL 和校验值集中管理，便于运维替换。
library;

import 'package:path_provider/path_provider.dart';

/// 可下载模型元数据
class DownloadableModel {
  /// 唯一标识（如 "sensevoice-tiny-v1"）
  final String id;

  /// 显示名称
  final String name;

  /// 版本号
  final String version;

  /// 下载 URL
  final String url;

  /// 期望的 SHA256 十六进制字符串
  final String sha256;

  /// 文件大小（字节）
  final int fileSize;

  /// 目标子目录（相对于应用文档目录）
  final String targetSubDir;

  /// 目标文件名
  final String targetFileName;

  const DownloadableModel({
    required this.id,
    required this.name,
    required this.version,
    required this.url,
    required this.sha256,
    required this.fileSize,
    required this.targetSubDir,
    required this.targetFileName,
  });

  /// 完整目标路径（需要异步获取应用文档目录）
  Future<String> get targetPath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$targetSubDir/$targetFileName';
  }

  /// .part 临时文件路径
  Future<String> get partPath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$targetSubDir/$targetFileName.part';
  }

  /// 目标目录路径
  Future<String> get targetDir async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$targetSubDir';
  }

  /// 格式化文件大小显示
  String get formattedSize {
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(0)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(0)} MB';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadableModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 模型注册表
///
/// 集中管理所有可下载模型的元数据。
class ModelRegistry {
  ModelRegistry._();

  /// SenseVoice-Tiny ONNX 语音识别模型（75MB）
  static final senseVoiceTiny = DownloadableModel(
    id: 'sensevoice-tiny-v1',
    name: '语音识别模型',
    version: '1.0',
    url: 'https://models.example.com/sensevoice_tiny_v1.onnx',
    sha256:
        '0000000000000000000000000000000000000000000000000000000000000000', // 占位，运维替换
    fileSize: 75 * 1024 * 1024, // 75 MB
    targetSubDir: 'models',
    targetFileName: 'sensevoice_tiny_v1.onnx',
  );

  /// Qwen-140M GGUF 语义解析模型（105MB）
  static final qwen140M = DownloadableModel(
    id: 'qwen-140m-v1',
    name: '语义解析模型',
    version: '1.0',
    url: 'https://models.example.com/qwen_140m_q4.gguf',
    sha256:
        '0000000000000000000000000000000000000000000000000000000000000000', // 占位，运维替换
    fileSize: 105 * 1024 * 1024, // 105 MB
    targetSubDir: 'models',
    targetFileName: 'qwen_140m_q4.gguf',
  );

  /// 所有注册模型
  static final List<DownloadableModel> models = [
    senseVoiceTiny,
    qwen140M,
  ];

  /// 按 ID 查找模型
  static DownloadableModel? getById(String id) {
    try {
      return models.firstWhere((m) => m.id == id);
    } on StateError {
      return null;
    }
  }
}
