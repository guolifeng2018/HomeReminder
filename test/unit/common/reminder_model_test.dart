import 'package:flutter_test/flutter_test.dart';
import 'package:home_reminder/src/core/common/code/models/reminder_model.dart';
import 'package:home_reminder/src/core/common/code/models/enums.dart';

void main() {
  final testDate = DateTime(2026, 6, 15, 10, 0, 0);
  final updatedDate = DateTime(2026, 6, 16, 12, 0, 0);

  group('Reminder 构造函数', () {
    test('创建带全部字段的 Reminder', () {
      final reminder = Reminder(
        id: 1,
        groupId: 2,
        title: '清洁客厅',
        content: '记得擦桌子',
        scheduledAt: testDate,
        status: ReminderStatus.pending,
        frequency: ReminderFrequency.weekly,
        createdAt: testDate,
        updatedAt: updatedDate,
      );
      expect(reminder.id, 1);
      expect(reminder.groupId, 2);
      expect(reminder.title, '清洁客厅');
      expect(reminder.content, '记得擦桌子');
      expect(reminder.scheduledAt, testDate);
      expect(reminder.status, ReminderStatus.pending);
      expect(reminder.frequency, ReminderFrequency.weekly);
      expect(reminder.createdAt, testDate);
      expect(reminder.updatedAt, updatedDate);
    });

    test('默认值：id=0, status=pending, frequency=once', () {
      final reminder = Reminder(
        groupId: 1,
        title: '测试',
        scheduledAt: testDate,
        createdAt: testDate,
      );
      expect(reminder.id, 0);
      expect(reminder.status, ReminderStatus.pending);
      expect(reminder.frequency, ReminderFrequency.once);
      expect(reminder.content, isNull);
      expect(reminder.updatedAt, isNull);
    });
  });

  group('Reminder.fromJson / toJson 往返', () {
    test('完整字段往返（含枚举序列化）', () {
      final original = Reminder(
        id: 1,
        groupId: 2,
        title: '清洁厨房',
        content: '洗碗和灶台',
        scheduledAt: testDate,
        status: ReminderStatus.overdue,
        frequency: ReminderFrequency.daily,
        createdAt: testDate,
        updatedAt: updatedDate,
      );
      final json = original.toJson();
      final restored = Reminder.fromJson(json);
      expect(restored, original);
    });

    test('空 content 和 updatedAt 往返', () {
      final original = Reminder(
        id: 1,
        groupId: 2,
        title: '测试',
        scheduledAt: testDate,
        status: ReminderStatus.completed,
        frequency: ReminderFrequency.once,
        createdAt: testDate,
      );
      final json = original.toJson();
      final restored = Reminder.fromJson(json);
      expect(restored, original);
      expect(restored.content, isNull);
      expect(restored.updatedAt, isNull);
    });

    test('枚举序列化为 name 字符串', () {
      final reminder = Reminder(
        groupId: 1,
        title: '测试',
        scheduledAt: testDate,
        status: ReminderStatus.dismissed,
        frequency: ReminderFrequency.biweekly,
        createdAt: testDate,
      );
      final json = reminder.toJson();
      expect(json['status'], 'dismissed');
      expect(json['frequency'], 'biweekly');
    });

    test('枚举反序列化从字符串', () {
      final json = <String, dynamic>{
        'group_id': 1,
        'title': '测试',
        'scheduled_at': testDate.toIso8601String(),
        'status': 'overdue',
        'frequency': 'monthly',
        'created_at': testDate.toIso8601String(),
      };
      final reminder = Reminder.fromJson(json);
      expect(reminder.status, ReminderStatus.overdue);
      expect(reminder.frequency, ReminderFrequency.monthly);
    });

    test('scheduledAt 在 JSON 中用 ISO 8601', () {
      final reminder = Reminder(
        groupId: 1,
        title: '测试',
        scheduledAt: testDate,
        createdAt: testDate,
      );
      final json = reminder.toJson();
      expect(json['scheduled_at'], testDate.toIso8601String());
    });
  });

  group('Reminder.fromMap / toMap', () {
    test('完整字段往返', () {
      final original = Reminder(
        id: 3,
        groupId: 4,
        title: '清洁卧室',
        content: '换床单',
        scheduledAt: testDate,
        status: ReminderStatus.pending,
        frequency: ReminderFrequency.weekly,
        createdAt: testDate,
        updatedAt: updatedDate,
      );
      final map = original.toMap();
      final restored = Reminder.fromMap(map);
      expect(restored, original);
    });

    test('枚举在 Map 中用 index', () {
      final reminder = Reminder(
        groupId: 1,
        title: '测试',
        scheduledAt: testDate,
        status: ReminderStatus.completed,
        frequency: ReminderFrequency.daily,
        createdAt: testDate,
      );
      final map = reminder.toMap();
      expect(map['status'], ReminderStatus.completed.index);
      expect(map['frequency'], ReminderFrequency.daily.index);
    });

    test('枚举从 Map 的 index 反序列化', () {
      final map = <String, dynamic>{
        'group_id': 1,
        'title': '测试',
        'scheduled_at': testDate.millisecondsSinceEpoch,
        'status': 2, // completed
        'frequency': 3, // biweekly
        'created_at': testDate.millisecondsSinceEpoch,
      };
      final reminder = Reminder.fromMap(map);
      expect(reminder.status, ReminderStatus.completed);
      expect(reminder.frequency, ReminderFrequency.biweekly);
    });

    test('时间字段在 Map 中用毫秒时间戳', () {
      final reminder = Reminder(
        groupId: 1,
        title: '测试',
        scheduledAt: testDate,
        createdAt: testDate,
      );
      final map = reminder.toMap();
      expect(map['scheduled_at'], testDate.millisecondsSinceEpoch);
      expect(map['created_at'], testDate.millisecondsSinceEpoch);
    });
  });

  group('Reminder.copyWith', () {
    final original = Reminder(
      id: 1,
      groupId: 2,
      title: '清洁',
      content: '原始内容',
      scheduledAt: testDate,
      status: ReminderStatus.pending,
      frequency: ReminderFrequency.once,
      createdAt: testDate,
      updatedAt: updatedDate,
    );

    test('更新 title', () {
      final updated = original.copyWith(title: '新清洁');
      expect(updated.title, '新清洁');
      expect(updated.id, original.id);
    });

    test('clearContent 清除内容', () {
      final updated = original.copyWith(clearContent: true);
      expect(updated.content, isNull);
    });

    test('clearUpdatedAt 清除更新时间', () {
      final updated = original.copyWith(clearUpdatedAt: true);
      expect(updated.updatedAt, isNull);
    });

    test('更新枚举字段', () {
      final updated = original.copyWith(
        status: ReminderStatus.completed,
        frequency: ReminderFrequency.daily,
      );
      expect(updated.status, ReminderStatus.completed);
      expect(updated.frequency, ReminderFrequency.daily);
    });
  });

  group('Reminder == / hashCode', () {
    test('相同字段 → 相等', () {
      final a = Reminder(
        groupId: 1, title: 'A', scheduledAt: testDate, createdAt: testDate,
      );
      final b = Reminder(
        groupId: 1, title: 'A', scheduledAt: testDate, createdAt: testDate,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('不同 status → 不等', () {
      final a = Reminder(
        groupId: 1, title: 'A', scheduledAt: testDate, createdAt: testDate,
        status: ReminderStatus.pending,
      );
      final b = Reminder(
        groupId: 1, title: 'A', scheduledAt: testDate, createdAt: testDate,
        status: ReminderStatus.completed,
      );
      expect(a, isNot(b));
    });
  });

  group('Reminder 序列化健壮性', () {
    test('JSON 缺失枚举字段 → 使用默认值', () {
      final json = <String, dynamic>{
        'group_id': 1,
        'title': '测试',
        'scheduled_at': testDate.toIso8601String(),
        'created_at': testDate.toIso8601String(),
      };
      final reminder = Reminder.fromJson(json);
      expect(reminder.status, ReminderStatus.pending);
      expect(reminder.frequency, ReminderFrequency.once);
    });

    test('Map 中枚举 index 越界 → clamp 到有效范围', () {
      final map = <String, dynamic>{
        'group_id': 1,
        'title': '测试',
        'scheduled_at': testDate.millisecondsSinceEpoch,
        'status': 99,
        'frequency': -1,
        'created_at': testDate.millisecondsSinceEpoch,
      };
      final reminder = Reminder.fromMap(map);
      expect(reminder.status.index, lessThanOrEqualTo(ReminderStatus.values.length - 1));
      expect(reminder.frequency.index, lessThanOrEqualTo(ReminderFrequency.values.length - 1));
    });
  });
}
