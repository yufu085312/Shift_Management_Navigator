import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shift_management_navigator/screens/staff/wish_submission_screen.dart';
import 'package:shift_management_navigator/providers/auth_provider.dart';
import 'package:shift_management_navigator/providers/staff_provider.dart';
import 'package:shift_management_navigator/providers/shift_request_provider.dart';
import 'package:shift_management_navigator/repositories/shift_request_repository.dart';
import 'package:shift_management_navigator/repositories/auth_repository.dart';
import 'package:shift_management_navigator/models/user_model.dart';
import 'package:shift_management_navigator/models/staff_model.dart';
import 'package:shift_management_navigator/models/shift_request_model.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockShiftRequestRepository extends Mock implements ShiftRequestRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockShiftRequestRepository mockShiftRequestRepository;

  setUpAll(() async {
    registerFallbackValue(const AsyncValue<UserModel?>.loading());
    await initializeDateFormatting('ja_JP');
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockShiftRequestRepository = MockShiftRequestRepository();
  });

  group('WishSubmissionScreen Integration Interaction Tests', () {
    testWidgets('Full flow: select date, enter reason, and submit', (tester) async {
      final mockUser = UserModel(
        uid: 'staff_001',
        name: 'Staff User',
        email: 'staff@example.com',
        role: AppConstants.roleStaff,
        storeId: 'store_001',
      );

      final mockStaff = StaffModel(
        id: 's1',
        userId: 'staff_001',
        storeId: 'store_001',
        name: 'Staff User',
      );

      when(() => mockShiftRequestRepository.createRequest(
        storeId: any(named: 'storeId'),
        staffId: any(named: 'staffId'),
        type: any(named: 'type'),
        date: any(named: 'date'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        reason: any(named: 'reason'),
      )).thenAnswer((_) async => ShiftRequestModel(
        id: 'r1',
        storeId: 'store_001',
        staffId: 's1',
        type: AppConstants.requestTypeWish,
        date: '2025-01-01',
        status: AppConstants.requestStatusPending,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
            shiftRequestRepositoryProvider.overrideWithValue(mockShiftRequestRepository),
            currentUserProvider.overrideWith((ref) => mockUser),
            currentStaffProvider.overrideWith((ref) => mockStaff),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WishSubmissionScreen()),
                  ),
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      // 1. Select a future day in TableCalendar
      // Today is Dec 30, so 31 should be visible.
      await tester.tap(find.text('31').first);
      await tester.pumpAndSettle();

      // 2. Enter reason
      await tester.enterText(find.byType(TextField), 'Test Reason');
      await tester.pump();

      // 3. Submit
      // Increase screen size to avoid off-screen issues in test
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.ensureVisible(find.text(AppConstants.labelSubmit));
      await tester.tap(find.text(AppConstants.labelSubmit));
      await tester.pump(); // Start loading
      
      // Wait for repository call and navigation
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Verify repository was called
      verify(() => mockShiftRequestRepository.createRequest(
        storeId: 'store_001',
        staffId: 's1',
        type: AppConstants.requestTypeWish,
        date: any(named: 'date'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        reason: 'Test Reason',
      )).called(1);

      // Verify success message - SnackBar might need a bit of time to be fully visible
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining(AppConstants.msgRequestSubmitted), findsOneWidget);
    });
  });
}
