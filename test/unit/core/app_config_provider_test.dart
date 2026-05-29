/// AppConfig Provider 单元测试
///
/// 验证默认值、setFirstLaunch 状态切换、setModelDownloadStatus 各状态切换。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:home_reminder/src/core/providers/code/app_config_provider.dart';
import 'package:home_reminder/src/core/providers/code/app_config.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('AppConfig defaults', () {
    test('isFirstLaunch defaults to true', () {
      final config = container.read(appConfigProvider);
      expect(config.isFirstLaunch, isTrue);
    });

    test('modelDownloadStatus defaults to idle', () {
      final config = container.read(appConfigProvider);
      expect(config.modelDownloadStatus, equals(ModelDownloadStatus.idle));
    });
  });

  group('setFirstLaunch', () {
    test('setFirstLaunch(false) updates isFirstLaunch to false', () {
      container.read(appConfigProvider.notifier).setFirstLaunch(false);
      final config = container.read(appConfigProvider);
      expect(config.isFirstLaunch, isFalse);
    });

    test('setFirstLaunch(true) keeps isFirstLaunch true', () {
      container.read(appConfigProvider.notifier).setFirstLaunch(false);
      container.read(appConfigProvider.notifier).setFirstLaunch(true);
      final config = container.read(appConfigProvider);
      expect(config.isFirstLaunch, isTrue);
    });

    test('setFirstLaunch does not affect modelDownloadStatus', () {
      container.read(appConfigProvider.notifier).setFirstLaunch(false);
      final config = container.read(appConfigProvider);
      expect(config.modelDownloadStatus, equals(ModelDownloadStatus.idle));
    });
  });

  group('setModelDownloadStatus', () {
    test('setModelDownloadStatus(downloading) updates status', () {
      container
          .read(appConfigProvider.notifier)
          .setModelDownloadStatus(ModelDownloadStatus.downloading);
      final config = container.read(appConfigProvider);
      expect(
          config.modelDownloadStatus, equals(ModelDownloadStatus.downloading));
    });

    test('setModelDownloadStatus(completed) updates status', () {
      container
          .read(appConfigProvider.notifier)
          .setModelDownloadStatus(ModelDownloadStatus.completed);
      final config = container.read(appConfigProvider);
      expect(
          config.modelDownloadStatus, equals(ModelDownloadStatus.completed));
    });

    test('setModelDownloadStatus(failed) updates status', () {
      container
          .read(appConfigProvider.notifier)
          .setModelDownloadStatus(ModelDownloadStatus.failed);
      final config = container.read(appConfigProvider);
      expect(config.modelDownloadStatus, equals(ModelDownloadStatus.failed));
    });

    test('full status lifecycle: idle → downloading → completed', () {
      final notifier = container.read(appConfigProvider.notifier);
      expect(
        container.read(appConfigProvider).modelDownloadStatus,
        equals(ModelDownloadStatus.idle),
      );

      notifier.setModelDownloadStatus(ModelDownloadStatus.downloading);
      expect(
        container.read(appConfigProvider).modelDownloadStatus,
        equals(ModelDownloadStatus.downloading),
      );

      notifier.setModelDownloadStatus(ModelDownloadStatus.completed);
      expect(
        container.read(appConfigProvider).modelDownloadStatus,
        equals(ModelDownloadStatus.completed),
      );
    });

    test('full status lifecycle: idle → downloading → failed', () {
      final notifier = container.read(appConfigProvider.notifier);
      expect(
        container.read(appConfigProvider).modelDownloadStatus,
        equals(ModelDownloadStatus.idle),
      );

      notifier.setModelDownloadStatus(ModelDownloadStatus.downloading);
      notifier.setModelDownloadStatus(ModelDownloadStatus.failed);
      expect(
        container.read(appConfigProvider).modelDownloadStatus,
        equals(ModelDownloadStatus.failed),
      );
    });

    test('setModelDownloadStatus does not affect isFirstLaunch', () {
      container
          .read(appConfigProvider.notifier)
          .setModelDownloadStatus(ModelDownloadStatus.completed);
      final config = container.read(appConfigProvider);
      expect(config.isFirstLaunch, isTrue);
    });
  });

  group('AppConfig copyWith', () {
    test('copyWith preserves unmodified fields', () {
      final original = const AppConfig();
      final modified = original.copyWith(isFirstLaunch: false);
      expect(modified.isFirstLaunch, isFalse);
      expect(
          modified.modelDownloadStatus, equals(ModelDownloadStatus.idle));
    });

    test('copyWith creates new instance', () {
      final original = const AppConfig();
      final modified = original.copyWith(isFirstLaunch: false);
      expect(identical(original, modified), isFalse);
    });
  });
}
