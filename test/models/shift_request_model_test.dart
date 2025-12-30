import 'package:flutter_test/flutter_test.dart';
import 'package:shift_management_navigator/models/shift_request_model.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

void main() {
  group('ShiftRequestModel Tests', () {
    test('fromJson should return a valid ShiftRequestModel', () {
      final json = {
        'id': 'req_id',
        'storeId': 'store_001',
        'staffId': 'staff_001',
        'type': AppConstants.requestTypeWish,
        'date': '2025-12-30',
        'startTime': '10:00',
        'endTime': '15:00',
        'status': AppConstants.requestStatusPending,
      };

      final request = ShiftRequestModel.fromJson(json);

      expect(request.id, 'req_id');
      expect(request.storeId, 'store_001');
      expect(request.staffId, 'staff_001');
      expect(request.type, AppConstants.requestTypeWish);
      expect(request.date, '2025-12-30');
      expect(request.startTime, '10:00');
      expect(request.endTime, '15:00');
      expect(request.status, AppConstants.requestStatusPending);
    });

    test('toJson should return a valid JSON map', () {
      final request = ShiftRequestModel(
        id: 'req_id',
        storeId: 'store_001',
        staffId: 'staff_001',
        type: AppConstants.requestTypeSubstitute,
        date: '2025-12-31',
        status: AppConstants.requestStatusApproved,
      );

      final json = request.toJson();

      expect(json['id'], 'req_id');
      expect(json['storeId'], 'store_001');
      expect(json['staffId'], 'staff_001');
      expect(json['type'], AppConstants.requestTypeSubstitute);
      expect(json['date'], '2025-12-31');
      expect(json['status'], AppConstants.requestStatusApproved);
    });
  });
}
