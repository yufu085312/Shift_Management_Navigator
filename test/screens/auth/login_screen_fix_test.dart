import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shift_management_navigator/screens/auth/login_screen.dart';
import 'package:shift_management_navigator/providers/auth_provider.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';
import 'package:shift_management_navigator/models/user_model.dart';

class MockSignIn extends Mock {
  Future<UserModel> call({
    required String email,
    required String password,
  });
}

void main() {
  testWidgets('LoginScreen shows success snackbar on success', (tester) async {
    final mockSignIn = MockSignIn();
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          signInProvider.overrideWithValue(mockSignIn.call),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Fill form
    await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.pump();

    // Setup mock success
    when(() => mockSignIn.call(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => const UserModel(
      uid: 'u1',
      name: 'Test User',
      email: 'test@example.com',
      role: 'staff',
    ));

    // Tap login
    await tester.tap(find.text(AppConstants.labelLogin).last); // Use last because title also has 'Login'
    await tester.pump(); // Start loading
    await tester.pump(); // Future completes
    await tester.pump(); // SnackBar starts

    // Verify SnackBar
    expect(find.text(AppConstants.msgLoginSuccess), findsOneWidget);
  });
}
