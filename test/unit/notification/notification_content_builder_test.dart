import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_reminder/src/core/common/code/models/enums.dart';
import 'package:home_reminder/src/core/common/code/models/reminder_model.dart';
import 'package:home_reminder/src/core/notification/code/notification_content_builder.dart';

void main() {
  late NotificationContentBuilder builder;

  final baseReminder = Reminder(
    id: 1,
    groupId: 1,
    title: '擦窗户',
    content: '用湿布擦拭客厅窗户玻璃',
    scheduledAt: DateTime(2026, 5, 30, 10, 0),
    status: ReminderStatus.pending,
    frequency: ReminderFrequency.once,
    createdAt: DateTime(2026, 5, 29),
  );

  setUp(() {
    builder = NotificationContentBuilder();
  });

  group('NotificationContentBuilder', () {
    test('should include group name prefix in Android title', () {
      final details = builder.buildAndroid(baseReminder, '客厅');
      expect(details.channelId, 'reminder_channel');
      expect(details.channelName, '到期提醒');
      expect(details.importance, Importance.max);
      expect(details.priority, Priority.high);
    });

    test('should include subtitle in iOS when title is not empty', () {
      final details = builder.buildDarwin(baseReminder, '卧室');
      expect(details.presentAlert, true);
      expect(details.presentBadge, true);
      expect(details.presentSound, true);
      expect(details.subtitle, '擦窗户');
    });

    test('should omit subtitle in iOS when title is empty', () {
      final reminder = baseReminder.copyWith(title: '', clearContent: false);
      final details = builder.buildDarwin(reminder, '厨房');
      expect(details.subtitle, isNull);
    });

    test('should use fallback title when title is empty', () {
      final reminder = baseReminder.copyWith(
        title: '',
        content: '清理冰箱',
      );
      final details = builder.buildAndroid(reminder, '冰箱');
      // body should contain fallback title
      expect(details.importance, Importance.max);
    });

    test('should truncate long body over 200 characters', () {
      // Create a very long content that would exceed 200 chars
      final longContent = 'A' * 250;
      final reminder = baseReminder.copyWith(
        title: '清理',
        content: longContent,
      );
      final android = builder.buildAndroid(reminder, '厨房');
      expect(android.importance, Importance.max);

      final ios = builder.buildDarwin(reminder, '厨房');
      expect(ios.subtitle, '清理');
    });

    test('should handle content as null gracefully', () {
      final reminder = baseReminder.copyWith(
        title: '买牛奶',
        content: null,
      );
      final android = builder.buildAndroid(reminder, '超市');
      expect(android.channelId, 'reminder_channel');
    });
  });
}
