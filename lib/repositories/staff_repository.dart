import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/staff_model.dart';
import '../core/constants/app_constants.dart';

class StaffRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // スタッフを作成
  Future<StaffModel> createStaff({
    required String userId,
    required String storeId,
    required String name,
    int? hourlyWage,
  }) async {
    final now = DateTime.now();
    final docRef = _firestore.collection(AppConstants.collectionStaffs).doc();

    final staffData = {
      'userId': userId,
      'storeId': storeId,
      'name': name,
      'hourlyWage': hourlyWage ?? 0,
      'isActive': true,
      'createdAt': Timestamp.fromDate(now),
    };

    await docRef.set(staffData);

    return StaffModel.fromJson({
      ...staffData,
      'id': docRef.id,
    });
  }

  // スタッフ情報を取得
  Future<StaffModel?> getStaff(String staffId) async {
    try {
      final doc = await _firestore.collection(AppConstants.collectionStaffs).doc(staffId).get();
      if (!doc.exists) return null;
      return StaffModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // 店舗のスタッフ一覧を取得
  Future<List<StaffModel>> getStaffsByStore(String storeId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionStaffs)
          .where('storeId', isEqualTo: storeId)
          .get();

      final allStaffs = querySnapshot.docs
          .map((doc) => StaffModel.fromFirestore(doc))
          .toList();

      // メモリ内でアクティブなスタッフのみに絞り込み
      return allStaffs.where((s) => s.isActive).toList();
    } catch (e) {
      return [];
    }
  }

  // スタッフ情報を更新
  Future<void> updateStaff({
    required String staffId,
    String? name,
    int? hourlyWage,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (hourlyWage != null) updates['hourlyWage'] = hourlyWage;
    if (isActive != null) updates['isActive'] = isActive;

    if (updates.isNotEmpty) {
      await _firestore.collection(AppConstants.collectionStaffs).doc(staffId).update(updates);
    }
  }

  // スタッフを削除(無効化)し、関連データをクリーンアップ
  Future<void> deleteStaff(String staffId, String userId) async {
    final batch = _firestore.batch();
    final nowStr = DateTime.now().toIso8601String().split('T')[0];
    
    // 1. staffs ドキュメントを無効化
    batch.update(_firestore.collection(AppConstants.collectionStaffs).doc(staffId), {
      'isActive': false,
    });
    
    // 2. users ドキュメントの storeId をクリア
    if (userId.isNotEmpty) {
      batch.update(_firestore.collection(AppConstants.collectionUsers).doc(userId), {
        'storeId': null,
      });
    }

    // 3. 未来のシフトを削除
    final shiftsSnapshot = await _firestore
        .collection(AppConstants.collectionShifts)
        .where('staffId', isEqualTo: staffId)
        .get();
    
    for (var doc in shiftsSnapshot.docs) {
      final date = doc.data()['date'] as String;
      if (date.compareTo(nowStr) >= 0) {
        batch.delete(doc.reference);
      }
    }

    // 4. 全ての申請(シフト希望・変更申請など)を削除
    final requestsSnapshot = await _firestore
        .collection(AppConstants.collectionShiftRequests)
        .where('staffId', isEqualTo: staffId)
        .get();

    for (var doc in requestsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  // ユーザーIDからスタッフ情報を取得
  Future<StaffModel?> getStaffByUserId(String userId, String storeId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionStaffs)
          .where('userId', isEqualTo: userId)
          .where('storeId', isEqualTo: storeId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      return StaffModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  // ユーザーIDのみでスタッフ情報を取得 (店舗横断、主に自動同期用)
  Future<StaffModel?> findStaffByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionStaffs)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      return StaffModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  // 店舗に参加(ユーザーと店舗の紐付け)
  Future<void> joinStore({
    required String userId,
    required String storeId,
    required String name,
  }) async {
    // すでに同じ店舗に登録されているか確認
    final querySnapshot = await _firestore
        .collection(AppConstants.collectionStaffs)
        .where('userId', isEqualTo: userId)
        .where('storeId', isEqualTo: storeId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // すでに登録済みならisActiveをtrueにする
      await querySnapshot.docs.first.reference.update({
        'isActive': true,
        'name': name,
      });
    } else {
      // 新規でスタッフデータを作成
      await createStaff(
        userId: userId,
        storeId: storeId,
        name: name,
        hourlyWage: 0,
      );
    }
  }

  // 店舗から退出(ユーザーと店舗の紐付けを解除)
  // Cloud Functions を使ってクリーンアップ処理を実行
  Future<void> leaveStore({
    required String userId,
    required String storeId,
  }) async {
    try {
      // Cloud Functions を呼び出してクリーンアップ
      final functions = FirebaseFunctions.instance;
      
      // 開発環境ではエミュレータを使用
      // 本番環境では自動的に本番の Functions を使用
      if (const String.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: 'true') == 'true') {
        functions.useFunctionsEmulator('127.0.0.1', 5001);
      }
      
      final callable = functions.httpsCallable('leaveStoreCleanup');
      
      await callable.call({
        'userId': userId,
        'storeId': storeId,
      });
    } catch (e) {
      throw Exception('店舗退出処理に失敗しました: $e');
    }
  }

  // 店舗のスタッフ数を取得
  Future<int> getStaffCount(String storeId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionStaffs)
          .where('storeId', isEqualTo: storeId)
          .get();

      final allStaffs = querySnapshot.docs
          .map((doc) => StaffModel.fromFirestore(doc))
          .toList();

      return allStaffs.where((s) => s.isActive).length;
    } catch (e) {
      return 0;
    }
  }
}
