import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shift_management_navigator/repositories/auth_repository.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late AuthRepository authRepository;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    authRepository = AuthRepository(auth: mockAuth, firestore: mockFirestore);
  });

  group('AuthRepository Error Handling Tests', () {
    test('signInWithEmailAndPassword throws localized error on network-request-failed', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password',
          )).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      expect(
        () => authRepository.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password',
        ),
        throwsA(contains(AppConstants.errMsgAuth)),
      );
    });

    test('signInWithEmailAndPassword throws specialized error on invalid-credential', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password',
          )).thenThrow(FirebaseAuthException(code: 'invalid-credential'));

      expect(
        () => authRepository.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password',
        ),
        throwsA(equals('メールアドレスまたはパスワードが間違っています')),
      );
    });
  });
}
