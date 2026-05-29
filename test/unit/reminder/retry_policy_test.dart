import 'package:flutter_test/flutter_test.dart';
import 'package:home_reminder/src/core/reminder/code/retry_policy.dart';

void main() {
  final policy = const RetryPolicy();
  final baseTime = DateTime(2026, 6, 1, 10, 0);

  group('RetryPolicy — 退避间隔', () {
    test('第 1 次重试 +5 分钟', () {
      expect(
        policy.nextRetryTime(1, baseTime),
        DateTime(2026, 6, 1, 10, 5),
      );
      expect(RetryPolicy.backoffMinutes(1), 5);
    });

    test('第 2 次重试 +15 分钟', () {
      expect(
        policy.nextRetryTime(2, baseTime),
        DateTime(2026, 6, 1, 10, 15),
      );
      expect(RetryPolicy.backoffMinutes(2), 15);
    });

    test('第 3 次重试 +45 分钟', () {
      expect(
        policy.nextRetryTime(3, baseTime),
        DateTime(2026, 6, 1, 10, 45),
      );
      expect(RetryPolicy.backoffMinutes(3), 45);
    });

    test('超过 3 次返回 null', () {
      expect(policy.nextRetryTime(4, baseTime), isNull);
      expect(policy.nextRetryTime(5, baseTime), isNull);
    });

    test('attemptNumber < 1 返回 null', () {
      expect(policy.nextRetryTime(0, baseTime), isNull);
      expect(policy.nextRetryTime(-1, baseTime), isNull);
    });

    test('超过 3 次 backoffMinutes 返回 0', () {
      expect(RetryPolicy.backoffMinutes(4), 0);
      expect(RetryPolicy.backoffMinutes(0), 0);
    });
  });
}
