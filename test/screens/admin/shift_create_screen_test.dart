import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shift_management_navigator/screens/admin/shift_create_screen.dart';
import 'package:shift_management_navigator/providers/auth_provider.dart';
import 'package:shift_management_navigator/providers/store_provider.dart';
import 'package:shift_management_navigator/providers/staff_provider.dart';
import 'package:shift_management_navigator/providers/shift_provider.dart';
import 'package:shift_management_navigator/providers/shift_request_provider.dart';
import 'package:shift_management_navigator/models/user_model.dart';
import 'package:shift_management_navigator/models/store_model.dart';
import 'package:shift_management_navigator/models/staff_model.dart';
import 'package:shift_management_navigator/models/shift_model.dart';
import 'package:shift_management_navigator/models/shift_request_model.dart';
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

  group('ShiftCreateScreen Tests', () {
    testWidgets('Displays calendar and basic UI', (tester) async {
      final mockUser = UserModel(
        uid: 'admin_001',
        name: 'Admin User',
        email: 'admin@example.com',
        role: AppConstants.roleAdmin,
        storeId: 'store_001',
      );

      final mockStore = StoreModel(
        id: 'store_001',
        name: 'Test Store',
        ownerId: 'admin_001',
      );

      final mockStaff = StaffModel(id: 's1', userId: 'u1', storeId: 'store_001', name: 'Staff A');
      final mockStaffUser = UserModel(uid: 'u1', name: 'Staff A', email: 'u1@ex.com', role: AppConstants.roleStaff, storeId: 'store_001');
      when(() => mockAuthRepository.getUserData('u1')).thenAnswer((_) async => mockStaffUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
            currentUserProvider.overrideWith((ref) => mockUser),
            storeProvider.overrideWith((ref, _) => mockStore),
            storeStaffsProvider.overrideWith((ref, _) => [mockStaff]),
            storeShiftsProvider.overrideWith((ref, _) => []),
            storeRequestsProvider.overrideWith((ref, _) => []),
          ],
          child: const MaterialApp(
            home: ShiftCreateScreen(),
          ),
        ),
      );

      // TableCalendar might have some animations or async loading internally
      await tester.pump();
      
      // If we see loading indicator, pump again
      if (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
        await tester.pump(const Duration(seconds: 1));
      }

      expect(find.text(AppConstants.titleShiftCreate), findsOneWidget);
      expect(find.byWidgetPredicate((widget) => widget.runtimeType.toString().contains('TableCalendar')), findsWidgets);
    });
  });
}
