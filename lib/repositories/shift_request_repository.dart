import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shift_request_model.dart';
import '../core/constants/app_constants.dart';

class ShiftRequestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 申請を作成
  Future<ShiftRequestModel> createRequest({
    required String storeId,
    required String staffId,
    required String type,
    required String date,
    String? startTime,
    String? endTime,
    String? reason,
    String? targetShiftId,
  }) async {
    final now = DateTime.now();
    final docRef = _firestore.collection(AppConstants.collectionShiftRequests).doc();

    final requestData = {
      'storeId': storeId,
      'staffId': staffId,
      'type': type,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'reason': reason,
      'status': AppConstants.requestStatusPending,
      'targetShiftId': targetShiftId,
      'createdAt': Timestamp.fromDate(now),
    };

    // バッチ処理で申請作成とシフト更新を同時に行う
    final batch = _firestore.batch();
    batch.set(docRef, requestData);

    if (targetShiftId != null && (type == AppConstants.requestTypeChange || type == AppConstants.requestTypeSubstitute)) {
      final internalStatus = type == AppConstants.requestTypeChange 
          ? AppConstants.shiftRequestStatusPendingChange 
          : AppConstants.shiftRequestStatusPendingSubstitute;

      batch.update(_firestore.collection(AppConstants.collectionShifts).doc(targetShiftId), {
        'requestStatus': internalStatus,
        'requestId': docRef.id,
        'updatedAt': Timestamp.fromDate(now),
      });
    }

    await batch.commit();

    return ShiftRequestModel.fromJson({
      ...requestData,
      'id': docRef.id,
    });
  }

  // 交代を志願する
  Future<void> volunteerForSubstitute(String requestId, String staffId) async {
    final batch = _firestore.batch();
    final requestRef = _firestore.collection(AppConstants.collectionShiftRequests).doc(requestId);
    
    // 申請データを取得して対象シフトIDを特定
    final requestDoc = await requestRef.get();
    if (!requestDoc.exists) return;
    
    final targetShiftId = requestDoc.data()?['targetShiftId'] as String?;

    batch.update(requestRef, {
      'volunteerStaffId': staffId,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    if (targetShiftId != null) {
      batch.update(_firestore.collection(AppConstants.collectionShifts).doc(targetShiftId), {
        'volunteerStaffId': staffId,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }

    await batch.commit();
  }

  // 特定店舗の申請一覧を取得(管理者用)
  Future<List<ShiftRequestModel>> getRequestsByStore(String storeId) async {
    final querySnapshot = await _firestore
        .collection(AppConstants.collectionShiftRequests)
        .where('storeId', isEqualTo: storeId)
        .get();

    final requests = querySnapshot.docs
        .map((doc) => ShiftRequestModel.fromFirestore(doc))
        .toList();

    // 最新順にメモリ内でソート
    requests.sort((a, b) {
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });

    return requests;
  }

  // 特定店舗の期間指定での申請一覧を取得
  Future<List<ShiftRequestModel>> getRequestsByStoreAndDateRange({
    required String storeId,
    required String startDate,
    required String endDate,
  }) async {
    final querySnapshot = await _firestore
        .collection(AppConstants.collectionShiftRequests)
        .where('storeId', isEqualTo: storeId)
        .get();

    final allRequests = querySnapshot.docs
        .map((doc) => ShiftRequestModel.fromFirestore(doc))
        .toList();

    // メモリ内で期間フィルタリング
    return allRequests.where((r) {
      return r.date.compareTo(startDate) >= 0 && r.date.compareTo(endDate) <= 0;
    }).toList();
  }

  // 特定スタッフの申請一覧を取得(スタッフ用)
  Future<List<ShiftRequestModel>> getRequestsByStaff(String staffId, String storeId) async {
    final querySnapshot = await _firestore
        .collection(AppConstants.collectionShiftRequests)
        .where('staffId', isEqualTo: staffId)
        .where('storeId', isEqualTo: storeId)
        .get();

    final requests = querySnapshot.docs
        .map((doc) => ShiftRequestModel.fromFirestore(doc))
        .toList();

    // 最新順にソート
    requests.sort((a, b) {
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });

    return requests;
  }

  // 申請を更新(承認/却下など)
  Future<void> updateRequestStatus(String requestId, String status) async {
    await _firestore.collection(AppConstants.collectionShiftRequests).doc(requestId).update({
      'status': status,
      'processedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // 特定スタッフの申請一覧を取得(自身が提出した、または志願した申請)
  Future<List<ShiftRequestModel>> getRequestsByStaffOrVolunteer(String staffId, String storeId) async {
    // requesterとしての申請
    final requesterQuery = await _firestore
        .collection(AppConstants.collectionShiftRequests)
        .where('storeId', isEqualTo: storeId)
        .where('staffId', isEqualTo: staffId)
        .get();

    // volunteerとしての申請
    final volunteerQuery = await _firestore
        .collection(AppConstants.collectionShiftRequests)
        .where('storeId', isEqualTo: storeId)
        .where('volunteerStaffId', isEqualTo: staffId)
        .get();

    final allDocs = [...requesterQuery.docs, ...volunteerQuery.docs];
    
    // 重複を除去 (同じドキュメント ID を持つものを省く)
    final seenIds = <String>{};
    final requests = <ShiftRequestModel>[];
    for (final doc in allDocs) {
      if (!seenIds.contains(doc.id)) {
        requests.add(ShiftRequestModel.fromFirestore(doc));
        seenIds.add(doc.id);
      }
    }

    // 最新順にソート
    requests.sort((a, b) {
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });

    return requests;
  }

  // 申請を削除
  Future<void> deleteRequest(String requestId) async {
    await _firestore.collection(AppConstants.collectionShiftRequests).doc(requestId).delete();
  }
}
