import 'package:flutter_test/flutter_test.dart';
import 'package:home_reminder/src/core/common/code/models/enums.dart';
import 'package:home_reminder/src/core/reminder/code/reminder_scheduler.dart';

void main() {
  final scheduler = const ReminderScheduler();
  final baseTime = DateTime(2026, 6, 1, 10, 0); // Monday

  group('ReminderScheduler — nextTriggerTime', () {
    test('once 返回原时间', () {
      expect(
        scheduler.nextTriggerTime(baseTime, ReminderFrequency.once),
        baseTime,
      );
    });

    test('daily +1 天', () {
      expect(
        scheduler.nextTriggerTime(baseTime, ReminderFrequency.daily),
        DateTime(2026, 6, 2, 10, 0),
      );
    });

    test('weekly +7 天', () {
      expect(
        scheduler.nextTriggerTime(baseTime, ReminderFrequency.weekly),
        DateTime(2026, 6, 8, 10, 0),
      );
    });

    test('biweekly +14 天', () {
      expect(
        scheduler.nextTriggerTime(baseTime, ReminderFrequency.biweekly),
        DateTime(2026, 6, 15, 10, 0),
      );
    });

    test('monthly +1 月', () {
      expect(
        scheduler.nextTriggerTime(baseTime, ReminderFrequency.monthly),
        DateTime(2026, 7, 1, 10, 0),
      );
    });

    test('monthly 月末溢出安全 — 1/31 → 2/28', () {
      final jan31 = DateTime(2026, 1, 31, 10, 0);
      expect(
        scheduler.nextTriggerTime(jan31, ReminderFrequency.monthly),
        DateTime(2026, 2, 28, 10, 0),
      );
    });

    test('monthly 跨年 — 12/15 → 1/15', () {
      final dec15 = DateTime(2026, 12, 15, 10, 0);
      expect(
        scheduler.nextTriggerTime(dec15, ReminderFrequency.monthly),
        DateTime(2027, 1, 15, 10, 0),
      );
    });
  });

  group('ReminderScheduler — isOverdue', () {
    test('过去时间 → 过期', () {
      expect(
        scheduler.isOverdue(DateTime(2020, 1, 1), now: DateTime(2026, 6, 1)),
        isTrue,
      );
    });

    test('未来时间 → 未过期', () {
      expect(
        scheduler.isOverdue(DateTime(2030, 1, 1), now: DateTime(2026, 6, 1)),
        isFalse,
      );
    });
  });

  group('ReminderScheduler — shouldSkip', () {
    test('pending 不跳过', () {
      expect(scheduler.shouldSkip(ReminderStatus.pending), isFalse);
    });

    test('overdue 不跳过', () {
      expect(scheduler.shouldSkip(ReminderStatus.overdue), isFalse);
    });

    test('completed 跳过', () {
      expect(scheduler.shouldSkip(ReminderStatus.completed), isTrue);
    });

    test('dismissed 跳过', () {
      expect(scheduler.shouldSkip(ReminderStatus.dismissed), isTrue);
    });
  });
}
