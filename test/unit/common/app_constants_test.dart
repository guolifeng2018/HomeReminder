import 'package:flutter_test/flutter_test.dart';
import '../../../src/core/common/code/constants/app_constants.dart';

void main() {
  group('app_constants', () {
    test('APP_NAME 非空', () {
      expect(appName, isNotEmpty);
      expect(appName, '居净清单');
    });

    test('dateTimeFormat 格式正确', () {
      expect(dateTimeFormat, 'yyyy-MM-dd HH:mm');
    });

    test('dateFormat 格式正确', () {
      expect(dateFormat, 'yyyy-MM-dd');
    });

    test('timeFormat 格式正确', () {
      expect(timeFormat, 'HH:mm');
    });

    test('displayDateFormat 格式正确', () {
      expect(displayDateFormat, contains('年'));
      expect(displayDateFormat, contains('月'));
      expect(displayDateFormat, contains('日'));
    });

    test('weekdayFormat 格式正确', () {
      expect(weekdayFormat, 'EEEE');
    });
  });

  group('defaultGroups', () {
    test('预设分组数量为 6', () {
      expect(defaultGroups.length, equals(6));
    });

    test('每组包含必要字段', () {
      for (final group in defaultGroups) {
        expect(group.containsKey('id'), isTrue);
        expect(group.containsKey('name'), isTrue);
        expect(group.containsKey('icon'), isTrue);
        expect(group.containsKey('is_preset'), isTrue);
        expect(group.containsKey('sort_order'), isTrue);
      }
    });

    test('所有分组 is_preset 为 true', () {
      for (final group in defaultGroups) {
        expect(group['is_preset'], isTrue);
      }
    });

    test('分组 ID 唯一（1-6）', () {
      final ids = defaultGroups.map((g) => g['id']).toSet();
      expect(ids.length, 6);
      for (int i = 1; i <= 6; i++) {
        expect(ids.contains(i), isTrue);
      }
    });

    test('分组名称正确', () {
      final names = defaultGroups.map((g) => g['name'] as String).toList();
      expect(names, ['客厅', '卧室', '厨房', '冰箱', '扫地机', '地面']);
    });

    test('每组有非空图标标识', () {
      for (final group in defaultGroups) {
        expect(group['icon'], isNotNull);
        expect(group['icon'], isNotEmpty);
      }
    });

    test('sort_order 递增 0-5', () {
      for (int i = 0; i < defaultGroups.length; i++) {
        expect(defaultGroups[i]['sort_order'], i);
      }
    });
  });
}
