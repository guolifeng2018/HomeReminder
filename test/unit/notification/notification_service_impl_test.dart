import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_reminder/src/core/common/code/models/enums.dart';
import 'package:home_reminder/src/core/common/code/models/reminder_model.dart';
import 'package:home_reminder/src/core/notification/code/badge_manager.dart';
import 'package:home_reminder/src/core/notification/code/notification_initializer.dart';
import 'package:home_reminder/src/core/notification/code/notification_service_impl.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockBadgeManager extends Mock implements BadgeManager {}

class MockNotificationInitializer extends Mock
    implements NotificationInitializer {}

void main() {
  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late MockBadgeManager mockBadgeManager;
  late MockNotificationInitializer mockInitializer;
  late NotificationServiceImpl service;

  final testReminder = Reminder(
    id: 42,
    groupId: 1,
    title: '擦窗户',
    content: '用湿布擦拭',
    scheduledAt: DateTime(2026, 5, 30, 10, 0),
    status: ReminderStatus.pending,
    frequency: ReminderFrequency.once,
    createdAt: DateTime(2026, 5, 29),
  );

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    mockBadgeManager = MockBadgeManager();
    mockInitializer = MockNotificationInitializer();

    registerFallbackValue(
      const AndroidNotificationDetails('', ''),
    );
    registerFallbackValue(
      DarwinNotificationDetails(),
    );
    registerFallbackValue(
      InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    registerFallbackValue(
      const AndroidNotificationChannel('', ''),
    );
    registerFallbackValue(0);
    registerFallbackValue('');
    registerFallbackValue(const NotificationDetails());

    // Set up mockInitializer to succeed initialization
    when(() => mockInitializer.ensureInitialized())
        .thenAnswer((_) async {});
    when(() => mockInitializer.initFailed).thenReturn(false);
    when(() => mockInitializer.isInitialized).thenReturn(true);

    service = NotificationServiceImpl(
      plugin: mockPlugin,
      initializer: mockInitializer,
      badgeManager: mockBadgeManager,
    );
  });

  group('NotificationServiceImpl', () {
    // Test 1: showNotification with Reminder
    test('should show notification with Reminder and groupName', () async {
      when(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async {});
      when(() => mockBadgeManager.updateBadge(any(), any()))
          .thenAnswer((_) async {});

      await service.show(
        testReminder,
        '客厅',
        pendingCount: 5,
        overdueCount: 3,
      );

      verify(() => mockInitializer.ensureInitialized()).called(1);
      verify(() => mockPlugin.show(
            testReminder.id,
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          )).called(1);
      verify(() => mockBadgeManager.updateBadge(5, 3)).called(1);
    });

    // Test 2: cancelAll
    test('should cancel all notifications and reset badge', () async {
      when(() => mockPlugin.cancelAll()).thenAnswer((_) async {});
      when(() => mockBadgeManager.updateBadge(any(), any()))
          .thenAnswer((_) async {});

      await service.cancelAll();

      verify(() => mockPlugin.cancelAll()).called(1);
      verify(() => mockBadgeManager.updateBadge(0, 0)).called(1);
    });

    // Test 3: cancelReminderNotification
    test('should cancel notification by id', () async {
      when(() => mockPlugin.cancel(42)).thenAnswer((_) async {});

      await service.cancelReminderNotification(42);

      verify(() => mockPlugin.cancel(42)).called(1);
    });

    // Test 4: updateNotification (cancel + re-show)
    test('should cancel then re-show when updating notification', () async {
      when(() => mockPlugin.cancel(any())).thenAnswer((_) async {});
      when(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async {});
      when(() => mockBadgeManager.updateBadge(any(), any()))
          .thenAnswer((_) async {});

      await service.updateNotification(
        testReminder,
        '卧室',
      );

      verify(() => mockPlugin.cancel(testReminder.id)).called(1);
      verify(() => mockPlugin.show(
            testReminder.id,
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          )).called(1);
    });

    // Test 5: showNotification with default badge counts
    test('should update badge with zeros when not specified', () async {
      when(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async {});
      when(() => mockBadgeManager.updateBadge(any(), any()))
          .thenAnswer((_) async {});

      await service.show(testReminder, '客厅');

      verify(() => mockBadgeManager.updateBadge(0, 0)).called(1);
    });

    // Test 6: plugin show error is caught
    test('should not throw when plugin.show fails', () async {
      when(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          )).thenThrow(Exception('show failed'));
      when(() => mockBadgeManager.updateBadge(any(), any()))
          .thenAnswer((_) async {});

      // Should not throw
      await service.show(testReminder, '客厅');
    });

    // Test 7: cancelAll catches error
    test('should not throw when cancelAll fails', () async {
      when(() => mockPlugin.cancelAll())
          .thenThrow(Exception('cancelAll failed'));
      when(() => mockBadgeManager.updateBadge(any(), any()))
          .thenAnswer((_) async {});

      // Should not throw
      await service.cancelAll();
    });

    // Test 8: showNotification encodeds payload with reminder_id
    test('should encode correct payload with reminder_id', () async {
      String? capturedPayload;
      when(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: captureAny(named: 'payload'),
          )).thenAnswer((invocation) async {
        capturedPayload =
            invocation.namedArguments[const Symbol('payload')] as String?;
      });
      when(() => mockBadgeManager.updateBadge(any(), any()))
          .thenAnswer((_) async {});

      await service.show(testReminder, '厨房');

      expect(capturedPayload, '{"reminder_id":42}');
    });

    // Test 9: showNotification with content null
    test('should handle reminder without content', () async {
      final reminderNoContent = testReminder.copyWith(content: null);
      when(() => mockPlugin.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async {});
      when(() => mockBadgeManager.updateBadge(any(), any()))
          .thenAnswer((_) async {});

      // Should not throw
      await service.show(reminderNoContent, '客厅');
    });

    // Test 10: cancelReminderNotification catches error
    test('should not throw when cancel fails', () async {
      when(() => mockPlugin.cancel(any()))
          .thenThrow(Exception('cancel failed'));

      // Should not throw
      await service.cancelReminderNotification(42);
    });
  });
}
