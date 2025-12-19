import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/shift_request_repository.dart';
import '../models/shift_request_model.dart';

final shiftRequestRepositoryProvider = Provider((ref) => ShiftRequestRepository());

// 特定スタッフの申請一覧を取得するプロバイダー
final staffRequestsProvider = FutureProvider.family<List<ShiftRequestModel>, String>((ref, staffId) async {
  final repository = ref.watch(shiftRequestRepositoryProvider);
  return repository.getRequestsByStaff(staffId);
});

// 特定店舗の申請一覧を取得するプロバイダー(管理者用)
final storeRequestsProvider = FutureProvider.family<List<ShiftRequestModel>, String>((ref, storeId) async {
  final repository = ref.watch(shiftRequestRepositoryProvider);
  return repository.getRequestsByStore(storeId);
});
