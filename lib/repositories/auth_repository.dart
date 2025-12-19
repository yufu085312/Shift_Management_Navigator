import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 現在のユーザーを取得
  User? get currentUser => _auth.currentUser;

  // 認証状態の変更を監視
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // メール/パスワードでログイン
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        throw Exception('ユーザー情報が見つかりません');
      }

      return UserModel.fromFirestore(userDoc);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // メール/パスワードで新規登録
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final now = DateTime.now();

      final userModel = UserModel(
        uid: uid,
        name: name,
        email: email,
        role: role,
        createdAt: now,
      );

      // Firestoreにユーザー情報を保存
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'role': role,
        'createdAt': Timestamp.fromDate(now),
      });

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ログアウト
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ユーザー情報を取得
  Future<UserModel?> getUserData(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return null;
      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      return null;
    }
  }

  // ユーザー情報を更新
  Future<void> updateUserData({
    required String uid,
    String? name,
    String? storeId,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (storeId != null) updates['storeId'] = storeId;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }

  // 店舗の特定のロールのユーザー一覧を取得
  Future<List<UserModel>> getUsersByStoreAndRole(String storeId, String role) async {
    // 複合インデックスを避けるため、店舗IDのみで引いてメモリ内でフィルタリング
    final querySnapshot = await _firestore
        .collection('users')
        .where('storeId', isEqualTo: storeId)
        .get();

    return querySnapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .where((user) => user.role == role)
        .toList();
  }

  // Firebase Authエラーハンドリング
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'このメールアドレスは既に登録されています';
      case 'invalid-email':
        return '正しいメールアドレスを入力してください';
      case 'weak-password':
        return 'パスワードは8文字以上で入力してください';
      case 'user-not-found':
        return 'メールアドレスまたはパスワードが正しくありません';
      case 'wrong-password':
        return 'メールアドレスまたはパスワードが正しくありません';
      case 'too-many-requests':
        return 'ログイン試行回数が多すぎます。しばらくしてから再度お試しください';
      case 'user-disabled':
        return 'このアカウントは無効化されています';
      case 'operation-not-allowed':
        return 'メール/パスワード認証が有効になっていません。Firebaseコンソールで有効にしてください。';
      default:
        return '認証エラーが発生しました: ${e.message}';
    }
  }
}
