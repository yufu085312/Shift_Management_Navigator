import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/store_repository.dart';
import '../models/store_model.dart';

// StoreRepositoryのプロバイダー
final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepository();
});

// 店舗情報を取得するプロバイダー
final storeProvider = FutureProvider.family<StoreModel?, String>((ref, storeId) async {
  final storeRepository = ref.watch(storeRepositoryProvider);
  return await storeRepository.getStore(storeId);
});

// オーナーの店舗一覧を取得するプロバイダー
final ownerStoresProvider = FutureProvider.family<List<StoreModel>, String>((ref, ownerId) async {
  final storeRepository = ref.watch(storeRepositoryProvider);
  return await storeRepository.getStoresByOwner(ownerId);
});
