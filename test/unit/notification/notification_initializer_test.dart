import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_reminder/src/core/notification/code/notification_initializer.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockAndroidFlutterLocalNotificationsPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class MockIOSFlutterLocalNotificationsPlugin extends Mock
    implements IOSFlutterLocalNotificationsPlugin {}

void main() {
  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late MockAndroidFlutterLocalNotificationsPlugin mockAndroid;
  late MockIOSFlutterLocalNotificationsPlugin mockIOS;

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    mockAndroid = MockAndroidFlutterLocalNotificationsPlugin();
    mockIOS = MockIOSFlutterLocalNotificationsPlugin();

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
  });

  group('NotificationInitializer', () {
    test('should create with correct static constants', () {
      expect(NotificationInitializer.channelId, 'reminder_channel');
      expect(NotificationInitializer.channelName, '到期提醒');
      expect(NotificationInitializer.channelDescription, '家庭事务到期提醒通知');
      expect(NotificationInitializer.channelId, isNotEmpty);
      expect(NotificationInitializer.channelName, isNotEmpty);
    });

    test('should be not initialized initially', () {
      final initializer =
          NotificationInitializer(plugin: mockPlugin);
      expect(initializer.isInitialized, false);
      expect(initializer.initFailed, false);
    });

    test('should create notification channel on Android', () async {
      when(() => mockPlugin.initialize(any())).thenAnswer((_) async => true);
      when(() => mockPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()).thenReturn(mockAndroid);
      when(() => mockPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()).thenReturn(null);
      when(() => mockAndroid.createNotificationChannel(any()))
          .thenAnswer((_) async {});

      final initializer =
          NotificationInitializer(plugin: mockPlugin);
      await initializer.ensureInitialized();

      expect(initializer.isInitialized, true);

      // capture the AndroidNotificationChannel
      final captured = verify(() => mockAndroid.createNotificationChannel(
            captureAny(),
          )).captured;
      expect(captured.length, 1);
      final channel = captured.first as AndroidNotificationChannel;
      expect(channel.id, 'reminder_channel');
      expect(channel.name, '到期提醒');
      expect(channel.importance, Importance.max);
    });

    test('should request iOS permissions', () async {
      when(() => mockPlugin.initialize(any())).thenAnswer((_) async => true);
      when(() => mockPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()).thenReturn(null);
      when(() => mockPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()).thenReturn(mockIOS);
      when(() => mockIOS.requestPermissions(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
          )).thenAnswer((_) async => true);

      final initializer =
          NotificationInitializer(plugin: mockPlugin);
      await initializer.ensureInitialized();

      expect(initializer.isInitialized, true);

      verify(() => mockIOS.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          )).called(1);
    });

    test('should be idempotent — second call is no-op', () async {
      when(() => mockPlugin.initialize(any())).thenAnswer((_) async => true);
      when(() => mockPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()).thenReturn(mockAndroid);
      when(() => mockPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()).thenReturn(null);
      when(() => mockAndroid.createNotificationChannel(any()))
          .thenAnswer((_) async {});

      final initializer =
          NotificationInitializer(plugin: mockPlugin);

      await initializer.ensureInitialized();
      await initializer.ensureInitialized();

      expect(initializer.isInitialized, true);
      verify(() => mockPlugin.initialize(any())).called(1);
    });

    test('should fallback to no-op on initialization failure', () async {
      when(() => mockPlugin.initialize(any()))
          .thenThrow(Exception('Plugin init failed'));

      final initializer =
          NotificationInitializer(plugin: mockPlugin);

      // should not throw
      await initializer.ensureInitialized();

      expect(initializer.isInitialized, false);
      expect(initializer.initFailed, true);

      // second call should be fast no-op
      await initializer.ensureInitialized();
      verify(() => mockPlugin.initialize(any())).called(1);
    });

    test('should expose plugin instance', () {
      final initializer =
          NotificationInitializer(plugin: mockPlugin);
      expect(initializer.plugin, same(mockPlugin));
    });
  });
}
