import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_reminder/src/core/common/code/models/enums.dart';
import 'package:home_reminder/src/core/common/code/models/reminder_model.dart';
import 'package:home_reminder/src/core/database/code/reminder_repository.dart';
import 'package:home_reminder/src/core/reminder/code/reminder_service_impl.dart';
import 'package:home_reminder/src/core/reminder/code/postpone_logic.dart';

class MockReminderRepository extends Mock implements ReminderRepository {}

void main() {
  late MockReminderRepository mockRepo;
  late ReminderServiceImpl service;

  Reminder _fakeReminder({
    int id = 1,
    int groupId = 1,
    String title = '测试提醒',
    String? content,
    DateTime? scheduledAt,
    ReminderStatus status = ReminderStatus.pending,
    ReminderFrequency frequency = ReminderFrequency.once,
  }) {
    return Reminder(
      id: id,
      groupId: groupId,
      title: title,
      content: content,
      scheduledAt: scheduledAt ?? DateTime(2026, 6, 1, 10, 0),
      status: status,
      frequency: frequency,
      createdAt: DateTime(2026, 6, 1),
    );
  }

  setUp(() {
    mockRepo = MockReminderRepository();
    service = ReminderServiceImpl(reminderRepo: mockRepo);
    registerFallbackValue(_fakeReminder());
  });

  group('ReminderServiceImpl — createReminder', () {
    test('正常创建 → 调用 repo.insert', () async {
      when(() => mockRepo.insert(any())).thenAnswer(
          (_) async => _fakeReminder(id: 42));

      final result = await service.createReminder(
        groupId: 1,
        title: '买菜',
        scheduledAt: DateTime(2026, 6, 5, 10, 0),
      );

      expect(result.id, 42);
      verify(() => mockRepo.insert(any())).called(1);
    });

    test('groupId=0 抛出 ArgumentError', () async {
      expect(
        () => service.createReminder(
          groupId: 0,
          title: '买菜',
          scheduledAt: DateTime(2026, 6, 5),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('title 为空抛出 ArgumentError', () async {
      expect(
        () => service.createReminder(
          groupId: 1,
          title: '',
          scheduledAt: DateTime(2026, 6, 5),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('内容为空字符串时正常创建', () async {
      when(() => mockRepo.insert(any())).thenAnswer(
          (_) async => _fakeReminder());

      final result = await service.createReminder(
        groupId: 1,
        title: 'title',
        scheduledAt: DateTime(2026, 6, 5),
        content: '',
      );

      expect(result.title, '测试提醒');
    });
  });

  group('ReminderServiceImpl — postponeReminder', () {
    test('推迟到明天 → 调用 getById + update', () async {
      final reminder = _fakeReminder();
      when(() => mockRepo.getById(1)).thenAnswer((_) async => reminder);
      when(() => mockRepo.update(any())).thenAnswer((_) async {});

      await service.postponeReminder(1, PostponePreset.tomorrow);

      verify(() => mockRepo.getById(1)).called(1);
      verify(() => mockRepo.update(any())).called(1);
    });

    test('提醒不存在 → 静默返回', () async {
      when(() => mockRepo.getById(999)).thenAnswer((_) async => null);

      await service.postponeReminder(999, PostponePreset.oneHour);

      verify(() => mockRepo.getById(999)).called(1);
      verifyNever(() => mockRepo.update(any()));
    });
  });

  group('ReminderServiceImpl — checkOverdue', () {
    test('委托 scheduler.findOverdue', () async {
      when(() => mockRepo.getOverdue()).thenAnswer((_) async => [
            _fakeReminder(id: 1),
          ]);
      when(() => mockRepo.update(any())).thenAnswer((_) async {});

      final count = await service.checkOverdue();

      expect(count, 1);
      verify(() => mockRepo.getOverdue()).called(1);
      verify(() => mockRepo.update(any())).called(1);
    });

    test('无过期提醒返回 0', () async {
      when(() => mockRepo.getOverdue()).thenAnswer((_) async => []);

      final count = await service.checkOverdue();

      expect(count, 0);
      verifyNever(() => mockRepo.update(any()));
    });
  });

  group('ReminderServiceImpl — cancelReminder', () {
    test('取消 → 状态变 dismissed', () async {
      final reminder = _fakeReminder(status: ReminderStatus.pending);
      when(() => mockRepo.getById(1)).thenAnswer((_) async => reminder);
      when(() => mockRepo.update(any())).thenAnswer((_) async {});

      await service.cancelReminder(1);

      verify(() => mockRepo.update(any())).called(1);
    });
  });

  group('ReminderServiceImpl — parseTime / getNextRetryTime', () {
    test('parseTime 返回 DateTime', () {
      final result = service.parseTime('明天', referenceDate: DateTime(2026, 6, 1));
      expect(result, isNotNull);
      expect(result!.day, 2);
    });

    test('getNextRetryTime 返回正确间隔', () {
      final result = service.getNextRetryTime(1, DateTime(2026, 6, 1, 10, 0));
      expect(result, DateTime(2026, 6, 1, 10, 5));
    });
  });
}
