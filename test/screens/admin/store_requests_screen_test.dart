import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shift_management_navigator/screens/admin/store_requests_screen.dart';
import 'package:shift_management_navigator/providers/auth_provider.dart';
import 'package:shift_management_navigator/providers/shift_request_provider.dart';
import 'package:shift_management_navigator/providers/staff_provider.dart';
import 'package:shift_management_navigator/models/user_model.dart';
import 'package:shift_management_navigator/models/shift_request_model.dart';
import 'package:shift_management_navigator/models/staff_model.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

void main() {
  group('StoreRequestsScreen Tests', () {
    testWidgets('Displays requests list', (tester) async {
      final mockUser = UserModel(
        uid: 'admin_001',
        name: 'Admin User',
        email: 'admin@example.com',
        role: AppConstants.roleAdmin,
        storeId: 'store_001',
      );

      final mockStaff = StaffModel(
        id: 's1',
        userId: 'u1',
        storeId: 'store_001',
        name: 'Staff A',
      );

      final mockRequests = [
        ShiftRequestModel(
          id: 'r1',
          storeId: 'store_001',
          staffId: 's1',
          type: AppConstants.requestTypeWish,
          date: '2025-12-30',
          status: AppConstants.requestStatusPending,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            storeRequestsProvider('store_001').overrideWith((ref) => mockRequests),
            storeStaffsProvider('store_001').overrideWith((ref) => [mockStaff]),
          ],
          child: const MaterialApp(
            home: StoreRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(AppConstants.titleShiftRequestList), findsOneWidget);
      expect(find.textContaining('Staff A'), findsOneWidget);
      expect(find.textContaining(AppConstants.labelShiftWish), findsOneWidget);
    });

    testWidgets('Displays empty message when no requests', (tester) async {
      final mockUser = UserModel(
        uid: 'admin_001',
        name: 'Admin User',
        email: 'admin@example.com',
        role: AppConstants.roleAdmin,
        storeId: 'store_001',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
            storeRequestsProvider('store_001').overrideWith((ref) => []),
            storeStaffsProvider('store_001').overrideWith((ref) => []),
          ],
          child: const MaterialApp(
            home: StoreRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(AppConstants.msgNoPendingRequests), findsOneWidget);
    });
  });
}
