import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/shift_request_repository.dart';
import '../models/shift_request_model.dart';

final shiftRequestRepositoryProvider = Provider((ref) => ShiftRequestRepository());

// 特定スタッフの申請一覧を取得するプロバイダー
final staffRequestsProvider = FutureProvider.family<List<ShiftRequestModel>, StaffRequestQueryParams>((ref, params) async {
  final repository = ref.watch(shiftRequestRepositoryProvider);
  return repository.getRequestsByStaff(params.staffId, params.storeId);
});

class StaffRequestQueryParams {
  final String staffId;
  final String storeId;

  StaffRequestQueryParams({required this.staffId, required this.storeId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffRequestQueryParams &&
          runtimeType == other.runtimeType &&
          staffId == other.staffId &&
          storeId == other.storeId;

  @override
  int get hashCode => staffId.hashCode ^ storeId.hashCode;
}

// 特定店舗の申請一覧を取得するプロバイダー(管理者用)
final storeRequestsProvider = FutureProvider.family<List<ShiftRequestModel>, String>((ref, storeId) async {
  final repository = ref.watch(shiftRequestRepositoryProvider);
  return repository.getRequestsByStore(storeId);
});
