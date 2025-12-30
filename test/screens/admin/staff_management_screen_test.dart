import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shift_management_navigator/screens/admin/staff_management_screen.dart';
import 'package:shift_management_navigator/providers/auth_provider.dart';
import 'package:shift_management_navigator/providers/staff_provider.dart';
import 'package:shift_management_navigator/providers/store_provider.dart';
import 'package:shift_management_navigator/models/user_model.dart';
import 'package:shift_management_navigator/models/store_model.dart';
import 'package:shift_management_navigator/models/staff_model.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

import 'package:mocktail/mocktail.dart';
import 'package:shift_management_navigator/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('StaffManagementScreen Tests', () {
    testWidgets('Displays staff list and store info', (tester) async {
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

      final mockStaffs = [
        StaffModel(id: 's1', userId: 'u1', storeId: 'store_001', name: 'Staff A'),
        StaffModel(id: 's2', userId: 'u2', storeId: 'store_001', name: 'Staff B'),
      ];

      final mockStaffUserA = UserModel(uid: 'u1', name: 'Staff A', email: 'u1@ex.com', role: AppConstants.roleStaff, storeId: 'store_001');
      final mockStaffUserB = UserModel(uid: 'u2', name: 'Staff B', email: 'u2@ex.com', role: AppConstants.roleStaff, storeId: 'store_001');

      when(() => mockAuthRepository.getUserData('u1')).thenAnswer((_) async => mockStaffUserA);
      when(() => mockAuthRepository.getUserData('u2')).thenAnswer((_) async => mockStaffUserB);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
            currentUserProvider.overrideWith((ref) => mockUser),
            storeProvider('store_001').overrideWith((ref) => mockStore),
            storeStaffsProvider('store_001').overrideWith((ref) => mockStaffs),
            staffCountProvider('store_001').overrideWith((ref) => 2),
          ],
          child: const MaterialApp(
            home: StaffManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(AppConstants.titleStaffManagement), findsOneWidget);
      expect(find.text('Test Store'), findsOneWidget);
      expect(find.text('Staff A'), findsOneWidget);
      expect(find.text('Staff B'), findsOneWidget);
      // 管理者ラベルが表示されていないことを確認 (スタッフA, Bは一般スタッフのため)
      expect(find.text(AppConstants.labelManager), findsNothing);
    });

    testWidgets('Displays admin register card when admin is not in staff list', (tester) async {
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
            currentUserProvider.overrideWith((ref) => mockUser),
            storeProvider('store_001').overrideWith((ref) => mockStore),
            storeStaffsProvider('store_001').overrideWith((ref) => []),
            staffCountProvider('store_001').overrideWith((ref) => 0),
          ],
          child: const MaterialApp(
            home: StaffManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(AppConstants.msgAdminRegisterPrompt), findsOneWidget);
      expect(find.text(AppConstants.labelRegisterSelfAsStaff), findsOneWidget);
    });
  });
}
