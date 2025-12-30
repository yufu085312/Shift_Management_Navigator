import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shift_management_navigator/screens/auth/signup_screen.dart';
import 'package:shift_management_navigator/providers/auth_provider.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';
import 'package:shift_management_navigator/models/user_model.dart';

class MockAuthRepository extends Mock {}

void main() {
  testWidgets('SignupScreen show success snackbar and pops on success', (tester) async {
    // Mock signup function
    final mockSignUp = MockSignUp();
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          signUpProvider.overrideWithValue(mockSignUp.call),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                ),
                child: const Text('Open Signup'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open SignupScreen
    await tester.tap(find.text('Open Signup'));
    await tester.pumpAndSettle();

    // Fill form
    await tester.enterText(find.byType(TextFormField).at(0), 'Test User'); // Name
    await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com'); // Email
    await tester.enterText(find.byType(TextFormField).at(2), 'password123'); // Password
    await tester.enterText(find.byType(TextFormField).at(3), 'password123'); // Confirm
    await tester.pump();

    // Setup mock success
    when(() => mockSignUp.call(
      email: any(named: 'email'),
      password: any(named: 'password'),
      name: any(named: 'name'),
      role: any(named: 'role'),
    )).thenAnswer((_) async => const UserModel(
      uid: 'u1',
      name: 'Test User',
      email: 'test@example.com',
      role: 'admin',
    ));

    // Tap register
    // Increase screen size to avoid off-screen issues in test
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.ensureVisible(find.text(AppConstants.labelRegister));
    await tester.tap(find.text(AppConstants.labelRegister));
    await tester.pump(); // Start loading
    await tester.pump(); // Future completes
    await tester.pump(); // Animation/SnackBar starts

    // Verify SnackBar
    expect(find.text(AppConstants.msgSignupSuccess), findsOneWidget);

    // Wait for transition
    await tester.pumpAndSettle();

    // Verify SignupScreen is popped (we should see 'Open Signup' button again)
    expect(find.text('Open Signup'), findsOneWidget);
    expect(find.byType(SignupScreen), findsNothing);
  });
}

class MockSignUp extends Mock {
  Future<UserModel> call({
    required String email,
    required String password,
    required String name,
    required String role,
  });
}
