import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';

// AuthRepositoryのプロバイダー
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// 認証状態の変更を監視するプロバイダー
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

// 現在のユーザー情報を取得するプロバイダー
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  final user = authRepository.currentUser;
  
  if (user == null) return null;
  
  return await authRepository.getUserData(user.uid);
});

// ログイン処理のプロバイダー
final signInProvider = Provider<Future<UserModel> Function({
  required String email,
  required String password,
})>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return ({required String email, required String password}) {
    return authRepository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  };
});

// 新規登録処理のプロバイダー
final signUpProvider = Provider<Future<UserModel> Function({
  required String email,
  required String password,
  required String name,
  required String role,
})>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return ({
    required String email,
    required String password,
    required String name,
    required String role,
  }) {
    return authRepository.signUpWithEmailAndPassword(
      email: email,
      password: password,
      name: name,
      role: role,
    );
  };
});

// ログアウト処理のプロバイダー
final signOutProvider = Provider<Future<void> Function()>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return () => authRepository.signOut();
});
