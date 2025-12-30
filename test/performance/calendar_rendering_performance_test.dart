import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shift_management_navigator/screens/admin/shift_create_screen.dart';
import 'package:shift_management_navigator/providers/auth_provider.dart';
import 'package:shift_management_navigator/providers/store_provider.dart';
import 'package:shift_management_navigator/providers/staff_provider.dart';
import 'package:shift_management_navigator/providers/shift_provider.dart';
import 'package:shift_management_navigator/providers/shift_request_provider.dart';
import 'package:shift_management_navigator/models/user_model.dart';
import 'package:shift_management_navigator/models/store_model.dart';
import 'package:shift_management_navigator/models/shift_model.dart';
import 'package:shift_management_navigator/repositories/auth_repository.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUpAll(() async {
    registerFallbackValue(const AsyncValue<UserModel?>.loading());
    await initializeDateFormatting('ja_JP');
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('Performance Tests - ShiftCreateScreen Calendar', () {
    testWidgets('Renders calendar with 100+ shifts without crashing', (tester) async {
      final mockUser = UserModel(
        uid: 'admin_001',
        name: 'Admin User',
        email: 'admin@example.com',
        role: AppConstants.roleAdmin,
        storeId: 'store_001',
      );

      // Create 100 shifts
      final mockShifts = List.generate(100, (i) => ShiftModel(
        id: 'shift_$i',
        storeId: 'store_001',
        staffId: 'staff_${i % 10}',
        date: '2025-12-${(i % 28) + 1}'.padLeft(10, '0'),
        startTime: '09:00',
        endTime: '18:00',
        status: AppConstants.shiftStatusConfirmed,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
            currentUserProvider.overrideWith((ref) => mockUser),
            storeProvider.overrideWith((ref, _) => StoreModel(id: 'store_001', name: 'Test Store', ownerId: 'admin_001')),
            storeStaffsProvider.overrideWith((ref, _) => []),
            storeShiftsProvider.overrideWith((ref, _) => mockShifts),
            storeRequestsProvider.overrideWith((ref, _) => []),
          ],
          child: const MaterialApp(
            home: ShiftCreateScreen(),
          ),
        ),
      );

      final watch = Stopwatch()..start();
      await tester.pumpAndSettle();
      watch.stop();

      print('Calendar with 100 shifts rendered in: ${watch.elapsedMilliseconds}ms');
      
      expect(find.text(AppConstants.titleShiftCreate), findsOneWidget);
      // Ensure we don't have massive lag (threshold 2s for test environment)
      expect(watch.elapsedMilliseconds, lessThan(2000));
    });
  });
}
