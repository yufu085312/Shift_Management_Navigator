import 'package:flutter_test/flutter_test.dart';
import 'package:shift_management_navigator/models/shift_model.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

void main() {
  group('Date Filtering Logic Tests', () {
    test('Shifts within date range are included', () {
      final shifts = [
        ShiftModel(
          id: '1',
          storeId: 'store_001',
          staffId: 'staff_001',
          date: '2025-12-25',
          startTime: '09:00',
          endTime: '18:00',
          status: AppConstants.shiftStatusConfirmed,
        ),
        ShiftModel(
          id: '2',
          storeId: 'store_001',
          staffId: 'staff_001',
          date: '2025-12-30',
          startTime: '09:00',
          endTime: '18:00',
          status: AppConstants.shiftStatusConfirmed,
        ),
        ShiftModel(
          id: '3',
          storeId: 'store_001',
          staffId: 'staff_001',
          date: '2026-01-05',
          startTime: '09:00',
          endTime: '18:00',
          status: AppConstants.shiftStatusConfirmed,
        ),
      ];

      final startDate = '2025-12-20';
      final endDate = '2025-12-31';

      final filtered = shifts.where((s) {
        return s.date.compareTo(startDate) >= 0 && s.date.compareTo(endDate) <= 0;
      }).toList();

      expect(filtered.length, 2);
      expect(filtered[0].id, '1');
      expect(filtered[1].id, '2');
    });

    test('Shifts outside date range are excluded', () {
      final shifts = [
        ShiftModel(
          id: '1',
          storeId: 'store_001',
          staffId: 'staff_001',
          date: '2025-12-15',
          startTime: '09:00',
          endTime: '18:00',
          status: AppConstants.shiftStatusConfirmed,
        ),
        ShiftModel(
          id: '2',
          storeId: 'store_001',
          staffId: 'staff_001',
          date: '2026-01-10',
          startTime: '09:00',
          endTime: '18:00',
          status: AppConstants.shiftStatusConfirmed,
        ),
      ];

      final startDate = '2025-12-20';
      final endDate = '2025-12-31';

      final filtered = shifts.where((s) {
        return s.date.compareTo(startDate) >= 0 && s.date.compareTo(endDate) <= 0;
      }).toList();

      expect(filtered.length, 0);
    });

    test('Boundary dates are included', () {
      final shifts = [
        ShiftModel(
          id: '1',
          storeId: 'store_001',
          staffId: 'staff_001',
          date: '2025-12-20',
          startTime: '09:00',
          endTime: '18:00',
          status: AppConstants.shiftStatusConfirmed,
        ),
        ShiftModel(
          id: '2',
          storeId: 'store_001',
          staffId: 'staff_001',
          date: '2025-12-31',
          startTime: '09:00',
          endTime: '18:00',
          status: AppConstants.shiftStatusConfirmed,
        ),
      ];

      final startDate = '2025-12-20';
      final endDate = '2025-12-31';

      final filtered = shifts.where((s) {
        return s.date.compareTo(startDate) >= 0 && s.date.compareTo(endDate) <= 0;
      }).toList();

      expect(filtered.length, 2);
    });
  });
}
