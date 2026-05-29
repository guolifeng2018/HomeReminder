import 'package:flutter_test/flutter_test.dart';
import '../../../src/core/common/code/permissions/permission_manager.dart';
import '../../../src/core/common/code/permissions/permission_manager_stub.dart';

void main() {
  group('PermissionType', () {
    test('枚举值数量为 3', () {
      expect(PermissionType.values.length, equals(3));
    });

    test('包含 microphone、notification、storage', () {
      final names = PermissionType.values.map((e) => e.name).toSet();
      expect(names, containsAll(['microphone', 'notification', 'storage']));
    });
  });

  group('PermissionStatus', () {
    test('枚举值数量为 5', () {
      expect(PermissionStatus.values.length, equals(5));
    });

    test('包含 granted、denied、permanentlyDenied、restricted、unknown', () {
      final names = PermissionStatus.values.map((e) => e.name).toSet();
      expect(
        names,
        containsAll([
          'granted',
          'denied',
          'permanentlyDenied',
          'restricted',
          'unknown',
        ]),
      );
    });

    test('isGranted → granted 为 true，其余为 false', () {
      expect(PermissionStatus.granted.isGranted, isTrue);
      expect(PermissionStatus.denied.isGranted, isFalse);
      expect(PermissionStatus.permanentlyDenied.isGranted, isFalse);
      expect(PermissionStatus.restricted.isGranted, isFalse);
      expect(PermissionStatus.unknown.isGranted, isFalse);
    });

    test('shouldOpenSettings → permanentlyDenied/restricted 为 true', () {
      expect(PermissionStatus.granted.shouldOpenSettings, isFalse);
      expect(PermissionStatus.denied.shouldOpenSettings, isFalse);
      expect(PermissionStatus.permanentlyDenied.shouldOpenSettings, isTrue);
      expect(PermissionStatus.restricted.shouldOpenSettings, isTrue);
      expect(PermissionStatus.unknown.shouldOpenSettings, isFalse);
    });
  });

  group('PermissionManagerStub', () {
    late PermissionManager manager;

    setUp(() {
      manager = PermissionManagerStub();
    });

    test('checkPermission 对所有类型返回 granted', () async {
      for (final type in PermissionType.values) {
        final status = await manager.checkPermission(type);
        expect(status, PermissionStatus.granted);
      }
    });

    test('requestPermission 对所有类型返回 granted', () async {
      for (final type in PermissionType.values) {
        final status = await manager.requestPermission(type);
        expect(status, PermissionStatus.granted);
      }
    });

    test('openSettings 返回 true', () async {
      final result = await manager.openSettings();
      expect(result, isTrue);
    });

    test('Stub 是 PermissionManager 的子类型', () {
      expect(manager, isA<PermissionManager>());
    });
  });
}
