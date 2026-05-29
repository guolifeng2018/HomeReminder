import 'package:flutter_test/flutter_test.dart';
import 'package:home_reminder/src/core/reminder/code/postpone_logic.dart';

void main() {
  final logic = const PostponeLogic();
  final baseTime = DateTime(2026, 6, 1, 10, 0);

  group('PostponeLogic — 推迟', () {
    test('推迟 1 小时', () {
      expect(
        logic.postpone(baseTime, preset: PostponePreset.oneHour),
        DateTime(2026, 6, 1, 11, 0),
      );
    });

    test('推迟 3 小时', () {
      expect(
        logic.postpone(baseTime, preset: PostponePreset.threeHours),
        DateTime(2026, 6, 1, 13, 0),
      );
    });

    test('推迟到明天', () {
      expect(
        logic.postpone(baseTime, preset: PostponePreset.tomorrow),
        DateTime(2026, 6, 2, 10, 0),
      );
    });

    test('自定义推迟 30 分钟', () {
      expect(
        logic.postpone(baseTime,
            preset: PostponePreset.custom,
            custom: const Duration(minutes: 30)),
        DateTime(2026, 6, 1, 10, 30),
      );
    });

    test('custom 不传 Duration 默认 1 小时', () {
      expect(
        logic.postpone(baseTime, preset: PostponePreset.custom),
        DateTime(2026, 6, 1, 11, 0),
      );
    });

    test('跨天推迟 — 23:30 + 1h = 次日 00:30', () {
      final lateNight = DateTime(2026, 6, 1, 23, 30);
      expect(
        logic.postpone(lateNight, preset: PostponePreset.oneHour),
        DateTime(2026, 6, 2, 0, 30),
      );
    });

    test('跨月推迟 — 月底 23:00 → 明天', () {
      final monthEnd = DateTime(2026, 6, 30, 23, 0);
      expect(
        logic.postpone(monthEnd, preset: PostponePreset.tomorrow),
        DateTime(2026, 7, 1, 23, 0),
      );
    });
  });
}
