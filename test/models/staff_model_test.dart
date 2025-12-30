import 'package:flutter_test/flutter_test.dart';
import 'package:shift_management_navigator/models/staff_model.dart';

void main() {
  group('StaffModel Tests', () {
    test('fromJson should return a valid StaffModel', () {
      final json = {
        'id': 'staff_001',
        'userId': 'user_001',
        'storeId': 'store_001',
        'name': 'Test Staff',
        'hourlyWage': 1200,
        'isActive': true,
      };

      final staff = StaffModel.fromJson(json);

      expect(staff.id, 'staff_001');
      expect(staff.userId, 'user_001');
      expect(staff.storeId, 'store_001');
      expect(staff.name, 'Test Staff');
      expect(staff.hourlyWage, 1200);
      expect(staff.isActive, true);
    });

    test('toJson should return a valid JSON map', () {
      final staff = StaffModel(
        id: 'staff_001',
        userId: 'user_001',
        storeId: 'store_001',
        name: 'Test Staff',
        hourlyWage: 1500,
        isActive: false,
      );

      final json = staff.toJson();

      expect(json['id'], 'staff_001');
      expect(json['userId'], 'user_001');
      expect(json['storeId'], 'store_001');
      expect(json['name'], 'Test Staff');
      expect(json['hourlyWage'], 1500);
      expect(json['isActive'], false);
    });

    test('StaffModel with default values should work', () {
      final staff = StaffModel(
        id: 'staff_002',
        userId: 'user_002',
        storeId: 'store_001',
        name: 'New Staff',
      );

      expect(staff.hourlyWage, 0);
      expect(staff.isActive, true);
    });
  });
}
