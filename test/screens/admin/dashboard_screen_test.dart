import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shift_management_navigator/screens/admin/dashboard_screen.dart';
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
class MockUserModel extends Mock implements UserModel {}
class MockStoreModel extends Mock implements StoreModel {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    registerFallbackValue(const AsyncValue<UserModel?>.loading());
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('AdminDashboardScreen Tests', () {
    testWidgets('Dashboard displays store info and navigation items', (tester) async {
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
        plan: AppConstants.planFree,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
            currentUserProvider.overrideWith((ref) => mockUser),
            storeProvider.overrideWith((ref, _) => mockStore),
            storeStaffsProvider.overrideWith((ref, _) => []),
            storeShiftsProvider.overrideWith((ref, _) => []),
            storeRequestsProvider.overrideWith((ref, _) => []),
          ],
          child: const MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for title
      expect(find.text(AppConstants.titleAdminDashboard), findsOneWidget);
      
      // Check for store name
      expect(find.text('Test Store'), findsOneWidget);
      
      // Check for navigation cards (using their titles)
      // Note: We need to see what the titles are in the dashboard_screen.dart
      // Based on my view of the code, I'll check for common labels.
      expect(find.text(AppConstants.labelDashboardMenuStaff), findsOneWidget);
      expect(find.text(AppConstants.labelDashboardMenuRequest), findsOneWidget);

      // Check for logout button in AppBar
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('Displays error when no store is linked', (tester) async {
      final mockUser = UserModel(
        uid: 'admin_001',
        name: 'Admin User',
        email: 'admin@example.com',
        role: AppConstants.roleAdmin,
        storeId: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
          child: const MaterialApp(
            home: AdminDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(AppConstants.errMsgNoStore), findsOneWidget);
    });
  });
}
