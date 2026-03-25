import 'package:carotid_check/core/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole', () {
    test('fromString parses role names case-insensitively', () {
      expect(UserRole.fromString('chw'), UserRole.chw);
      expect(UserRole.fromString('CHW'), UserRole.chw);
      expect(UserRole.fromString('clinician'), UserRole.clinician);
      expect(UserRole.fromString('Clinician'), UserRole.clinician);
      expect(UserRole.fromString('admin'), UserRole.admin);
    });

    test('fromString defaults unknown values to chw', () {
      expect(UserRole.fromString('unknown'), UserRole.chw);
      expect(UserRole.fromString(''), UserRole.chw);
    });

    test('level and getters', () {
      expect(UserRole.chw.level, 1);
      expect(UserRole.clinician.level, 2);
      expect(UserRole.admin.level, 3);
      expect(UserRole.chw.isChw, isTrue);
      expect(UserRole.chw.isClinician, isFalse);
      expect(UserRole.clinician.isClinician, isTrue);
      expect(UserRole.admin.isAdmin, isTrue);
    });
  });
}
