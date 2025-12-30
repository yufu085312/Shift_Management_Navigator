import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shift_management_navigator/screens/staff/change_request_screen.dart';
import 'package:shift_management_navigator/providers/staff_provider.dart';
import 'package:shift_management_navigator/providers/shift_provider.dart';
import 'package:shift_management_navigator/repositories/staff_repository.dart';
import 'package:shift_management_navigator/repositories/shift_repository.dart';
import 'package:shift_management_navigator/models/staff_model.dart';
import 'package:shift_management_navigator/models/shift_model.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

class MockStaffRepository extends Mock implements StaffRepository {}
class MockShiftRepository extends Mock implements ShiftRepository {}

void main() {
  late MockStaffRepository mockStaffRepository;
  late MockShiftRepository mockShiftRepository;

  setUp(() {
    mockStaffRepository = MockStaffRepository();
    mockShiftRepository = MockShiftRepository();
  });

  Widget createTestWidget() {
    final mockStaff = StaffModel(
      id: 'staff_001',
      userId: 'user_001',
      storeId: 'store_001',
      name: 'Test Staff',
    );

    final mockShifts = [
      ShiftModel(
        id: 'shift_001',
        storeId: 'store_001',
        staffId: 'staff_001',
        date: '2025-12-30',
        startTime: '09:00',
        endTime: '18:00',
        status: AppConstants.shiftStatusConfirmed,
      ),
    ];

    when(() => mockShiftRepository.getShiftsByStaffAndDateRange(
      staffId: any(named: 'staffId'),
      storeId: any(named: 'storeId'),
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
    )).thenAnswer((_) async => mockShifts);

    return ProviderScope(
      overrides: [
        staffRepositoryProvider.overrideWithValue(mockStaffRepository),
        shiftRepositoryProvider.overrideWithValue(mockShiftRepository),
        currentStaffProvider.overrideWith((ref) async => mockStaff),
      ],
      child: const MaterialApp(
        home: ChangeRequestScreen(),
      ),
    );
  }

  testWidgets('ChangeRequestScreen displays request type options', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    expect(find.text(AppConstants.labelChangeTime), findsOneWidget);
    expect(find.text(AppConstants.labelSubstituteWish), findsOneWidget);
  });
}
