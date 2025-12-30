import 'package:flutter_test/flutter_test.dart';
import 'package:shift_management_navigator/models/store_model.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

void main() {
  group('StoreModel Tests', () {
    test('fromJson should return a valid StoreModel', () {
      final json = {
        'id': 'store_001',
        'name': 'Test Store',
        'ownerId': 'owner_001',
        'plan': AppConstants.planBasic,
        'shiftUnitMinutes': 15,
        'weekStart': 1,
      };

      final store = StoreModel.fromJson(json);

      expect(store.id, 'store_001');
      expect(store.name, 'Test Store');
      expect(store.ownerId, 'owner_001');
      expect(store.plan, AppConstants.planBasic);
      expect(store.shiftUnitMinutes, 15);
      expect(store.weekStart, 1);
    });

    test('toJson should return a valid JSON map', () {
      final store = StoreModel(
        id: 'store_001',
        name: 'Test Store',
        ownerId: 'owner_001',
        plan: AppConstants.planPro,
      );

      final json = store.toJson();

      expect(json['id'], 'store_001');
      expect(json['name'], 'Test Store');
      expect(json['ownerId'], 'owner_001');
      expect(json['plan'], AppConstants.planPro);
    });

    test('StoreModel with default values should work', () {
      final store = StoreModel(
        id: 'store_002',
        name: 'New Store',
        ownerId: 'owner_002',
      );

      expect(store.plan, AppConstants.planFree);
      expect(store.shiftUnitMinutes, 30);
      expect(store.weekStart, 0);
      expect(store.businessHours, {});
    });
  });
}
