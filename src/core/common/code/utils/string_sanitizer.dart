/// 字符串清洗工具
///
/// 处理用户输入中的空白、控制字符、特殊字符和超长字符串。
/// 确保数据库存储和 UI 展示的安全性。
library;

/// 字符串清洗工具类
class StringSanitizer {
  StringSanitizer._();

  /// 默认最大长度
  static const int defaultMaxLength = 500;

  /// 清洗输入字符串
  ///
  /// [input] 待清洗字符串（可为 null）。
  /// [maxLength] 最大允许长度，默认 500。超过则截断。
  ///
  /// 处理流程：
  /// 1. null → 空字符串
  /// 2. trim 首尾空白
  /// 3. 移除零宽字符
  /// 4. 移除控制字符（保留换行）
  /// 5. 连续空白合并为单个空格
  /// 6. 截断超长字符串
  static String sanitize(String? input, {int maxLength = defaultMaxLength}) {
    if (input == null) return '';

    var result = input;

    // 1. trim 首尾空白
    result = result.trim();

    // 2. 如果 trim 后为空，直接返回
    if (result.isEmpty) return '';

    // 3. 移除零宽字符（必须在合并空白前，避免 U+FEFF 被 \s 匹配为空格）
    result = result.replaceAll(
      RegExp('[\u200B\u200C\u200D\uFEFF]'),
      '',
    );

    // 4. 移除控制字符（0x00-0x1F, 0x7F-0x9F），保留换行符 \n (0x0A)
    result = result.replaceAll(
      RegExp(r'[\x00-\x09\x0B\x0C\x0E-\x1F\x7F-\x9F]'),
      '',
    );

    // 5. 连续空白合并为单个空格
    result = result.replaceAll(RegExp(r'\s+'), ' ');

    // 6. trim again after removing control/zero-width chars
    result = result.trim();
    if (result.isEmpty) return '';

    // 7. 截断超长字符串
    if (result.length > maxLength) {
      result = result.substring(0, maxLength).trimRight();
    }

    return result;
  }

  /// 判断输入是否为空（null、空字符串或纯空白）
  static bool isEmpty(String? input) {
    if (input == null) return true;
    return input.trim().isEmpty;
  }

  /// 判断输入是否非空
  static bool isNotEmpty(String? input) {
    return !isEmpty(input);
  }

  /// 判断字符串是否超过指定长度
  static bool isTooLong(String? input, {int maxLength = defaultMaxLength}) {
    if (input == null) return false;
    return input.length > maxLength;
  }

  /// 安全截断字符串（保留完整 UTF-16 字符）
  static String truncate(String? input, {int maxLength = defaultMaxLength}) {
    if (input == null) return '';
    if (input.length <= maxLength) return input;
    return input.substring(0, maxLength);
  }
}
