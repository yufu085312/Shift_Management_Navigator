import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_model.dart';
import '../core/constants/app_constants.dart';

class StoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 店舗を作成
  Future<StoreModel> createStore({
    required String name,
    required String ownerId,
    Map<String, dynamic>? businessHours,
    int? shiftUnitMinutes,
    int? weekStart,
  }) async {
    final now = DateTime.now();
    final docRef = _firestore.collection(AppConstants.collectionStores).doc();

    final storeData = {
      'name': name,
      'ownerId': ownerId,
      'plan': AppConstants.planFree,
      'businessHours': businessHours ?? {},
      'shiftUnitMinutes': shiftUnitMinutes ?? 30,
      'weekStart': weekStart ?? 0,
      'createdAt': Timestamp.fromDate(now),
    };

    await docRef.set(storeData);

    return StoreModel.fromJson({
      ...storeData,
      'id': docRef.id,
    });
  }

  // 店舗情報を取得
  Future<StoreModel?> getStore(String storeId) async {
    try {
      final doc = await _firestore.collection(AppConstants.collectionStores).doc(storeId).get();
      if (!doc.exists) return null;
      return StoreModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // 店舗情報を更新
  Future<void> updateStore({
    required String storeId,
    String? name,
    String? plan,
    Map<String, dynamic>? businessHours,
    int? shiftUnitMinutes,
    int? weekStart,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (plan != null) updates['plan'] = plan;
    if (businessHours != null) updates['businessHours'] = businessHours;
    if (shiftUnitMinutes != null) updates['shiftUnitMinutes'] = shiftUnitMinutes;
    if (weekStart != null) updates['weekStart'] = weekStart;

    if (updates.isNotEmpty) {
      await _firestore.collection(AppConstants.collectionStores).doc(storeId).update(updates);
    }
  }

  // オーナーの店舗を取得
  Future<List<StoreModel>> getStoresByOwner(String ownerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionStores)
          .where('ownerId', isEqualTo: ownerId)
          .get();

      return querySnapshot.docs
          .map((doc) => StoreModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
