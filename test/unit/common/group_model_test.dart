import 'package:flutter_test/flutter_test.dart';
import 'package:home_reminder/src/core/common/code/models/group_model.dart';

void main() {
  final testDate = DateTime(2026, 6, 15, 10, 0, 0);

  group('Group 构造函数', () {
    test('创建带全部字段的 Group', () {
      final group = Group(
        id: 1,
        name: '客厅',
        icon: 'living',
        isPreset: true,
        sortOrder: 0,
        createdAt: testDate,
      );
      expect(group.id, 1);
      expect(group.name, '客厅');
      expect(group.icon, 'living');
      expect(group.isPreset, true);
      expect(group.sortOrder, 0);
      expect(group.createdAt, testDate);
    });

    test('默认值：id=0, isPreset=false, sortOrder=0', () {
      final group = Group(name: '自定义', createdAt: testDate);
      expect(group.id, 0);
      expect(group.isPreset, false);
      expect(group.sortOrder, 0);
      expect(group.icon, isNull);
    });
  });

  group('Group.fromJson / toJson 往返', () {
    test('完整字段往返', () {
      final original = Group(
        id: 1,
        name: '厨房',
        icon: 'kitchen',
        isPreset: true,
        sortOrder: 2,
        createdAt: testDate,
      );
      final json = original.toJson();
      final restored = Group.fromJson(json);
      expect(restored, original);
    });

    test('空 icon 往返', () {
      final original = Group(
        id: 2,
        name: '自定义分组',
        isPreset: false,
        sortOrder: 10,
        createdAt: testDate,
      );
      final json = original.toJson();
      final restored = Group.fromJson(json);
      expect(restored, original);
      expect(restored.icon, isNull);
    });

    test('缺失字段使用默认值', () {
      final json = <String, dynamic>{
        'name': '测试',
      };
      final group = Group.fromJson(json);
      expect(group.name, '测试');
      expect(group.id, 0);
      expect(group.isPreset, false);
      expect(group.sortOrder, 0);
    });
  });

  group('Group.fromMap / toMap', () {
    test('完整字段往返', () {
      final original = Group(
        id: 3,
        name: '卧室',
        icon: 'bedroom',
        isPreset: true,
        sortOrder: 1,
        createdAt: testDate,
      );
      final map = original.toMap();
      final restored = Group.fromMap(map);
      expect(restored, original);
    });

    test('isPreset 在 Map 中用 1/0 表示', () {
      final group = Group(name: '测试', isPreset: true, createdAt: testDate);
      final map = group.toMap();
      expect(map['is_preset'], 1);
    });

    test('createdAt 在 Map 中用毫秒时间戳', () {
      final group = Group(name: '测试', createdAt: testDate);
      final map = group.toMap();
      expect(map['created_at'], testDate.millisecondsSinceEpoch);
    });

    test('id=0 时不在 Map 中', () {
      final group = Group(name: '新分组', createdAt: testDate);
      final map = group.toMap();
      expect(map.containsKey('id'), isFalse);
    });
  });

  group('Group.copyWith', () {
    final original = Group(
      id: 1,
      name: '客厅',
      icon: 'living',
      isPreset: true,
      sortOrder: 0,
      createdAt: testDate,
    );

    test('部分更新 name', () {
      final updated = original.copyWith(name: '主卧');
      expect(updated.name, '主卧');
      expect(updated.id, original.id);
      expect(updated.icon, original.icon);
    });

    test('clearIcon 清除图标', () {
      final updated = original.copyWith(clearIcon: true);
      expect(updated.icon, isNull);
    });

    test('不传参数保持原值', () {
      final updated = original.copyWith();
      expect(updated, original);
    });
  });

  group('Group == / hashCode', () {
    test('相同字段 → 相等', () {
      final a = Group(id: 1, name: 'A', createdAt: testDate);
      final b = Group(id: 1, name: 'A', createdAt: testDate);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('不同字段 → 不等', () {
      final a = Group(id: 1, name: 'A', createdAt: testDate);
      final b = Group(id: 2, name: 'A', createdAt: testDate);
      expect(a, isNot(b));
    });

    test('null icon 相等', () {
      final a = Group(id: 1, name: 'A', createdAt: testDate);
      final b = Group(id: 1, name: 'A', createdAt: testDate);
      expect(a, b);
    });
  });

  group('Group.toString', () {
    test('包含关键字段', () {
      final group = Group(id: 1, name: '客厅', createdAt: testDate);
      final str = group.toString();
      expect(str, contains('Group'));
      expect(str, contains('客厅'));
    });
  });

  group('Group 序列化健壮性', () {
    test('JSON 中 id 为 double → 转为 int', () {
      final json = <String, dynamic>{
        'id': 1.0,
        'name': '测试',
      };
      final group = Group.fromJson(json);
      expect(group.id, 1);
    });

    test('JSON 中 id 为字符串 → 解析', () {
      final json = <String, dynamic>{
        'id': '5',
        'name': '测试',
      };
      final group = Group.fromJson(json);
      expect(group.id, 5);
    });

    test('is_preset 为 1 → true', () {
      final json = <String, dynamic>{
        'name': '测试',
        'is_preset': 1,
      };
      final group = Group.fromJson(json);
      expect(group.isPreset, true);
    });

    test('createdAt 为毫秒时间戳 → 正确解析', () {
      final ts = testDate.millisecondsSinceEpoch;
      final map = <String, dynamic>{
        'name': '测试',
        'created_at': ts,
      };
      final group = Group.fromMap(map);
      expect(group.createdAt.millisecondsSinceEpoch, ts);
    });
  });
}
