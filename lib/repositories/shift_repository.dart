import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shift_model.dart';
import '../core/constants/app_constants.dart';

class ShiftRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // シフトを作成
  Future<ShiftModel> createShift({
    required String storeId,
    required String staffId,
    required String date,
    required String startTime,
    required String endTime,
    String status = AppConstants.shiftStatusDraft,
  }) async {
    final now = DateTime.now();
    final docRef = _firestore.collection(AppConstants.collectionShifts).doc();

    final shiftData = {
      'storeId': storeId,
      'staffId': staffId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    await docRef.set(shiftData);

    return ShiftModel.fromJson({
      ...shiftData,
      'id': docRef.id,
    });
  }

  // シフトを取得
  Future<ShiftModel?> getShift(String shiftId) async {
    try {
      final doc = await _firestore.collection(AppConstants.collectionShifts).doc(shiftId).get();
      if (!doc.exists) return null;
      return ShiftModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // 店舗の特定期間のシフト一覧を取得
  Future<List<ShiftModel>> getShiftsByStoreAndDateRange({
    required String storeId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionShifts)
          .where('storeId', isEqualTo: storeId)
          .get();

      final allShifts = querySnapshot.docs
          .map((doc) => ShiftModel.fromFirestore(doc))
          .toList();

      // メモリ内で期間フィルタリング
      return allShifts.where((s) {
        return s.date.compareTo(startDate) >= 0 && s.date.compareTo(endDate) <= 0;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // スタッフの特定期間のシフト一覧を取得
  Future<List<ShiftModel>> getShiftsByStaffAndDateRange({
    required String staffId,
    required String storeId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionShifts)
          .where('staffId', isEqualTo: staffId)
          .where('storeId', isEqualTo: storeId)
          .get();

      final allShifts = querySnapshot.docs
          .map((doc) => ShiftModel.fromFirestore(doc))
          .toList();

      // メモリ内で期間フィルタリング
      return allShifts.where((s) {
        return s.date.compareTo(startDate) >= 0 && s.date.compareTo(endDate) <= 0;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // シフトを更新
  Future<void> updateShift({
    required String shiftId,
    String? staffId,
    String? startTime,
    String? endTime,
    String? status,
    String? requestStatus,
    String? requestId,
    bool clearRequest = false,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    
    if (staffId != null) updates['staffId'] = staffId;
    if (startTime != null) updates['startTime'] = startTime;
    if (endTime != null) updates['endTime'] = endTime;
    if (status != null) updates['status'] = status;
    
    if (clearRequest) {
      updates['requestStatus'] = FieldValue.delete();
      updates['requestId'] = FieldValue.delete();
    } else {
      if (requestStatus != null) updates['requestStatus'] = requestStatus;
      if (requestId != null) updates['requestId'] = requestId;
    }

    await _firestore.collection(AppConstants.collectionShifts).doc(shiftId).update(updates);
  }

  // シフトを削除
  Future<void> deleteShift(String shiftId) async {
    await _firestore.collection(AppConstants.collectionShifts).doc(shiftId).delete();
  }

  // シフトを公開(ステータスを確定に変更)
  Future<void> publishShifts({
    required String storeId,
    required String startDate,
    required String endDate,
  }) async {
    final querySnapshot = await _firestore
        .collection(AppConstants.collectionShifts)
        .where('storeId', isEqualTo: storeId)
        .get();

    final batch = _firestore.batch();
    int count = 0;
    
    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final date = data['date'] as String;
      final status = data['status'] as String;
      
      // 期間内かつ下書き状態のものを抽出
      if (date.compareTo(startDate) >= 0 && 
          date.compareTo(endDate) <= 0 && 
          status == AppConstants.shiftStatusDraft) {
        batch.update(doc.reference, {
          'status': AppConstants.shiftStatusConfirmed,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
        count++;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }

  // 代打を募集しているシフト一覧を取得
  Future<List<ShiftModel>> getRecruitingSubstitutes(String storeId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionShifts)
          .where('storeId', isEqualTo: storeId)
          .where('requestStatus', isEqualTo: AppConstants.shiftRequestStatusPendingSubstitute)
          .get();

      return querySnapshot.docs
          .map((doc) => ShiftModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
