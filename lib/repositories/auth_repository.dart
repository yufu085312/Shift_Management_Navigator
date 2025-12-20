import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

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
      final userDoc = await _firestore.collection(AppConstants.collectionUsers).doc(uid).get();

      if (!userDoc.exists) {
        throw Exception(AppConstants.errMsgUserNotFound);
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
      await _firestore.collection(AppConstants.collectionUsers).doc(uid).set({
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
      final userDoc = await _firestore.collection(AppConstants.collectionUsers).doc(uid).get();
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
    bool clearStoreId = false,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (clearStoreId) {
      updates['storeId'] = null;
    } else if (storeId != null) {
      updates['storeId'] = storeId;
    }

    if (updates.isNotEmpty) {
      await _firestore.collection(AppConstants.collectionUsers).doc(uid).update(updates);
    }
  }

  // 店舗の特定のロールのユーザー一覧を取得
  Future<List<UserModel>> getUsersByStoreAndRole(String storeId, String role) async {
    // 複合インデックスを避けるため、店舗IDのみで引いてメモリ内でフィルタリング
    final querySnapshot = await _firestore
        .collection(AppConstants.collectionUsers)
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
        return AppConstants.errMsgEmailInUse;
      case 'invalid-email':
        return AppConstants.valInvalidEmail;
      case 'weak-password':
        return AppConstants.labelPasswordHelper;
      case 'user-not-found':
      case 'wrong-password':
        return AppConstants.errMsgInvalidCred;
      case 'too-many-requests':
        return AppConstants.errMsgTooManyRequests;
      case 'user-disabled':
        return AppConstants.errMsgUserDisabled;
      case 'operation-not-allowed':
        return AppConstants.errMsgOpNotAllowed;
      default:
        return '${AppConstants.errMsgAuth}: ${e.message}';
    }
  }
}
