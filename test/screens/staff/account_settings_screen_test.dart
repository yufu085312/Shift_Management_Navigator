import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shift_management_navigator/screens/staff/account_settings_screen.dart';
import 'package:shift_management_navigator/providers/auth_provider.dart';
import 'package:shift_management_navigator/providers/staff_provider.dart';
import 'package:shift_management_navigator/repositories/auth_repository.dart';
import 'package:shift_management_navigator/repositories/staff_repository.dart';
import 'package:shift_management_navigator/models/user_model.dart';
import 'package:shift_management_navigator/models/staff_model.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockStaffRepository extends Mock implements StaffRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockStaffRepository mockStaffRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockStaffRepository = MockStaffRepository();
  });

  Widget createTestWidget({UserModel? user, StaffModel? staff}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        staffRepositoryProvider.overrideWithValue(mockStaffRepository),
        currentUserProvider.overrideWith((ref) => user),
        currentStaffProvider.overrideWith((ref) => staff),
      ],
      child: const MaterialApp(
        home: AccountSettingsScreen(),
      ),
    );
  }

  testWidgets('AccountSettingsScreen displays current name and updates', (tester) async {
    final mockUser = UserModel(uid: 'u1', name: 'Old Name', email: 'u1@ex.com', role: AppConstants.roleStaff, storeId: 's1');
    final mockStaff = StaffModel(id: 'st1', userId: 'u1', storeId: 's1', name: 'Old Name');

    when(() => mockAuthRepository.updateUserData(
      uid: any(named: 'uid'),
      name: any(named: 'name'),
    )).thenAnswer((_) async => {});

    when(() => mockStaffRepository.updateStaff(
      staffId: any(named: 'staffId'),
      name: any(named: 'name'),
    )).thenAnswer((_) async => {});

    await tester.pumpWidget(createTestWidget(user: mockUser, staff: mockStaff));
    await tester.pumpAndSettle();

    // 初期値の確認
    expect(find.text('Old Name'), findsOneWidget);

    // 名前を編集
    await tester.enterText(find.byType(TextFormField), 'New Name');
    
    // 保存ボタンをタップ
    await tester.tap(find.text(AppConstants.labelUpdate));
    
    // 非同期処理とスナックバーの初期表示を待つ
    await tester.pump(); 
    
    // リポジトリが呼ばれたことを確認 (非同期なので pump の後に検証)
    verify(() => mockAuthRepository.updateUserData(
      uid: 'u1',
      name: 'New Name',
    )).called(1);

    verify(() => mockStaffRepository.updateStaff(
      staffId: 'st1',
      name: 'New Name',
    )).called(1);

    // スナックバーの表示確認
    expect(find.text(AppConstants.msgUpdateComplete), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
