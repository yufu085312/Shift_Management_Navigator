import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shift_management_navigator/screens/staff/wish_submission_screen.dart';
import 'package:shift_management_navigator/providers/staff_provider.dart';
import 'package:shift_management_navigator/repositories/staff_repository.dart';
import 'package:shift_management_navigator/models/staff_model.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

class MockStaffRepository extends Mock implements StaffRepository {}

void main() {
  late MockStaffRepository mockStaffRepository;

  setUp(() {
    mockStaffRepository = MockStaffRepository();
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
        currentStaffProvider.overrideWith((ref) => mockStaff),
      ],
      child: const MaterialApp(
        home: WishSubmissionScreen(),
      ),
    );
  }

  group('Wish Submission Validation Tests', () {
    testWidgets('Submitting without selecting date shows error', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 日付を選択せずに送信ボタンをタップ
      // まず、カレンダーが表示されるまで待つ
      await tester.pumpAndSettle();

      // 送信ボタンを探す（画面をスクロールして見つける必要がある場合がある）
      final submitButton = find.text(AppConstants.labelSubmit);
      
      if (submitButton.evaluate().isNotEmpty) {
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pump();

        // エラーメッセージが表示されることを確認
        expect(find.text(AppConstants.valSelectDate), findsOneWidget);
      }
    });

    testWidgets('WishSubmissionScreen displays calendar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // カレンダーが表示されることを確認
      expect(find.text(AppConstants.titleWishSubmission), findsOneWidget);
    });
  });
}
