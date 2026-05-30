import 'package:flutter_test/flutter_test.dart';
import 'package:home_reminder/src/core/notification/code/notification_payload_handler.dart';

void main() {
  group('NotificationPayloadHandler.encodePayload', () {
    test('should encode reminderId as JSON string', () {
      expect(NotificationPayloadHandler.encodePayload(42),
          '{"reminder_id":42}');
    });

    test('should encode zero correctly', () {
      expect(NotificationPayloadHandler.encodePayload(0),
          '{"reminder_id":0}');
    });

    test('should encode large int correctly', () {
      expect(NotificationPayloadHandler.encodePayload(999999),
          '{"reminder_id":999999}');
    });
  });

  group('NotificationPayloadHandler.decodePayload', () {
    test('should decode valid payload', () {
      final result =
          NotificationPayloadHandler.decodePayload('{"reminder_id":42}');
      expect(result, 42);
    });

    test('should return null for null payload', () {
      expect(NotificationPayloadHandler.decodePayload(null), isNull);
    });

    test('should return null for empty string payload', () {
      expect(NotificationPayloadHandler.decodePayload(''), isNull);
    });

    test('should return null for invalid JSON', () {
      expect(
          NotificationPayloadHandler.decodePayload('not-json'), isNull);
    });

    test('should return null for JSON without reminder_id key', () {
      expect(
          NotificationPayloadHandler.decodePayload('{"other":1}'), isNull);
    });

    test('should return null for JSON array (not object)', () {
      expect(NotificationPayloadHandler.decodePayload('[1,2,3]'), isNull);
    });

    test('should handle reminder_id as double', () {
      expect(NotificationPayloadHandler.decodePayload(
          '{"reminder_id":42.0}'), 42);
    });

    test('should handle reminder_id as string', () {
      expect(NotificationPayloadHandler.decodePayload(
          '{"reminder_id":"99"}'), 99);
    });

    test('should return null for non-numeric string reminder_id', () {
      expect(NotificationPayloadHandler.decodePayload(
          '{"reminder_id":"abc"}'), isNull);
    });

    test('should return null for boolean reminder_id', () {
      expect(NotificationPayloadHandler.decodePayload(
          '{"reminder_id":true}'), isNull);
    });
  });
}
