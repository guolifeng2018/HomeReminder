import 'package:flutter_test/flutter_test.dart';
import '../../../src/core/common/code/models/enums.dart';

void main() {
  group('ReminderStatus', () {
    test('枚举值数量为 4', () {
      expect(ReminderStatus.values.length, equals(4));
    });

    test('包含 pending、overdue、completed、dismissed', () {
      final names = ReminderStatus.values.map((e) => e.name).toSet();
      expect(
        names,
        containsAll(['pending', 'overdue', 'completed', 'dismissed']),
      );
    });

    test('index 值按声明顺序', () {
      expect(ReminderStatus.pending.index, 0);
      expect(ReminderStatus.overdue.index, 1);
      expect(ReminderStatus.completed.index, 2);
      expect(ReminderStatus.dismissed.index, 3);
    });

    group('fromString', () {
      test('精确匹配', () {
        expect(ReminderStatus.fromString('pending'), ReminderStatus.pending);
        expect(ReminderStatus.fromString('overdue'), ReminderStatus.overdue);
        expect(ReminderStatus.fromString('completed'), ReminderStatus.completed);
        expect(ReminderStatus.fromString('dismissed'), ReminderStatus.dismissed);
      });

      test('大小写不敏感', () {
        expect(ReminderStatus.fromString('PENDING'), ReminderStatus.pending);
        expect(ReminderStatus.fromString('Pending'), ReminderStatus.pending);
        expect(ReminderStatus.fromString('COMPLETED'), ReminderStatus.completed);
      });

      test('前后空白容错', () {
        expect(ReminderStatus.fromString('  pending  '), ReminderStatus.pending);
      });

      test('未知字符串返回默认值 pending', () {
        expect(ReminderStatus.fromString('unknown_status'), ReminderStatus.pending);
      });

      test('空字符串返回 pending', () {
        expect(ReminderStatus.fromString(''), ReminderStatus.pending);
      });
    });

    group('displayName', () {
      test('中文显示名称', () {
        expect(ReminderStatus.pending.displayName, '待处理');
        expect(ReminderStatus.overdue.displayName, '已过期');
        expect(ReminderStatus.completed.displayName, '已完成');
        expect(ReminderStatus.dismissed.displayName, '已忽略');
      });
    });
  });

  group('ReminderFrequency', () {
    test('枚举值数量为 5', () {
      expect(ReminderFrequency.values.length, equals(5));
    });

    test('包含 once、daily、weekly、biweekly、monthly', () {
      final names = ReminderFrequency.values.map((e) => e.name).toSet();
      expect(
        names,
        containsAll(['once', 'daily', 'weekly', 'biweekly', 'monthly']),
      );
    });

    test('index 值按声明顺序', () {
      expect(ReminderFrequency.once.index, 0);
      expect(ReminderFrequency.daily.index, 1);
      expect(ReminderFrequency.weekly.index, 2);
      expect(ReminderFrequency.biweekly.index, 3);
      expect(ReminderFrequency.monthly.index, 4);
    });

    group('fromString', () {
      test('精确匹配', () {
        expect(ReminderFrequency.fromString('once'), ReminderFrequency.once);
        expect(ReminderFrequency.fromString('daily'), ReminderFrequency.daily);
        expect(ReminderFrequency.fromString('weekly'), ReminderFrequency.weekly);
        expect(ReminderFrequency.fromString('biweekly'), ReminderFrequency.biweekly);
        expect(ReminderFrequency.fromString('monthly'), ReminderFrequency.monthly);
      });

      test('大小写不敏感', () {
        expect(ReminderFrequency.fromString('ONCE'), ReminderFrequency.once);
        expect(ReminderFrequency.fromString('Daily'), ReminderFrequency.daily);
      });

      test('前后空白容错', () {
        expect(ReminderFrequency.fromString('  weekly  '), ReminderFrequency.weekly);
      });

      test('未知字符串返回默认值 once', () {
        expect(ReminderFrequency.fromString('yearly'), ReminderFrequency.once);
      });

      test('空字符串返回 once', () {
        expect(ReminderFrequency.fromString(''), ReminderFrequency.once);
      });
    });

    group('displayName', () {
      test('中文显示名称', () {
        expect(ReminderFrequency.once.displayName, '一次性');
        expect(ReminderFrequency.daily.displayName, '每天');
        expect(ReminderFrequency.weekly.displayName, '每周');
        expect(ReminderFrequency.biweekly.displayName, '隔周');
        expect(ReminderFrequency.monthly.displayName, '每月');
      });
    });
  });
}
