import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shift_management_navigator/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end test', () {
    testWidgets('Verify login screen loads', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify that we are on the login screen
      // Assuming AppConstants.labelLogin is used in the button
      expect(find.text('ログイン'), findsWidgets);
    });
  });
}
