/// SpokenTimeParser — 口语时间解析引擎
///
/// 支持 ≥20 种中文口语时间表达→DateTime 解析。
/// 纯同步计算，不涉及 I/O 或异步操作。
///
/// 使用方式：
/// ```dart
/// final dt = SpokenTimeParser.parse('明天下午3点');
/// // 或指定参考时间：
/// final dt = SpokenTimeParser.parse('下周三', referenceDate: DateTime(2026, 6, 1));
/// ```
library;

/// 口语时间解析引擎
class SpokenTimeParser {
  SpokenTimeParser._(); // 禁止实例化

  /// 解析口语时间字符串为 [DateTime]
  ///
  /// [input] 为中文口语时间表达，如「今天下午3点」「明天早上」「下周三」等。
  /// [referenceDate] 为参考时间，默认为当前时间。
  ///
  /// 返回解析后的 [DateTime]，无法解析时返回 `null`。
  static DateTime? parse(String input, {DateTime? referenceDate}) {
    if (input.trim().isEmpty) return null;

    final ref = referenceDate ?? DateTime.now();
    final text = input.trim();

    // 按优先级尝试各类模式
    DateTime? result;

    // 1. 纯相对偏移（含具体时间）
    result = _tryRelativeOffset(text, ref);
    if (result != null) return result;

    // 2. 日期+时间组合模式
    result = _tryDateTimeCombo(text, ref);
    if (result != null) return result;

    // 3. 仅日期模式（无具体时刻，默认 09:00）
    result = _tryDateOnly(text, ref);
    if (result != null) return result;

    // 4. 仅时间模式（默认今天）
    result = _tryTimeOnly(text, ref);
    if (result != null) return result;

    // 5. 频率模式（取首次发生时间）
    result = _tryFrequency(text, ref);
    if (result != null) return result;

    return null;
  }

  // ─── 1. 纯相对偏移 ────────────────────────────────────────

  /// X分钟后 / X小时后 / 半小时后 / X天后 / X周后 / 半个月后 / 隔天
  static DateTime? _tryRelativeOffset(String text, DateTime ref) {
    // 半小时后 → +30min
    if (RegExp(r'半小时后').hasMatch(text)) {
      return ref.add(const Duration(minutes: 30));
    }

    // X分钟后
    final minutesAfter = RegExp(r'(\d+)\s*分钟后').firstMatch(text);
    if (minutesAfter != null) {
      final mins = int.parse(minutesAfter.group(1)!);
      return ref.add(Duration(minutes: mins));
    }

    // X小时后
    final hoursAfter = RegExp(r'(\d+)\s*小时后').firstMatch(text);
    if (hoursAfter != null) {
      final hrs = int.parse(hoursAfter.group(1)!);
      return ref.add(Duration(hours: hrs));
    }

    // X天后
    final daysAfter = RegExp(r'(一|两|三|四|五|六|七|八|九|十|\d+)\s*天后').firstMatch(text);
    if (daysAfter != null) {
      final days = _chineseOrDigitToInt(daysAfter.group(1)!);
      return DateTime(ref.year, ref.month, ref.day + days,
          ref.hour, ref.minute);
    }

    // 隔天 → +2天
    if (RegExp(r'隔天').hasMatch(text)) {
      return DateTime(ref.year, ref.month, ref.day + 2,
          ref.hour, ref.minute);
    }

    // 半个月后 → +15天
    if (RegExp(r'半个月后').hasMatch(text)) {
      return DateTime(ref.year, ref.month, ref.day + 15,
          ref.hour, ref.minute);
    }

    // X周后 / 一周后
    final weeksAfter = RegExp(r'(一|两|三|四|五|六|\d+)\s*周后').firstMatch(text);
    if (weeksAfter != null) {
      final w = _chineseOrDigitToInt(weeksAfter.group(1)!);
      return DateTime(ref.year, ref.month, ref.day + (w * 7),
          ref.hour, ref.minute);
    }

    return null;
  }

  // ─── 2. 日期+时间组合 ──────────────────────────────────────

  /// 今天/明天/后天 + 时间修饰（上午/下午/中午/晚上/凌晨 + 数字点/半）
  static DateTime? _tryDateTimeCombo(String text, DateTime ref) {
    int dayOffset = 0;
    bool hasDate = false;

    // 注意顺序：大后天必须在后天之前匹配，避免子串误匹配
    if (RegExp(r'大后天').hasMatch(text)) {
      dayOffset = 3;
      hasDate = true;
    } else if (RegExp(r'后天').hasMatch(text)) {
      dayOffset = 2;
      hasDate = true;
    } else if (RegExp(r'明天').hasMatch(text)) {
      dayOffset = 1;
      hasDate = true;
    } else if (RegExp(r'今天').hasMatch(text)) {
      dayOffset = 0;
      hasDate = true;
    }

    if (!hasDate) return null;

    // 提取时间
    final time = _parseTime(text);
    final hour = time?.$1 ?? 9;
    final minute = time?.$2 ?? 0;

    return DateTime(ref.year, ref.month, ref.day + dayOffset, hour, minute);
  }

  // ─── 3. 仅日期模式 ────────────────────────────────────────

  /// 下周X / 本周X / 周末 / 下周末 / 月底 / 下个月X号 / 大后天
  static DateTime? _tryDateOnly(String text, DateTime ref) {
    // 提取可能的时间修饰
    final time = _parseTime(text);
    final defaultHour = time?.$1 ?? 9;
    final defaultMinute = time?.$2 ?? 0;

    // 大后天（无时间）
    if (RegExp(r'^大后天$').hasMatch(text.trim())) {
      return DateTime(ref.year, ref.month, ref.day + 3, defaultHour, defaultMinute);
    }

    // 下周X
    final nextWeek = RegExp(r'下周(一|二|三|四|五|六|日|天|1|2|3|4|5|6|7)').firstMatch(text);
    if (nextWeek != null) {
      final targetDay = _weekdayFromChinese(nextWeek.group(1)!);
      final date = _nextWeekday(ref, targetDay, weeksAhead: 1);
      return DateTime(date.year, date.month, date.day, defaultHour, defaultMinute);
    }

    // 本周X
    final thisWeek = RegExp(r'本周(一|二|三|四|五|六|日|天|1|2|3|4|5|6|7)').firstMatch(text);
    if (thisWeek != null) {
      final targetDay = _weekdayFromChinese(thisWeek.group(1)!);
      final date = _nextWeekday(ref, targetDay, weeksAhead: 0, includeToday: true);
      return DateTime(date.year, date.month, date.day, defaultHour, defaultMinute);
    }

    // 下周末 → 下周六
    if (RegExp(r'下周末').hasMatch(text)) {
      final date = _nextWeekday(ref, DateTime.saturday, weeksAhead: 1);
      return DateTime(date.year, date.month, date.day, defaultHour, defaultMinute);
    }

    // 周末 → 本周六（若今天是周六则返回下周六）
    if (RegExp(r'^周末$').hasMatch(text.trim())) {
      final sat = _nextWeekday(ref, DateTime.saturday, weeksAhead: 0, includeToday: true);
      // 如果今天已经是周六且返回的是今天（即 includeToday 匹配了今天），
      // 且 ref 是周六，则推到下周六
      if (ref.weekday == DateTime.saturday &&
          sat.year == ref.year && sat.month == ref.month && sat.day == ref.day) {
        final nextSat = _nextWeekday(ref, DateTime.saturday, weeksAhead: 1);
        return DateTime(nextSat.year, nextSat.month, nextSat.day, defaultHour, defaultMinute);
      }
      return DateTime(sat.year, sat.month, sat.day, defaultHour, defaultMinute);
    }

    // 月底 → 本月最后一天
    if (RegExp(r'月底').hasMatch(text)) {
      final lastDay = _lastDayOfMonth(ref.year, ref.month);
      return DateTime(ref.year, ref.month, lastDay, defaultHour, defaultMinute);
    }

    // 下个月X号
    final nextMonthDay = RegExp(r'下个月\s*(\d+)\s*号?').firstMatch(text);
    if (nextMonthDay != null) {
      final day = int.parse(nextMonthDay.group(1)!);
      final nextMonth = ref.month == 12 ? 1 : ref.month + 1;
      final nextYear = ref.month == 12 ? ref.year + 1 : ref.year;
      final lastDay = _lastDayOfMonth(nextYear, nextMonth);
      final safeDay = day > lastDay ? lastDay : day;
      return DateTime(nextYear, nextMonth, safeDay, defaultHour, defaultMinute);
    }

    return null;
  }

  // ─── 4. 仅时间模式 ────────────────────────────────────────

  /// 上午X点 / 中午X点 / 下午X点 / 晚上X点 / 凌晨X点（默认今天）
  static DateTime? _tryTimeOnly(String text, DateTime ref) {
    final time = _parseTime(text);
    if (time == null) return null;

    final hour = time.$1;
    final minute = time.$2;
    return DateTime(ref.year, ref.month, ref.day, hour, minute);
  }

  // ─── 5. 频率模式 ──────────────────────────────────────────

  /// 每天早上8点 → 今天8点；每周三 → 最近周三
  static DateTime? _tryFrequency(String text, DateTime ref) {
    // 每天早上X点
    final dailyAt = RegExp(r'每天早上\s*(.*)').firstMatch(text);
    if (dailyAt != null) {
      final time = _parseTime(dailyAt.group(1)!);
      final hour = time?.$1 ?? 8;
      final minute = time?.$2 ?? 0;
      return DateTime(ref.year, ref.month, ref.day, hour, minute);
    }

    // 每周X
    final weekly = RegExp(r'每周\s*(一|二|三|四|五|六|日|天|1|2|3|4|5|6|7)').firstMatch(text);
    if (weekly != null) {
      final targetDay = _weekdayFromChinese(weekly.group(1)!);
      return _nextWeekday(ref, targetDay, weeksAhead: 0, includeToday: true);
    }

    return null;
  }

  // ─── 辅助方法 ─────────────────────────────────────────────

  /// 解析时间部分，返回 (hour, minute)
  static (int, int)? _parseTime(String text) {
    int hour = 9;
    int minute = 0;
    bool hasTimeModifier = false;
    bool hasExplicitHour = false;

    // 检测时间修饰词
    if (RegExp(r'凌晨').hasMatch(text)) {
      hour = 2; // 默认凌晨2点
      hasTimeModifier = true;
    } else if (RegExp(r'早上|早晨').hasMatch(text)) {
      hour = 8; // 默认早上8点
      hasTimeModifier = true;
    } else if (RegExp(r'上午').hasMatch(text)) {
      hour = 9;
      hasTimeModifier = true;
    } else if (RegExp(r'中午').hasMatch(text)) {
      hour = 12;
      hasTimeModifier = true;
    } else if (RegExp(r'下午').hasMatch(text)) {
      hour = 14; // 默认下午2点
      hasTimeModifier = true;
    } else if (RegExp(r'晚上|傍晚').hasMatch(text)) {
      hour = 20; // 默认晚上8点
      hasTimeModifier = true;
    }

    // 提取具体数字 + 点/时
    final hourMatch = RegExp(r'(\d{1,2})\s*[点时]').firstMatch(text);
    if (hourMatch != null) {
      final rawHour = int.parse(hourMatch.group(1)!);
      hasExplicitHour = true;

      if (RegExp(r'下午').hasMatch(text) && rawHour < 12) {
        hour = rawHour + 12;
      } else if (RegExp(r'晚上|傍晚').hasMatch(text) && rawHour < 12) {
        hour = rawHour + 12;
      } else {
        hour = rawHour;
      }

      // 凌晨特殊处理：凌晨3点 → 3
      if (RegExp(r'凌晨').hasMatch(text)) {
        hour = rawHour;
      }
    }

    // 提取分钟
    final minuteMatch = RegExp(r'(\d{1,2})\s*分').firstMatch(text);
    if (minuteMatch != null) {
      minute = int.parse(minuteMatch.group(1)!);
    }

    // 半
    if (RegExp(r'半').hasMatch(text)) {
      minute = 30;
    }

    if (!hasTimeModifier && !hasExplicitHour) return null;

    return (hour, minute);
  }

  /// 中文数字或阿拉伯数字 → int
  static int _chineseOrDigitToInt(String s) {
    const map = {
      '一': 1, '二': 2, '两': 2, '三': 3,
      '四': 4, '五': 5, '六': 6,
    };
    if (map.containsKey(s)) return map[s]!;
    return int.tryParse(s) ?? 1;
  }

  /// 中文星期 → DateTime.weekday (1=Mon, 7=Sun)
  static int _weekdayFromChinese(String s) {
    const map = {
      '一': 1, '1': 1,
      '二': 2, '2': 2,
      '三': 3, '3': 3,
      '四': 4, '4': 4,
      '五': 5, '5': 5,
      '六': 6, '6': 6,
      '日': 7, '天': 7, '7': 7,
    };
    return map[s] ?? 1;
  }

  /// 计算下一个 [targetWeekday]（1=Mon, 7=Sun）
  ///
  /// [weeksAhead] 控制提前周数：在找到下一次出现后，再追加 N 周。
  /// [includeToday] 为 true 时，如果当天就是目标星期则返回当天。
  static DateTime _nextWeekday(DateTime ref, int targetWeekday,
      {int weeksAhead = 0, bool includeToday = false}) {
    int currentWeekday = ref.weekday; // 1=Mon, 7=Sun
    int diff = targetWeekday - currentWeekday;
    bool pushedToNextWeek = false;

    if (includeToday && diff == 0) {
      diff = 0;
    } else if (diff <= 0) {
      diff += 7;
      pushedToNextWeek = true;
    }

    // 如果已推到下周，减少需追加的周数（避免 double-count）
    int extraWeeks = weeksAhead;
    if (pushedToNextWeek && extraWeeks > 0) {
      extraWeeks -= 1;
    }

    diff += extraWeeks * 7;
    return DateTime(ref.year, ref.month, ref.day + diff, 9, 0);
  }

  /// 计算某年某月的最后一天
  static int _lastDayOfMonth(int year, int month) {
    if (month == 12) {
      return 31;
    }
    // 下个月1号的前一天
    return DateTime(year, month + 1, 0).day;
  }
}
