import 'package:flutter_test/flutter_test.dart';
import '../../../src/core/common/code/utils/string_sanitizer.dart';

void main() {
  group('StringSanitizer.sanitize', () {
    test('null → 空字符串', () {
      expect(StringSanitizer.sanitize(null), equals(''));
    });

    test('空字符串 → 空字符串', () {
      expect(StringSanitizer.sanitize(''), equals(''));
    });

    test('纯空白 → 空字符串', () {
      expect(StringSanitizer.sanitize('   \t  \n  '), equals(''));
    });

    test('trim 首尾空白', () {
      expect(StringSanitizer.sanitize('  hello  '), equals('hello'));
    });

    test('连续空格合并为单个空格', () {
      expect(StringSanitizer.sanitize('hello    world'), equals('hello world'));
    });

    test('连续空白（tab、换行、多空格）合并为单个空格', () {
      expect(
        StringSanitizer.sanitize('hello\t\t\n\n  world'),
        equals('hello world'),
      );
    });

    test('保留正常文本', () {
      expect(StringSanitizer.sanitize('客厅清洁'), equals('客厅清洁'));
    });

    test('移除控制字符（0x00-0x1F，换行除外）', () {
      // 0x01 (SOH), 0x7F (DEL) are control chars
      const input = 'hello\x01\x7F world';
      expect(StringSanitizer.sanitize(input), equals('hello world'));
    });

    test('保留换行符但被合并为空格', () {
      // 换行被 \s+ 正则合并为空格
      expect(StringSanitizer.sanitize('line1\nline2'), equals('line1 line2'));
    });

    test('移除零宽字符', () {
      // U+200B zero-width space
      const input = 'he\u200Bllo\u200C world\uFEFF';
      expect(StringSanitizer.sanitize(input), equals('hello world'));
    });

    test('超长字符串截断（默认 500）', () {
      final long = 'a' * 600;
      final result = StringSanitizer.sanitize(long);
      expect(result.length, equals(500));
      expect(result, equals('a' * 500));
    });

    test('自定义 maxLength 截断', () {
      final long = 'hello world';
      final result = StringSanitizer.sanitize(long, maxLength: 5);
      expect(result.length, equals(5));
      expect(result, equals('hello'));
    });

    test('截断后 trim 尾部空白', () {
      // 500 'a' + spaces → sanitize: trim → 'a'*500 (already trimmed)
      final long = 'a' * 500 + '   ';
      final result = StringSanitizer.sanitize(long);
      expect(result.length, equals(500));
      expect(result, equals('a' * 500));
    });

    test('恰好等于 maxLength → 不截断', () {
      final exact = 'a' * 500;
      final result = StringSanitizer.sanitize(exact);
      expect(result.length, equals(500));
      expect(result, equals(exact));
    });

    test('控制字符和零宽字符混合', () {
      const input = '\x01he\u200Bllo\x02 \x7Fworld\uFEFF!';
      expect(StringSanitizer.sanitize(input), equals('hello world!'));
    });
  });

  group('StringSanitizer.isEmpty / isNotEmpty', () {
    test('null → isEmpty true', () {
      expect(StringSanitizer.isEmpty(null), isTrue);
    });

    test('空字符串 → isEmpty true', () {
      expect(StringSanitizer.isEmpty(''), isTrue);
    });

    test('纯空白 → isEmpty true', () {
      expect(StringSanitizer.isEmpty('   '), isTrue);
    });

    test('非空字符串 → isEmpty false', () {
      expect(StringSanitizer.isEmpty('hello'), isFalse);
    });

    test('isNotEmpty 与 isEmpty 相反', () {
      expect(StringSanitizer.isNotEmpty(null), isFalse);
      expect(StringSanitizer.isNotEmpty(''), isFalse);
      expect(StringSanitizer.isNotEmpty('   '), isFalse);
      expect(StringSanitizer.isNotEmpty('hello'), isTrue);
    });
  });

  group('StringSanitizer.isTooLong', () {
    test('null → false', () {
      expect(StringSanitizer.isTooLong(null), isFalse);
    });

    test('未超长 → false', () {
      expect(StringSanitizer.isTooLong('a' * 500), isFalse);
      expect(StringSanitizer.isTooLong('a' * 100), isFalse);
    });

    test('超长 → true', () {
      expect(StringSanitizer.isTooLong('a' * 501), isTrue);
    });

    test('自定义 maxLength', () {
      expect(StringSanitizer.isTooLong('abcde', maxLength: 5), isFalse);
      expect(StringSanitizer.isTooLong('abcdef', maxLength: 5), isTrue);
    });
  });

  group('StringSanitizer.truncate', () {
    test('null → 空字符串', () {
      expect(StringSanitizer.truncate(null), equals(''));
    });

    test('未超长 → 原样返回', () {
      expect(StringSanitizer.truncate('hello'), equals('hello'));
    });

    test('超长 → 截断', () {
      expect(StringSanitizer.truncate('hello world', maxLength: 5), equals('hello'));
    });
  });
}
