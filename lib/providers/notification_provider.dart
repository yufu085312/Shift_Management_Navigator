import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/notification_repository.dart';
import '../models/notification_model.dart';

final notificationRepositoryProvider = Provider((ref) => NotificationRepository());

// ユーザーの通知一覧を取得するプロバイダー
final notificationsProvider = FutureProvider.family<List<NotificationModel>, String>((ref, userId) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotifications(userId);
});

// 未読通知数を取得するプロバイダー
final unreadNotificationCountProvider = Provider.family<int, String>((ref, userId) {
  final notificationsAsync = ref.watch(notificationsProvider(userId));
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
