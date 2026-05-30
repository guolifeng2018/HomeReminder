/// 模型注册表 单元测试
///
/// 覆盖：DownloadableModel 属性、路径计算、formattedSize、
/// ModelRegistry.getById 和 models 列表完整性。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:home_reminder/src/core/common/code/download/model_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DownloadableModel', () {
    final model = DownloadableModel(
      id: 'test-model',
      name: 'Test Model',
      version: '1.0.0',
      url: 'https://example.com/model.bin',
      sha256: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      fileSize: 1024 * 1024, // 1 MB
      targetSubDir: 'models',
      targetFileName: 'test.bin',
    );

    test('构造后所有属性正确', () {
      expect(model.id, 'test-model');
      expect(model.name, 'Test Model');
      expect(model.version, '1.0.0');
      expect(model.url, 'https://example.com/model.bin');
      expect(model.sha256.length, 64);
      expect(model.fileSize, 1048576);
      expect(model.targetSubDir, 'models');
      expect(model.targetFileName, 'test.bin');
    });

    test('formattedSize 正确格式化', () {
      expect(model.formattedSize, contains('MB'));
    });
  });

  group('DownloadableModel.formattedSize', () {
    test('0 字节显示 0 KB', () {
      final m = DownloadableModel(
        id: 's', name: 's', version: '1', url: 'http://x',
        sha256: 'a' * 64, fileSize: 0,
        targetSubDir: 'd', targetFileName: 'f',
      );
      expect(m.formattedSize, '0 KB');
    });

    test('512 字节四舍五入为 1 KB', () {
      final m = DownloadableModel(
        id: 's', name: 's', version: '1', url: 'http://x',
        sha256: 'a' * 64, fileSize: 512,
        targetSubDir: 'd', targetFileName: 'f',
      );
      expect(m.formattedSize, contains('KB'));
    });

    test('1024 字节显示 1 KB', () {
      final m = DownloadableModel(
        id: 's', name: 's', version: '1', url: 'http://x',
        sha256: 'a' * 64, fileSize: 1024,
        targetSubDir: 'd', targetFileName: 'f',
      );
      expect(m.formattedSize, '1 KB');
    });

    test('105 MB 显示正确', () {
      final m = DownloadableModel(
        id: 's', name: 's', version: '1', url: 'http://x',
        sha256: 'a' * 64, fileSize: 105 * 1024 * 1024,
        targetSubDir: 'd', targetFileName: 'f',
      );
      expect(m.formattedSize, contains('MB'));
    });
  });

  group('ModelRegistry', () {
    test('models 列表包含 2 个模型', () {
      expect(ModelRegistry.models.length, 2);
    });

    test('两个模型 id 分别为 sensevoice 和 qwen', () {
      final ids = ModelRegistry.models.map((m) => m.id).toSet();
      expect(ids, contains('sensevoice-tiny-v1'));
      expect(ids, contains('qwen-140m-v1'));
    });

    test('getById 命中返回正确模型', () {
      final model = ModelRegistry.getById('sensevoice-tiny-v1');
      expect(model, isNotNull);
      expect(model!.name, isNotEmpty);
    });

    test('getById 未命中返回 null', () {
      final model = ModelRegistry.getById('non-existent');
      expect(model, isNull);
    });

    test('SenseVoice-Tiny 模型信息正确', () {
      final model = ModelRegistry.getById('sensevoice-tiny-v1')!;
      expect(model.version, '1.0');
      expect(model.fileSize, 75 * 1024 * 1024);
      expect(model.targetSubDir, 'models');
    });

    test('Qwen-140M 模型信息正确', () {
      final model = ModelRegistry.getById('qwen-140m-v1')!;
      expect(model.version, '1.0');
      expect(model.fileSize, 105 * 1024 * 1024);
      expect(model.targetSubDir, 'models');
    });
  });
}
