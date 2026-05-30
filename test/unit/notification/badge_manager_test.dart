import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_reminder/src/core/notification/code/badge_manager.dart';

class MockBadgeOperator extends Mock implements BadgeOperator {}

void main() {
  late MockBadgeOperator mockOperator;
  late BadgeManager badgeManager;

  setUp(() {
    mockOperator = MockBadgeOperator();
    badgeManager = BadgeManager(badgeOperator: mockOperator);
  });

  group('BadgeManager.calculateBadge', () {
    test('should return 0 when both counts are 0', () {
      expect(badgeManager.calculateBadge(0, 0), 0);
    });

    test('should return pending + overdue total', () {
      expect(badgeManager.calculateBadge(3, 2), 5);
    });

    test('should return only pending when overdue is 0', () {
      expect(badgeManager.calculateBadge(5, 0), 5);
    });

    test('should return only overdue when pending is 0', () {
      expect(badgeManager.calculateBadge(0, 3), 3);
    });

    test('should cap at maxBadgeCount (99)', () {
      expect(badgeManager.calculateBadge(60, 50), 99);
      expect(badgeManager.calculateBadge(100, 0), 99);
      expect(badgeManager.calculateBadge(0, 100), 99);
    });

    test('should treat negative pending as 0', () {
      expect(badgeManager.calculateBadge(-1, 0), 0);
      expect(badgeManager.calculateBadge(-5, 3), 3);
    });

    test('should treat negative overdue as 0', () {
      expect(badgeManager.calculateBadge(0, -1), 0);
      expect(badgeManager.calculateBadge(3, -5), 3);
    });

    test('should return 0 when both are negative', () {
      expect(badgeManager.calculateBadge(-1, -2), 0);
    });
  });

  group('BadgeManager.updateBadge', () {
    test('should remove badge when count is 0', () async {
      when(() => mockOperator.removeBadge()).thenAnswer((_) async {});

      await badgeManager.updateBadge(0, 0);

      verify(() => mockOperator.removeBadge()).called(1);
      verifyNever(() => mockOperator.updateBadgeCount(any()));
    });

    test('should update badge count when count > 0', () async {
      when(() => mockOperator.updateBadgeCount(3))
          .thenAnswer((_) async {});

      await badgeManager.updateBadge(1, 2);

      verify(() => mockOperator.updateBadgeCount(3)).called(1);
      verifyNever(() => mockOperator.removeBadge());
    });

    test('should cap badge at maxBadgeCount when updating', () async {
      when(() => mockOperator.updateBadgeCount(99))
          .thenAnswer((_) async {});

      await badgeManager.updateBadge(60, 50);

      verify(() => mockOperator.updateBadgeCount(99)).called(1);
      verifyNever(() => mockOperator.removeBadge());
    });

    test('should not throw on operator failure', () async {
      when(() => mockOperator.removeBadge())
          .thenThrow(Exception('Badge not supported'));

      // should not throw
      await badgeManager.updateBadge(0, 0);
    });
  });
}
