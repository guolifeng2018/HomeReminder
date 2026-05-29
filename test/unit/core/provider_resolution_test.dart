/// Provider 解析测试
///
/// 验证所有 7 个 Provider 均可在 ProviderContainer 中正常 resolve，
/// 无 ProviderNotFoundException 抛出。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:home_reminder/src/core/providers/code/database_providers.dart';
import 'package:home_reminder/src/core/providers/code/service_providers.dart';
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

  group('Provider resolution', () {
    test('databaseProvider resolves without error', () {
      final db = container.read(databaseProvider);
      expect(db, isNotNull);
    });

    test('groupRepositoryProvider resolves without error', () {
      final repo = container.read(groupRepositoryProvider);
      expect(repo, isNotNull);
    });

    test('reminderRepositoryProvider resolves without error', () {
      final repo = container.read(reminderRepositoryProvider);
      expect(repo, isNotNull);
    });

    test('reminderServiceProvider resolves without error', () {
      final service = container.read(reminderServiceProvider);
      expect(service, isNotNull);
    });

    test('notificationServiceProvider resolves without error', () {
      final service = container.read(notificationServiceProvider);
      expect(service, isNotNull);
    });

    test('voiceServiceProvider resolves without error', () {
      final service = container.read(voiceServiceProvider);
      expect(service, isNotNull);
    });

    test('appConfigProvider resolves without error', () {
      final config = container.read(appConfigProvider);
      expect(config, isNotNull);
    });

    test('all providers resolve without exception', () {
      expect(
        () {
          container.read(databaseProvider);
          container.read(groupRepositoryProvider);
          container.read(reminderRepositoryProvider);
          container.read(reminderServiceProvider);
          container.read(notificationServiceProvider);
          container.read(voiceServiceProvider);
          container.read(appConfigProvider);
        },
        returnsNormally,
      );
    });
  });
}
