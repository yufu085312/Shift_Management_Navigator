import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shift_management_navigator/screens/staff/my_shift_screen.dart';
import 'package:shift_management_navigator/providers/staff_provider.dart';
import 'package:shift_management_navigator/providers/shift_provider.dart';
import 'package:shift_management_navigator/providers/shift_request_provider.dart';
import 'package:shift_management_navigator/repositories/staff_repository.dart';
import 'package:shift_management_navigator/repositories/shift_repository.dart';
import 'package:shift_management_navigator/repositories/shift_request_repository.dart';
import 'package:shift_management_navigator/models/staff_model.dart';
import 'package:shift_management_navigator/models/shift_model.dart';
import 'package:shift_management_navigator/models/shift_request_model.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

class MockStaffRepository extends Mock implements StaffRepository {}
class MockShiftRepository extends Mock implements ShiftRepository {}
class MockShiftRequestRepository extends Mock implements ShiftRequestRepository {}

void main() {
  late MockStaffRepository mockStaffRepository;
  late MockShiftRepository mockShiftRepository;
  late MockShiftRequestRepository mockShiftRequestRepository;

  setUp(() {
    mockStaffRepository = MockStaffRepository();
    mockShiftRepository = MockShiftRepository();
    mockShiftRequestRepository = MockShiftRequestRepository();
  });

  Widget createTestWidget() {
    final mockStaff = StaffModel(
      id: 'staff_001',
      userId: 'user_001',
      storeId: 'store_001',
      name: 'Test Staff',
    );

    return ProviderScope(
      overrides: [
        staffRepositoryProvider.overrideWithValue(mockStaffRepository),
        shiftRepositoryProvider.overrideWithValue(mockShiftRepository),
        shiftRequestRepositoryProvider.overrideWithValue(mockShiftRequestRepository),
        currentStaffProvider.overrideWith((ref) async => mockStaff),
      ],
      child: const MaterialApp(
        home: MyShiftScreen(),
      ),
    );
  }

  testWidgets('MyShiftScreen displays app bar title', (tester) async {
    when(() => mockShiftRepository.getShiftsByStaffAndDateRange(
      staffId: any(named: 'staffId'),
      storeId: any(named: 'storeId'),
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
    )).thenAnswer((_) async => []);

    when(() => mockShiftRequestRepository.getRequestsByStaffOrVolunteer(
      any(),
      any(),
    )).thenAnswer((_) async => []);

    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    expect(find.text(AppConstants.titleMyShift), findsOneWidget);
  });
}
