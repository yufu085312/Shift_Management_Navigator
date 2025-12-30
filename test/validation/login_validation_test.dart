import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shift_management_navigator/screens/auth/login_screen.dart';
import 'package:shift_management_navigator/providers/auth_provider.dart';
import 'package:shift_management_navigator/repositories/auth_repository.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('Login Validation Tests', () {
    testWidgets('Empty email shows validation error', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // パスワードのみ入力
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );

      // ログインボタンをタップ
      await tester.tap(find.text(AppConstants.labelLogin).last);
      await tester.pump();

      // エラーメッセージが表示されることを確認
      expect(find.text(AppConstants.valInputEmail), findsOneWidget);
    });

    testWidgets('Invalid email format shows validation error', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // 無効なメールアドレスを入力
      await tester.enterText(
        find.byType(TextFormField).first,
        'invalid-email',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );

      // ログインボタンをタップ
      await tester.tap(find.text(AppConstants.labelLogin).last);
      await tester.pump();

      // エラーメッセージが表示されることを確認
      expect(find.text(AppConstants.valInvalidEmail), findsOneWidget);
    });

    testWidgets('Empty password shows validation error', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // メールアドレスのみ入力
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );

      // ログインボタンをタップ
      await tester.tap(find.text(AppConstants.labelLogin).last);
      await tester.pump();

      // エラーメッセージが表示されることを確認
      expect(find.text(AppConstants.valInputPassword), findsOneWidget);
    });

    testWidgets('Both fields empty shows both validation errors', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // ログインボタンをタップ（何も入力せず）
      await tester.tap(find.text(AppConstants.labelLogin).last);
      await tester.pump();

      // 両方のエラーメッセージが表示されることを確認
      expect(find.text(AppConstants.valInputEmail), findsOneWidget);
      expect(find.text(AppConstants.valInputPassword), findsOneWidget);
    });
  });
}
