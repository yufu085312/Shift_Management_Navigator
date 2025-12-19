import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/shift_repository.dart';
import '../models/shift_model.dart';

// ShiftRepositoryのプロバイダー
final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  return ShiftRepository();
});

// 店舗の特定期間のシフト一覧を取得するプロバイダー
final storeShiftsProvider = FutureProvider.family<List<ShiftModel>, ShiftQueryParams>((ref, params) async {
  final shiftRepository = ref.watch(shiftRepositoryProvider);
  return await shiftRepository.getShiftsByStoreAndDateRange(
    storeId: params.storeId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

// スタッフの特定期間のシフト一覧を取得するプロバイダー
final staffShiftsProvider = FutureProvider.family<List<ShiftModel>, StaffShiftQueryParams>((ref, params) async {
  final shiftRepository = ref.watch(shiftRepositoryProvider);
  return await shiftRepository.getShiftsByStaffAndDateRange(
    staffId: params.staffId,
    storeId: params.storeId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

// 代打募集中のシフト一覧を取得するプロバイダー
final recruitingSubstitutesProvider = FutureProvider.family<List<ShiftModel>, String>((ref, storeId) async {
  final shiftRepository = ref.watch(shiftRepositoryProvider);
  return await shiftRepository.getRecruitingSubstitutes(storeId);
});

// クエリパラメータ
class ShiftQueryParams {
  final String storeId;
  final String startDate;
  final String endDate;

  ShiftQueryParams({
    required this.storeId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftQueryParams &&
          runtimeType == other.runtimeType &&
          storeId == other.storeId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => storeId.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}

// スタッフ用クエリパラメータ
class StaffShiftQueryParams {
  final String staffId;
  final String storeId;
  final String startDate;
  final String endDate;

  StaffShiftQueryParams({
    required this.staffId,
    required this.storeId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffShiftQueryParams &&
          runtimeType == other.runtimeType &&
          staffId == other.staffId &&
          storeId == other.storeId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => staffId.hashCode ^ storeId.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}
