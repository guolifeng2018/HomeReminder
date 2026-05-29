/// 自然语言口语时间解析器
///
/// 将中文口语时间表达解析为 [DateTime] 对象。
/// 支持 ≥15 种常用口语表达，覆盖相对日期、星期、时刻组合。
///
/// 仅依赖 `intl` 包（用于格式化，核心解析为纯 Dart 实现）。
library;

import 'package:intl/intl.dart';

/// 自然语言时间解析工具类
class DateFormatter {
  DateFormatter._();

  // ─── 中文数字映射 ───

  static const Map<String, int> _digits = {
    '零': 0, '一': 1, '二': 2, '三': 3, '四': 4,
    '五': 5, '六': 6, '七': 7, '八': 8, '九': 9,
    '十': 10, '两': 2,
  };

  /// 中文数字 → int（支持 "二十三" → 23，"十" → 10，"三十一" → 31）
  static int? _parseNumber(String s) {
    if (s.isEmpty) return null;
    final i = int.tryParse(s);
    if (i != null) return i;
    // 纯中文数字
    if (_digits.containsKey(s) && s != '十') return _digits[s];
    if (s == '十') return 10;
    if (s.length == 2 && s[0] == '十') {
      return 10 + (_digits[s[1]] ?? 0);
    }
    if (s.length == 2 && s[1] == '十') {
      return (_digits[s[0]] ?? 0) * 10;
    }
    if (s.length == 3 && s[1] == '十') {
      return (_digits[s[0]] ?? 0) * 10 + (_digits[s[2]] ?? 0);
    }
    return null;
  }

  // ─── 星期映射 ───

  static const Map<String, int> _weekdays = {
    '一': DateTime.monday, '二': DateTime.tuesday,
    '三': DateTime.wednesday, '四': DateTime.thursday,
    '五': DateTime.friday, '六': DateTime.saturday,
    '日': DateTime.sunday, '天': DateTime.sunday,
  };

  // ─── 公共 API ───

  /// 解析自然语言时间表达
  ///
  /// [input] 中文口语时间字符串（如 "今天下午三点"、"下周一"、"半小时后"）。
  /// [referenceDate] 参考时间，默认为当前时刻。
  ///
  /// 成功解析返回 [DateTime]，无法识别返回 `null`。
  static DateTime? parseNaturalLanguage(String input, {DateTime? referenceDate}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final now = referenceDate ?? DateTime.now();

    // 优先处理纯相对偏移（无日期成分，直接返回 DateTime）
    final relativeResult = _parseRelativeOffset(trimmed, now);
    if (relativeResult != null) return relativeResult;

    // 提取时刻（hour、minute）并移除时间片段，得到纯日期文本
    final (timeHour, timeMinute, dateText) = _extractTime(trimmed);

    // 解析日期部分
    final datePart = _extractDate(dateText, now);
    if (datePart == null && timeHour == null) {
      // 尝试完整模式匹配（日期 + 时间在同一输入中）
      return _parseFullPattern(dateText, now);
    }
    if (datePart == null) return null;

    final h = timeHour ?? 9;
    final m = timeMinute;
    return _safeDateTime(datePart.year, datePart.month, datePart.day, h, m);
  }

  /// 纯相对时间偏移（如 "半小时后"、"X分钟后"、"X小时后"）
  static DateTime? _parseRelativeOffset(String text, DateTime now) {
    // "半小时后"
    if (text.contains('半小时后') || text.contains('半个小时后')) {
      return now.add(const Duration(minutes: 30));
    }
    // "X分钟后"
    final minLater = RegExp(r'([零一二三四五六七八九十两\d]+)分钟后').firstMatch(text);
    if (minLater != null) {
      final mins = _parseNumber(minLater.group(1)!);
      if (mins != null) return now.add(Duration(minutes: mins));
    }
    // "X小时后"
    final hourLater = RegExp(r'([零一二三四五六七八九十两\d]+)小时后').firstMatch(text);
    if (hourLater != null) {
      final hrs = _parseNumber(hourLater.group(1)!);
      if (hrs != null) return now.add(Duration(hours: hrs));
    }
    // 纯数字 "X分钟后"
    final digitMinLater = RegExp(r'(\d+)分钟后').firstMatch(text);
    if (digitMinLater != null) {
      final mins = int.tryParse(digitMinLater.group(1)!);
      if (mins != null) return now.add(Duration(minutes: mins));
    }
    // 纯数字 "X小时后"
    final digitHourLater = RegExp(r'(\d+)小时后').firstMatch(text);
    if (digitHourLater != null) {
      final hrs = int.tryParse(digitHourLater.group(1)!);
      if (hrs != null) return now.add(Duration(hours: hrs));
    }
    return null;
  }

  /// 格式化 DateTime 为显示字符串（"MM月dd日 HH:mm"）
  static String formatDisplay(DateTime dt) {
    return DateFormat('M月d日 HH:mm').format(dt);
  }

  /// 格式化为标准日期时间字符串（"yyyy-MM-dd HH:mm"）
  static String formatStandard(DateTime dt) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  // ─── 时刻提取 ───

  /// 返回 (hour, minute, 去除时间后的文本)。
  static (int?, int, String) _extractTime(String text) {
    int? hour;
    int minute = 0;

    var remaining = text;

    // 上午/下午 + 数字 + 点 + 可选 分
    final ampmHourMin = RegExp(
      r'(上午|下午|早上|中午|晚上|凌晨)([零一二三四五六七八九十两\d]+)点(?:([零一二三四五六七八九十两\d]+)分)?',
    );
    final m1 = ampmHourMin.firstMatch(remaining);
    if (m1 != null) {
      final period = m1.group(1)!;
      final hRaw = _parseNumber(m1.group(2)!);
      final mRaw = m1.group(3) != null ? _parseNumber(m1.group(3)!) : 0;
      if (hRaw != null) {
        hour = _applyPeriod(period, hRaw);
        minute = mRaw ?? 0;
        remaining = remaining.replaceRange(m1.start, m1.end, '').trim();
      }
    }

    // 中午/晚上/凌晨 无具体数字（如"明天中午"）
    if (hour == null) {
      final noonMatch = RegExp(r'中午').firstMatch(remaining);
      if (noonMatch != null) {
        hour = 12;
        minute = 0;
        remaining = remaining.replaceRange(noonMatch.start, noonMatch.end, '').trim();
      }
    }
    
    if (hour == null) {
      final eveningMatch = RegExp(r'晚上').firstMatch(remaining);
      if (eveningMatch != null) {
        hour = 20;
        minute = 0;
        remaining = remaining.replaceRange(eveningMatch.start, eveningMatch.end, '').trim();
      }
    }

    // 纯数字时间 "X点" 或 "X点X分"
    if (hour == null) {
      final plainHourMin = RegExp(
        r'([零一二三四五六七八九十两\d]+)点(?:([零一二三四五六七八九十两\d]+)分)?',
      );
      final m2 = plainHourMin.firstMatch(remaining);
      if (m2 != null) {
        final hRaw = _parseNumber(m2.group(1)!);
        final mRaw = m2.group(2) != null ? _parseNumber(m2.group(2)!) : 0;
        if (hRaw != null) {
          hour = hRaw; // 无 period 修饰，保持原值
          minute = mRaw ?? 0;
          remaining = remaining.replaceRange(m2.start, m2.end, '').trim();
        }
      }
    }

    return (hour, minute, remaining);
  }

  /// 根据时段调整小时数
  static int _applyPeriod(String period, int h) {
    switch (period) {
      case '凌晨':
        return h == 12 ? 0 : h;
      case '上午':
      case '早上':
        return h == 12 ? 0 : h;
      case '中午':
        return 12; // "中午" 固定 12:00
      case '下午':
        return h == 12 ? 12 : h + 12;
      case '晚上':
        return h == 12 ? 0 : h + 12;
      default:
        return h;
    }
  }

  // ─── 日期提取 ───

  /// 从文本中提取日期部分，返回 DateTime（不含时刻）。
  static DateTime? _extractDate(String text, DateTime now) {
    // 绝对日期：今天、明天、后天、大后天（先长后短避免 "大后天" 被 "后天" 误匹配）
    final relativeDays = [
      ('大后天', 3),
      ('后天', 2),
      ('明天', 1),
      ('今天', 0),
    ];
    for (final (word, offset) in relativeDays) {
      if (text.contains(word)) {
        return now.add(Duration(days: offset));
      }
    }

    // "每天" → 今天（用于 "每天晚上八点" 等模式）
    if (text.contains('每天')) {
      return now;
    }

    // "下周"（无具体星期）→ 7天后
    if (text.contains('下周') && !RegExp(r'下周[一二三四五六日天]').hasMatch(text)) {
      return now.add(const Duration(days: 7));
    }

    // "下周X" → 下周某天
    final nextWeekDay = RegExp(r'下周([一二三四五六日天])').firstMatch(text);
    if (nextWeekDay != null) {
      final wd = _weekdays[nextWeekDay.group(1)!];
      if (wd != null) {
        return _nextWeekday(now, wd, nextWeek: true);
      }
    }

    // "本周X" → 本周某天
    final thisWeekDay = RegExp(r'本周([一二三四五六日天])').firstMatch(text);
    if (thisWeekDay != null) {
      final wd = _weekdays[thisWeekDay.group(1)!];
      if (wd != null) {
        return _nextWeekday(now, wd, nextWeek: false);
      }
    }

    // "周X" / "星期X"（无前缀，默认最近未来）
    final plainWeekDay = RegExp(r'周([一二三四五六日天])').firstMatch(text);
    if (plainWeekDay != null) {
      final wd = _weekdays[plainWeekDay.group(1)!];
      if (wd != null) {
        return _nextWeekday(now, wd, nextWeek: false);
      }
    }

    // "每X天" / "X天后" → X天后
    final daysLater = RegExp(r'(?:每|每隔)?([零一二三四五六七八九十两\d]+|半)天[后内]?').firstMatch(text);
    if (daysLater != null) {
      final raw = daysLater.group(1)!;
      final days = raw == '半' ? 0 : (_parseNumber(raw) ?? 0);
      if (raw == '半') {
        // "半天" → 0.5天，取12小时 → 但要求是日期，返回今天
        return now;
      }
      if (days > 0) {
        return now.add(Duration(days: days));
      }
    }

    // "X天后"（纯数字）
    final pureDaysLater = RegExp(r'(\d+)天后').firstMatch(text);
    if (pureDaysLater != null) {
      final days = int.tryParse(pureDaysLater.group(1)!) ?? 0;
      return now.add(Duration(days: days));
    }

    // "半个月后" → 15天后
    if (text.contains('半个月')) {
      return now.add(const Duration(days: 15));
    }

    // "一个月后" → 30天后
    if (text.contains('一个月')) {
      return now.add(const Duration(days: 30));
    }

    // "X周后" → X*7天后
    final weeksLater = RegExp(r'([零一二三四五六七八九十两\d]+)周[后内]?').firstMatch(text);
    if (weeksLater != null) {
      final weeks = _parseNumber(weeksLater.group(1)!) ?? 0;
      return now.add(Duration(days: weeks * 7));
    }

    // "下个月X号/日"
    final nextMonthDay = RegExp(r'下个月([零一二三四五六七八九十两\d]+)[号日]').firstMatch(text);
    if (nextMonthDay != null) {
      final day = _parseNumber(nextMonthDay.group(1)!);
      if (day != null) {
        return _nextMonthDay(now, day);
      }
    }

    // "下个月"（无具体日）→ 下个月同一天
    if (text.contains('下个月')) {
      return _addMonthsSafe(now, 1);
    }

    return null;
  }

  /// 完整模式匹配（日期 + 时间在同一输入中，且前面的提取未能分离）
  /// e.g., "每周五" → 没有显式时间，应该还能匹配上
  static DateTime? _parseFullPattern(String text, DateTime now) {
    // "每周X" → 最近一周的周X
    final everyWeek = RegExp(r'每周([一二三四五六日天])').firstMatch(text);
    if (everyWeek != null) {
      final wd = _weekdays[everyWeek.group(1)!];
      if (wd != null) {
        return _nextWeekday(now, wd, nextWeek: false);
      }
    }
    return null;
  }

  // ─── 辅助 ───

  /// 计算下一个指定星期几的日期
  /// [nextWeek] 为 true 时，跳过本周，从下周开始算
  static DateTime _nextWeekday(DateTime base, int targetWeekday, {required bool nextWeek}) {
    var daysUntil = targetWeekday - base.weekday;
    if (nextWeek) {
      // 确保目标日在下周
      daysUntil += 7;
    } else {
      if (daysUntil < 0) daysUntil += 7;
      if (daysUntil == 0) daysUntil = 7; // 今天同星期 → 下周同天
    }
    return base.add(Duration(days: daysUntil));
  }

  /// 计算下个月第 N 天（安全处理月末溢出）
  static DateTime _nextMonthDay(DateTime base, int day) {
    var year = base.year;
    var month = base.month + 1;
    if (month > 12) {
      month = 1;
      year++;
    }
    final maxDay = _daysInMonth(year, month);
    final safeDay = day > maxDay ? maxDay : day;
    return DateTime(year, month, safeDay);
  }

  /// 安全地增加月份（处理月末溢出）
  static DateTime _addMonthsSafe(DateTime base, int months) {
    var year = base.year;
    var month = base.month + months;
    while (month > 12) {
      month -= 12;
      year++;
    }
    final maxDay = _daysInMonth(year, month);
    final safeDay = base.day > maxDay ? maxDay : base.day;
    return DateTime(year, month, safeDay);
  }

  /// 某年某月的天数
  static int _daysInMonth(int year, int month) {
    if (month == 2) {
      return _isLeapYear(year) ? 29 : 28;
    }
    return [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1];
  }

  /// 闰年判断
  static bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// 创建安全的 DateTime（处理无效日期如 4月31日）
  static DateTime? _safeDateTime(int year, int month, int day, int hour, int minute) {
    try {
      if (month < 1 || month > 12) return null;
      final maxDay = _daysInMonth(year, month);
      if (day < 1 || day > maxDay) return null;
      if (hour < 0 || hour > 23) return null;
      if (minute < 0 || minute > 59) return null;
      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }
}
