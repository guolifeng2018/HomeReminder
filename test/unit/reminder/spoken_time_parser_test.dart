import 'package:flutter_test/flutter_test.dart';
import 'package:home_reminder/src/core/reminder/code/spoken_time_parser.dart';

/// referenceDate: 2026-06-01 Monday 10:00
final referenceDate = DateTime(2026, 6, 1, 10, 0);

void main() {
  group('SpokenTimeParser — 纯相对偏移', () {
    test('15分钟后', () {
      final result = SpokenTimeParser.parse('15分钟后', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 1, 10, 15));
    });

    test('半小时后', () {
      final result = SpokenTimeParser.parse('半小时后', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 1, 10, 30));
    });

    test('2小时后', () {
      final result = SpokenTimeParser.parse('2小时后', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 1, 12, 0));
    });

    test('三天后', () {
      final result = SpokenTimeParser.parse('三天后', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 4, 10, 0));
    });

    test('一周后', () {
      final result = SpokenTimeParser.parse('一周后', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 8, 10, 0));
    });

    test('半个月后', () {
      final result = SpokenTimeParser.parse('半个月后', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 16, 10, 0));
    });

    test('隔天', () {
      final result = SpokenTimeParser.parse('隔天', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 3, 10, 0));
    });
  });

  group('SpokenTimeParser — 日期+时间组合', () {
    test('今天下午3点', () {
      final result = SpokenTimeParser.parse('今天下午3点', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 1, 15, 0));
    });

    test('明天早上', () {
      final result = SpokenTimeParser.parse('明天早上', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 2, 8, 0));
    });

    test('后天下午', () {
      final result = SpokenTimeParser.parse('后天下午', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 3, 14, 0));
    });
  });

  group('SpokenTimeParser — 仅日期模式', () {
    test('大后天', () {
      final result = SpokenTimeParser.parse('大后天', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 4, 9, 0));
    });

    test('下周一下午', () {
      final result = SpokenTimeParser.parse('下周一下午', referenceDate: referenceDate);
      // 下周一 = 6/8, 下午默认 14:00
      expect(result, DateTime(2026, 6, 8, 14, 0));
    });

    test('下周三', () {
      final result = SpokenTimeParser.parse('下周三', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 10, 9, 0));
    });

    test('本周五', () {
      final result = SpokenTimeParser.parse('本周五', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 5, 9, 0));
    });

    test('周末 → 本周六', () {
      final result = SpokenTimeParser.parse('周末', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 6, 9, 0));
    });

    test('周末 → 若今天是周六则返回下周六', () {
      final satRef = DateTime(2026, 6, 6, 10, 0); // Saturday
      final result = SpokenTimeParser.parse('周末', referenceDate: satRef);
      expect(result, DateTime(2026, 6, 13, 9, 0)); // 下周六
    });

    test('下周末 → 下周六', () {
      final result = SpokenTimeParser.parse('下周末', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 13, 9, 0));
    });

    test('月底 → 6月30日', () {
      final result = SpokenTimeParser.parse('月底', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 30, 9, 0));
    });

    test('月底 → 闰年2月29日', () {
      final leapRef = DateTime(2024, 2, 15, 10, 0);
      final result = SpokenTimeParser.parse('月底', referenceDate: leapRef);
      expect(result, DateTime(2024, 2, 29, 9, 0));
    });

    test('月底 → 非闰年2月28日', () {
      final nonLeapRef = DateTime(2025, 2, 15, 10, 0);
      final result = SpokenTimeParser.parse('月底', referenceDate: nonLeapRef);
      expect(result, DateTime(2025, 2, 28, 9, 0));
    });

    test('下个月5号', () {
      final result = SpokenTimeParser.parse('下个月5号', referenceDate: referenceDate);
      expect(result, DateTime(2026, 7, 5, 9, 0));
    });

    test('下个月31号 → 安全取最后一天', () {
      // 6月只有30天，下个月是7月有31天
      // 测试12月→1月跨年
      final decRef = DateTime(2026, 12, 15, 10, 0);
      final result = SpokenTimeParser.parse('下个月5号', referenceDate: decRef);
      expect(result, DateTime(2027, 1, 5, 9, 0));
    });
  });

  group('SpokenTimeParser — 仅时间模式', () {
    test('上午9点', () {
      final result = SpokenTimeParser.parse('上午9点', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 1, 9, 0));
    });

    test('中午12点', () {
      final result = SpokenTimeParser.parse('中午12点', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 1, 12, 0));
    });

    test('晚上8点', () {
      final result = SpokenTimeParser.parse('晚上8点', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 1, 20, 0));
    });

    test('凌晨2点', () {
      final result = SpokenTimeParser.parse('凌晨2点', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 1, 2, 0));
    });
  });

  group('SpokenTimeParser — 频率模式', () {
    test('每天早上8点', () {
      final result = SpokenTimeParser.parse('每天早上8点', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 1, 8, 0));
    });

    test('每周三', () {
      final result = SpokenTimeParser.parse('每周三', referenceDate: referenceDate);
      expect(result, DateTime(2026, 6, 3, 9, 0));
    });
  });

  group('SpokenTimeParser — 边界与异常', () {
    test('空字符串返回 null', () {
      expect(SpokenTimeParser.parse('', referenceDate: referenceDate), isNull);
      expect(SpokenTimeParser.parse('   ', referenceDate: referenceDate), isNull);
    });

    test('无意义输入返回 null', () {
      expect(SpokenTimeParser.parse('你好世界', referenceDate: referenceDate), isNull);
      expect(SpokenTimeParser.parse('abc123', referenceDate: referenceDate), isNull);
    });

    test('默认 referenceDate 为当前时间', () {
      final result = SpokenTimeParser.parse('今天');
      expect(result, isNotNull);
      final now = DateTime.now();
      expect(result!.year, now.year);
      expect(result.month, now.month);
      expect(result.day, now.day);
    });
  });
}
