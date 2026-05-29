/// Provider override 测试
///
/// 验证通过 ProviderScope.overrides 可替换 stub 为 mock 实现。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:home_reminder/src/core/providers/code/service_providers.dart';
import 'package:home_reminder/src/core/providers/code/reminder_service.dart';
import 'package:home_reminder/src/core/providers/code/notification_service.dart';
import 'package:home_reminder/src/core/providers/code/voice_service.dart';

/// Mock ReminderService — 记录方法调用而非抛出异常
class MockReminderService implements ReminderService {
  bool scheduleCalled = false;
  bool cancelCalled = false;
  int? lastCancelledId;

  @override
  Future<void> scheduleReminder(dynamic reminder) async {
    scheduleCalled = true;
  }

  @override
  Future<void> cancelReminder(int id) async {
    cancelCalled = true;
    lastCancelledId = id;
  }
}

/// Mock NotificationService — 记录方法调用
class MockNotificationService implements NotificationService {
  bool showCalled = false;
  bool cancelAllCalled = false;
  String? lastTitle;
  String? lastBody;

  @override
  Future<void> showNotification(String title, String body) async {
    showCalled = true;
    lastTitle = title;
    lastBody = body;
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalled = true;
  }
}

/// Mock VoiceService — 记录方法调用
class MockVoiceService implements VoiceService {
  bool listeningStarted = false;
  bool listeningStopped = false;

  @override
  Future<String> startListening() async {
    listeningStarted = true;
    return 'mock transcription';
  }

  @override
  Future<void> stopListening() async {
    listeningStopped = true;
  }
}

void main() {
  group('Provider override', () {
    test('reminderServiceProvider override with mock', () {
      final mock = MockReminderService();
      final container = ProviderContainer(
        overrides: [
          reminderServiceProvider.overrideWith((ref) => mock),
        ],
      );

      final resolved = container.read(reminderServiceProvider);
      expect(resolved, same(mock));
      expect(resolved, isA<MockReminderService>());

      container.dispose();
    });

    test('notificationServiceProvider override with mock', () {
      final mock = MockNotificationService();
      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWith((ref) => mock),
        ],
      );

      final resolved = container.read(notificationServiceProvider);
      expect(resolved, same(mock));

      container.dispose();
    });

    test('voiceServiceProvider override with mock', () {
      final mock = MockVoiceService();
      final container = ProviderContainer(
        overrides: [
          voiceServiceProvider.overrideWith((ref) => mock),
        ],
      );

      final resolved = container.read(voiceServiceProvider);
      expect(resolved, same(mock));

      container.dispose();
    });

    test('mock ReminderService methods can be called', () async {
      final mock = MockReminderService();
      final container = ProviderContainer(
        overrides: [
          reminderServiceProvider.overrideWith((ref) => mock),
        ],
      );

      final service = container.read(reminderServiceProvider);
      await service.scheduleReminder('test');
      await service.cancelReminder(42);

      expect(mock.scheduleCalled, isTrue);
      expect(mock.cancelCalled, isTrue);
      expect(mock.lastCancelledId, equals(42));

      container.dispose();
    });

    test('override is scoped — does not leak to another container', () {
      final mock = MockReminderService();
      final overridden = ProviderContainer(
        overrides: [
          reminderServiceProvider.overrideWith((ref) => mock),
        ],
      );
      final defaultContainer = ProviderContainer();

      expect(
        overridden.read(reminderServiceProvider),
        isA<MockReminderService>(),
      );
      expect(
        defaultContainer.read(reminderServiceProvider),
        isA<StubReminderService>(),
      );

      overridden.dispose();
      defaultContainer.dispose();
    });
  });
}
