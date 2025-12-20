import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shift_provider.dart';
import '../providers/shift_request_provider.dart';
import '../core/constants/app_constants.dart';

final autoAssignServiceProvider = Provider((ref) => AutoAssignService(ref));

class AutoAssignService {
  final Ref _ref;

  AutoAssignService(this._ref);

  Future<int> autoAssign({
    required String storeId,
    required String startDate,
    required String endDate,
  }) async {
    final shiftRepository = _ref.read(shiftRepositoryProvider);
    final requestRepository = _ref.read(shiftRequestRepositoryProvider);

    // 1. 指定期間のスタッフ希望(wish)を取得
    final wishes = await requestRepository.getRequestsByStoreAndDateRange(
      storeId: storeId,
      startDate: startDate,
      endDate: endDate,
    );

    // 2. 既存のシフトを取得
    final existingShifts = await shiftRepository.getShiftsByStoreAndDateRange(
      storeId: storeId,
      startDate: startDate,
      endDate: endDate,
    );

    // 3. 自動割当ロジック
    int count = 0;
    // シンプルな実装: まだシフトが入っていない日付の希望を全てドラフトとして採用
    for (final wish in wishes) {
      if (wish.type != AppConstants.requestTypeWish) continue;

      // 同日の同スタッフのシフトが既にあるかチェック
      final hasShift = existingShifts.any(
        (s) => s.staffId == wish.staffId && s.date == wish.date,
      );

      if (!hasShift) {
        await shiftRepository.createShift(
          storeId: storeId,
          staffId: wish.staffId,
          date: wish.date,
          startTime: wish.startTime ?? '09:00',
          endTime: wish.endTime ?? '18:00',
          status: AppConstants.shiftStatusDraft,
        );
        count++;
      }
    }
    return count;
  }
}
