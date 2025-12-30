import 'package:flutter_test/flutter_test.dart';
import 'package:shift_management_navigator/models/shift_model.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

void main() {
  group('ShiftModel Tests', () {
    test('fromJson should return a valid ShiftModel', () {
      final json = {
        'id': 'test_id',
        'storeId': 'store_001',
        'staffId': 'staff_001',
        'date': '2025-12-30',
        'startTime': '09:00',
        'endTime': '18:00',
        'status': AppConstants.shiftStatusConfirmed,
      };

      final shift = ShiftModel.fromJson(json);

      expect(shift.id, 'test_id');
      expect(shift.storeId, 'store_001');
      expect(shift.staffId, 'staff_001');
      expect(shift.date, '2025-12-30');
      expect(shift.startTime, '09:00');
      expect(shift.endTime, '18:00');
      expect(shift.status, AppConstants.shiftStatusConfirmed);
    });

    test('toJson should return a valid JSON map', () {
      final shift = ShiftModel(
        id: 'test_id',
        storeId: 'store_001',
        staffId: 'staff_001',
        date: '2025-12-30',
        startTime: '09:00',
        endTime: '18:00',
        status: AppConstants.shiftStatusDraft,
      );

      final json = shift.toJson();

      expect(json['id'], 'test_id');
      expect(json['storeId'], 'store_001');
      expect(json['staffId'], 'staff_001');
      expect(json['date'], '2025-12-30');
      expect(json['startTime'], '09:00');
      expect(json['endTime'], '18:00');
      expect(json['status'], AppConstants.shiftStatusDraft);
    });
  });
}
