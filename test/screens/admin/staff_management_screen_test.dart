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
import 'package:shift_management_navigator/repositories/staff_repository.dart';

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
            userDataProvider('u1').overrideWith((ref) async => mockStaffUserA),
            userDataProvider('u2').overrideWith((ref) async => mockStaffUserB),
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

    testWidgets('Syncs user data when admin updates staff name', (tester) async {
      final mockUser = UserModel(uid: 'admin_001', name: 'Admin', email: 'a@ex.com', role: AppConstants.roleAdmin, storeId: 'store_001');
      final mockStaff = StaffModel(id: 's1', userId: 'u1', storeId: 'store_001', name: 'Old Name');
      final mockStore = StoreModel(id: 'store_001', name: 'Store', ownerId: 'admin_001');

      final mockStaffRepository = MockStaffRepository();
      registerFallbackValue(mockStaff);

      when(() => mockAuthRepository.getUserData('u1')).thenAnswer((_) async => UserModel(uid: 'u1', name: 'Old Name', email: 'u1@ex.com', role: AppConstants.roleStaff, storeId: 'store_001'));
      when(() => mockStaffRepository.updateStaff(
        staffId: any(named: 'staffId'),
        name: any(named: 'name'),
        hourlyWage: any(named: 'hourlyWage'),
      )).thenAnswer((_) async => {});
      when(() => mockAuthRepository.updateUserData(
        uid: any(named: 'uid'),
        name: any(named: 'name'),
      )).thenAnswer((_) async => {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
            staffRepositoryProvider.overrideWithValue(mockStaffRepository),
            currentUserProvider.overrideWith((ref) => mockUser),
            storeProvider('store_001').overrideWith((ref) => mockStore),
            storeStaffsProvider('store_001').overrideWith((ref) => [mockStaff]),
            staffCountProvider('store_001').overrideWith((ref) => 1),
            userDataProvider('u1').overrideWith((ref) async => UserModel(uid: 'u1', name: 'Old Name', email: 'u1@ex.com', role: AppConstants.roleStaff, storeId: 'store_001')),
          ],
          child: const MaterialApp(
            home: StaffManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // FutureProvider の完了を待つ
      await tester.pump(const Duration(milliseconds: 100));

      final staffItem = find.text('Old Name');
      expect(staffItem, findsOneWidget);
      
      // 編集ボタンをタップ
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'New Name');
      await tester.tap(find.text(AppConstants.labelUpdate));
      await tester.pumpAndSettle();

      // StaffRepository と AuthRepository の両方が呼ばれたことを確認
      verify(() => mockStaffRepository.updateStaff(
        staffId: 's1',
        name: 'New Name',
        hourlyWage: any(named: 'hourlyWage'),
      )).called(1);
      
      verify(() => mockAuthRepository.updateUserData(
        uid: 'u1',
        name: 'New Name',
      )).called(1);
    });
  });
}

class MockStaffRepository extends Mock implements StaffRepository {}
