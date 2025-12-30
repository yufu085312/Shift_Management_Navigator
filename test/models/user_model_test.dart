import 'package:flutter_test/flutter_test.dart';
import 'package:shift_management_navigator/models/user_model.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

void main() {
  group('UserModel Tests', () {
    test('fromJson should return a valid UserModel', () {
      final json = {
        'uid': 'user_001',
        'name': 'Test User',
        'email': 'test@example.com',
        'role': AppConstants.roleAdmin,
        'storeId': 'store_001',
      };

      final user = UserModel.fromJson(json);

      expect(user.uid, 'user_001');
      expect(user.name, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.role, AppConstants.roleAdmin);
      expect(user.storeId, 'store_001');
    });

    test('toJson should return a valid JSON map', () {
      final user = UserModel(
        uid: 'user_001',
        name: 'Test User',
        email: 'test@example.com',
        role: AppConstants.roleStaff,
      );

      final json = user.toJson();

      expect(json['uid'], 'user_001');
      expect(json['name'], 'Test User');
      expect(json['email'], 'test@example.com');
      expect(json['role'], AppConstants.roleStaff);
    });

    test('UserModel without storeId should work', () {
      final user = UserModel(
        uid: 'user_002',
        name: 'New User',
        email: 'new@example.com',
        role: AppConstants.roleStaff,
      );

      expect(user.storeId, null);
    });
  });
}
