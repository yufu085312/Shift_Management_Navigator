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

  testWidgets('LoginScreen displays all UI elements', (tester) async {
    await tester.pumpWidget(createTestWidget());

    expect(find.text(AppConstants.labelAppName), findsOneWidget);
    expect(find.text(AppConstants.labelLogin), findsNWidgets(2)); // Title and Button
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email and Password
    expect(find.text(AppConstants.labelNoAccount), findsOneWidget);
  });

  testWidgets('Validation error shown if fields are empty', (tester) async {
    await tester.pumpWidget(createTestWidget());

    // Trigger validation
    await tester.tap(find.text(AppConstants.labelLogin).last);
    await tester.pump();

    expect(find.text(AppConstants.valInputEmail), findsOneWidget);
    expect(find.text(AppConstants.valInputPassword), findsOneWidget);
  });
}
