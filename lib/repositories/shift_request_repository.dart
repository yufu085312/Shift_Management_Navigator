import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shift_request_model.dart';

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
  }) async {
    final now = DateTime.now();
    final docRef = _firestore.collection('shift_requests').doc();

    final requestData = {
      'storeId': storeId,
      'staffId': staffId,
      'type': type,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'reason': reason,
      'status': 'pending',
      'createdAt': Timestamp.fromDate(now),
    };

    await docRef.set(requestData);

    return ShiftRequestModel.fromJson({
      ...requestData,
      'id': docRef.id,
    });
  }

  // 特定店舗の申請一覧を取得(管理者用)
  Future<List<ShiftRequestModel>> getRequestsByStore(String storeId) async {
    final querySnapshot = await _firestore
        .collection('shift_requests')
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
        .collection('shift_requests')
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
  Future<List<ShiftRequestModel>> getRequestsByStaff(String staffId) async {
    final querySnapshot = await _firestore
        .collection('shift_requests')
        .where('staffId', isEqualTo: staffId)
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
    await _firestore.collection('shift_requests').doc(requestId).update({
      'status': status,
      'processedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // 申請を削除
  Future<void> deleteRequest(String requestId) async {
    await _firestore.collection('shift_requests').doc(requestId).delete();
  }
}
