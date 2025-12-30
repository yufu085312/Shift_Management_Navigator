import 'package:flutter_test/flutter_test.dart';
import 'package:shift_management_navigator/models/shift_request_model.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

void main() {
  group('Status Transition Logic Tests', () {
    test('Request status can transition from pending to approved', () {
      final request = ShiftRequestModel(
        id: 'req_001',
        storeId: 'store_001',
        staffId: 'staff_001',
        type: AppConstants.requestTypeWish,
        date: '2025-12-30',
        status: AppConstants.requestStatusPending,
      );

      expect(request.status, AppConstants.requestStatusPending);

      // ステータス更新をシミュレート
      final updatedRequest = request.copyWith(
        status: AppConstants.requestStatusApproved,
      );

      expect(updatedRequest.status, AppConstants.requestStatusApproved);
    });

    test('Request status can transition from pending to rejected', () {
      final request = ShiftRequestModel(
        id: 'req_001',
        storeId: 'store_001',
        staffId: 'staff_001',
        type: AppConstants.requestTypeWish,
        date: '2025-12-30',
        status: AppConstants.requestStatusPending,
      );

      final updatedRequest = request.copyWith(
        status: AppConstants.requestStatusRejected,
      );

      expect(updatedRequest.status, AppConstants.requestStatusRejected);
    });

    test('Volunteer staff ID can be added to substitute request', () {
      final request = ShiftRequestModel(
        id: 'req_001',
        storeId: 'store_001',
        staffId: 'staff_001',
        type: AppConstants.requestTypeSubstitute,
        date: '2025-12-30',
        status: AppConstants.requestStatusPending,
      );

      expect(request.volunteerStaffId, null);

      final updatedRequest = request.copyWith(
        volunteerStaffId: 'staff_002',
      );

      expect(updatedRequest.volunteerStaffId, 'staff_002');
    });
  });
}
