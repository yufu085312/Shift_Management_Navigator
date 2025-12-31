import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import '../models/staff_model.dart';
import '../core/constants/app_constants.dart';

class StaffRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _dateFormatPattern = 'yyyy-MM-dd';

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
      AppConstants.fieldUserId: userId,
      AppConstants.fieldStoreId: storeId,
      AppConstants.fieldName: name,
      AppConstants.fieldHourlyWage: hourlyWage ?? 0,
      AppConstants.fieldIsActive: true,
      AppConstants.fieldCreatedAt: Timestamp.fromDate(now),
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
          .where(AppConstants.fieldStoreId, isEqualTo: storeId)
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
    if (name != null) updates[AppConstants.fieldName] = name;
    if (hourlyWage != null) updates[AppConstants.fieldHourlyWage] = hourlyWage;
    if (isActive != null) updates[AppConstants.fieldIsActive] = isActive;

    if (updates.isNotEmpty) {
      await _firestore.collection(AppConstants.collectionStaffs).doc(staffId).update(updates);
    }
  }

  // スタッフを削除(無効化)し、関連データをクリーンアップ
  Future<void> deleteStaff(String staffId, String userId) async {
    final batch = _firestore.batch();
    final nowStr = DateFormat(_dateFormatPattern).format(DateTime.now());
    
    // 1. staffs ドキュメントを無効化
    batch.update(_firestore.collection(AppConstants.collectionStaffs).doc(staffId), {
      AppConstants.fieldIsActive: false,
    });
    
    // 2. users ドキュメントの storeId をクリア (管理者の場合は店舗アクセス権を維持するためスキップ)
    if (userId.isNotEmpty) {
      final userDoc = await _firestore.collection(AppConstants.collectionUsers).doc(userId).get();
      final userRole = userDoc.data()?[AppConstants.fieldRole] as String?;
      
      if (userRole != AppConstants.roleAdmin) {
        batch.update(_firestore.collection(AppConstants.collectionUsers).doc(userId), {
          AppConstants.fieldStoreId: null,
        });
      }
    }

    // 3. 未来のシフトを削除
    final shiftsSnapshot = await _firestore
        .collection(AppConstants.collectionShifts)
        .where(AppConstants.fieldStaffId, isEqualTo: staffId)
        .get();
    
    for (var doc in shiftsSnapshot.docs) {
      final date = doc.data()[AppConstants.fieldDate] as String;
      if (date.compareTo(nowStr) >= 0) {
        batch.delete(doc.reference);
      }
    }

    // 4. 全ての申請(シフト希望・変更申請など)を削除
    final requestsSnapshot = await _firestore
        .collection(AppConstants.collectionShiftRequests)
        .where(AppConstants.fieldStaffId, isEqualTo: staffId)
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
          .where(AppConstants.fieldUserId, isEqualTo: userId)
          .where(AppConstants.fieldStoreId, isEqualTo: storeId)
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
          .where(AppConstants.fieldUserId, isEqualTo: userId)
          .where(AppConstants.fieldIsActive, isEqualTo: true)
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
    // すでに同じ店舗に登録されているか確認 (isActiveに関わらず取得)
    final querySnapshot = await _firestore
        .collection(AppConstants.collectionStaffs)
        .where(AppConstants.fieldUserId, isEqualTo: userId)
        .where(AppConstants.fieldStoreId, isEqualTo: storeId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // すでに登録済み（または過去に登録されていた）ならisActiveをtrueにする
      await querySnapshot.docs.first.reference.update({
        AppConstants.fieldIsActive: true,
        AppConstants.fieldName: name,
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
  // スタッフ情報の無効化、未来のシフトと申請の削除を行う
  Future<void> leaveStore({
    required String userId,
    required String storeId,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // 1. スタッフ情報を取得（userId のみでクエリし、インデックス不要にする）
      final staffQuery = await _firestore
          .collection(AppConstants.collectionStaffs)
          .where(AppConstants.fieldUserId, isEqualTo: userId)
          .get();
      
      // storeId でフィルタリング
      final staffDocs = staffQuery.docs.where((doc) => doc.data()[AppConstants.fieldStoreId] == storeId).toList();
      
      if (staffDocs.isEmpty) {
        throw Exception('スタッフ情報が見つかりません');
      }
      
      final staffDoc = staffDocs.first;
      final staffId = staffDoc.id;
      
      // 2. スタッフ情報を無効化
      batch.update(staffDoc.reference, {AppConstants.fieldIsActive: false});

      // 3. ユーザー情報の店舗IDをクリア
      final userDocRef = _firestore.collection(AppConstants.collectionUsers).doc(userId);
      batch.update(userDocRef, {AppConstants.fieldStoreId: null});
      
      // 4. 本日以降のシフトを削除（staffId のみでクエリし、インデックス不要にする）
      final today = DateFormat(_dateFormatPattern).format(DateTime.now());
      final shiftsQuery = await _firestore
          .collection(AppConstants.collectionShifts)
          .where(AppConstants.fieldStaffId, isEqualTo: staffId)
          .get();
      
      // 日付と storeId でフィルタリング
      for (var doc in shiftsQuery.docs) {
        final data = doc.data();
        final shiftDate = data[AppConstants.fieldDate] as String;
        final shiftStoreId = data[AppConstants.fieldStoreId] as String;
        
        if (shiftStoreId == storeId && shiftDate.compareTo(today) >= 0) {
          batch.delete(doc.reference);
        }
      }
      
      // 5. すべての申請を削除（staffId のみでクエリ）
      final requestsQuery = await _firestore
          .collection(AppConstants.collectionShiftRequests)
          .where(AppConstants.fieldStaffId, isEqualTo: staffId)
          .get();
      
      // storeId でフィルタリング
      for (var doc in requestsQuery.docs) {
        if (doc.data()[AppConstants.fieldStoreId] == storeId) {
          batch.delete(doc.reference);
        }
      }
      
      // バッチ処理を実行
      await batch.commit();
    } catch (e) {
      throw Exception('店舗退出処理に失敗しました: $e');
    }
  }

  // 店舗のスタッフ数を取得
  Future<int> getStaffCount(String storeId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionStaffs)
          .where(AppConstants.fieldStoreId, isEqualTo: storeId)
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
