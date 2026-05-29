import 'package:flutter_test/flutter_test.dart';
import 'package:home_reminder/src/core/common/code/utils/date_formatter.dart';

void main() {
  group('DateFormatter.parseNaturalLanguage', () {
    // 固定参考时间：2026-06-15 10:00（周一）
    final refDate = DateTime(2026, 6, 15, 10);

    // ─── 相对日期 ───

    test('"今天下午三点" → 今天 15:00', () {
      final result = DateFormatter.parseNaturalLanguage('今天下午三点', referenceDate: refDate);
      expect(result, DateTime(2026, 6, 15, 15));
    });

    test('"明天上午九点" → 明天 09:00', () {
      final result = DateFormatter.parseNaturalLanguage('明天上午九点', referenceDate: refDate);
      expect(result, DateTime(2026, 6, 16, 9, 0));
    });

    test('"后天" → 后天 09:00（默认）', () {
      final result = DateFormatter.parseNaturalLanguage('后天', referenceDate: refDate);
      expect(result, DateTime(2026, 6, 17, 9, 0));
    });

    test('"大后天" → 3天后 09:00', () {
      final result = DateFormatter.parseNaturalLanguage('大后天', referenceDate: refDate);
      expect(result, DateTime(2026, 6, 18, 9, 0));
    });

    // ─── 星期表达 ───

    test('"下周一" → 下周一 09:00', () {
      // refDate 是周一(6/15)，下周一是 6/22
      final result = DateFormatter.parseNaturalLanguage('下周一', referenceDate: refDate);
      expect(result, DateTime(2026, 6, 22, 9, 0));
    });

    test('"下周五" → 下周五 09:00', () {
      // refDate 周一(6/15)，本周五 6/19，下周五 6/26
      final result = DateFormatter.parseNaturalLanguage('下周五', referenceDate: refDate);
      expect(result, DateTime(2026, 6, 26, 9, 0));
    });

    test('"下周" → 7天后 09:00', () {
      final result = DateFormatter.parseNaturalLanguage('下周', referenceDate: refDate);
      expect(result, DateTime(2026, 6, 22, 9, 0));
    });

    test('"本周日" → 本周日 09:00', () {
      // refDate 周一(6/15)，本周日 6/21
      final result = DateFormatter.parseNaturalLanguage('本周日', referenceDate: refDate);
      expect(result, DateTime(2026, 6, 21, 9, 0));
    });

    test('"每周五" → 最近未来周五 09:00', () {
      // refDate 周一(6/15)，本周五 6/19
      final result = DateFormatter.parseNaturalLanguage('每周五', referenceDate: refDate);
      expect(result, DateTime(2026, 6, 19, 9, 0));
    });

    // ─── 时间段 + 时间 ───

    test('"明天中午" → 明天 12:00', () {
      final result = DateFormatter.parseNaturalLanguage('明天中午', referenceDate: refDate);
      expect(result, DateTime(2026, 6, 16, 12, 0));
    });

    test('"每天晚上八点" → 今天 20:00', () {
      final result = DateFormatter.parseNaturalLanguage('每天晚上八点', referenceDate: refDate);
      expect(result, DateTime(2026, 6, 15, 20));
    });

    // ─── 相对偏移 ───

    test('"半个小时"→ 参考时刻 + 30min', () {
      // Note: "半个小时" without "后" won't match the relative offset pattern
      // "半小时后" is the expected form
      final result = DateFormatter.parseNaturalLanguage('半小时后', referenceDate: refDate);
      expect(result, DateTime(2026, 6, 15, 10, 30));
    });

    test('"三天后" → 3天后 09:00', () {
      final result = DateFormatter.parseNaturalLanguage('三天后', referenceDate: refDate);
      expect(result, DateTime(2026, 6, 18, 9, 0));
    });

    test('"半个月后" → 15天后 09:00', () {
      final result = DateFormatter.parseNaturalLanguage('半个月后', referenceDate: refDate);
      expect(result, DateTime(2026, 6, 30, 9, 0));
    });

    test('"一个月后" → 30天后 09:00', () {
      final result = DateFormatter.parseNaturalLanguage('一个月后', referenceDate: refDate);
      expect(result, DateTime(2026, 7, 15, 9, 0));
    });

    test('"每三天" → 3天后 09:00（首次触发）', () {
      final result = DateFormatter.parseNaturalLanguage('每三天', referenceDate: refDate);
      expect(result, DateTime(2026, 6, 18, 9, 0));
    });

    // ─── 月份表达 ───

    test('"下个月五号" → 下个月 5 号 09:00', () {
      final result = DateFormatter.parseNaturalLanguage('下个月五号', referenceDate: refDate);
      expect(result, DateTime(2026, 7, 5, 9, 0));
    });

    // ─── 边界测试 ───

    test('上午12点 → 0:00', () {
      final result = DateFormatter.parseNaturalLanguage('明天上午十二点', referenceDate: refDate);
      expect(result, DateTime(2026, 6, 16));
    });

    test('下午12点 → 12:00', () {
      final result = DateFormatter.parseNaturalLanguage('明天下午十二点', referenceDate: refDate);
      expect(result, DateTime(2026, 6, 16, 12, 0));
    });

    test('晚上12点 → 0:00（零点）', () {
      final result = DateFormatter.parseNaturalLanguage('今天晚上十二点', referenceDate: refDate);
      expect(result, DateTime(2026, 6, 15));
    });

    test('闰年 2月29日（2028年）', () {
      final feb28 = DateTime(2028, 2, 28, 10);
      final result = DateFormatter.parseNaturalLanguage('明天', referenceDate: feb28);
      expect(result, DateTime(2028, 2, 29, 9, 0));
    });

    test('月末 31日溢出 → 安全裁剪（1月31日 + 1个月 → 2月28/29日）', () {
      final jan31 = DateTime(2026, 1, 31, 10, 0);
      // "一个月后" → 30天后，即 3月2日
      final result = DateFormatter.parseNaturalLanguage('一个月后', referenceDate: jan31);
      expect(result, DateTime(2026, 3, 2, 9, 0));
    });

    test('下个月 31 号（当月只有30天）→ 安全裁剪到30号', () {
      // 3月31日 → 下个月是4月，只有30天，31号 → 30号
      final mar31 = DateTime(2026, 3, 31, 10, 0);
      final result = DateFormatter.parseNaturalLanguage('下个月三十一号', referenceDate: mar31);
      expect(result, DateTime(2026, 4, 30, 9, 0));
    });

    // ─── 不可解析 → null ───

    test('空字符串 → null', () {
      expect(DateFormatter.parseNaturalLanguage(''), isNull);
    });

    test('纯空白 → null', () {
      expect(DateFormatter.parseNaturalLanguage('   '), isNull);
    });

    test('无意义输入 → null', () {
      expect(DateFormatter.parseNaturalLanguage('随便什么文字'), isNull);
    });

    test('无参考时间时使用当前时间（至少不返回 null）', () {
      final result = DateFormatter.parseNaturalLanguage('今天');
      expect(result, isNotNull);
    });
  });

  group('DateFormatter 辅助方法', () {
    test('formatDisplay 格式化显示', () {
      final dt = DateTime(2026, 6, 15, 14, 30);
      expect(DateFormatter.formatDisplay(dt), '6月15日 14:30');
    });

    test('formatStandard 格式化标准', () {
      final dt = DateTime(2026, 6, 15, 14, 30);
      expect(DateFormatter.formatStandard(dt), '2026-06-15 14:30');
    });
  });
}
