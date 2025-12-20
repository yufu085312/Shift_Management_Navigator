import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/staff_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_constants.dart';

final notificationServiceProvider = Provider((ref) => NotificationService(ref));

class NotificationService {
  final Ref _ref;

  NotificationService(this._ref);

  // 全スタッフに通知を送信
  Future<void> notifyAllStaff({
    required String storeId,
    required String title,
    required String body,
    String? excludeUserId,
  }) async {
    final staffRepository = _ref.read(staffRepositoryProvider);
    final notificationRepository = _ref.read(notificationRepositoryProvider);

    final staffs = await staffRepository.getStaffsByStore(storeId);
    
    final batch = <Future>[];
    for (final staff in staffs) {
      final userId = staff.userId;
      if (userId.isNotEmpty && userId != excludeUserId) {
        batch.add(notificationRepository.createNotification(
          userId: userId,
          title: title,
          body: body,
        ));
      }
    }
    
    await Future.wait(batch);
  }

  // 特定のユーザーに通知を送信
  Future<void> notifyUser({
    required String userId,
    required String title,
    required String body,
  }) async {
    final notificationRepository = _ref.read(notificationRepositoryProvider);
    await notificationRepository.createNotification(
      userId: userId,
      title: title,
      body: body,
    );
  }

  // 店舗の管理者に通知を送信
  Future<void> notifyAdmins({
    required String storeId,
    required String title,
    required String body,
  }) async {
    final authRepository = _ref.read(authRepositoryProvider);
    final notificationRepository = _ref.read(notificationRepositoryProvider);

    final admins = await authRepository.getUsersByStoreAndRole(storeId, AppConstants.roleAdmin);
    
    final batch = <Future>[];
    for (final admin in admins) {
      batch.add(notificationRepository.createNotification(
        userId: admin.uid,
        title: title,
        body: body,
      ));
    }
    
    await Future.wait(batch);
  }
}
