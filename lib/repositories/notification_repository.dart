import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../core/constants/app_constants.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 通知を作成
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    await _firestore.collection(AppConstants.collectionNotifications).add({
      'userId': userId,
      'title': title,
      'body': body,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 通知を取得
  Future<List<NotificationModel>> getNotifications(String userId) async {
    final querySnapshot = await _firestore
        .collection(AppConstants.collectionNotifications)
        .where('userId', isEqualTo: userId)
        .get();

    final notifications = querySnapshot.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .toList();

    // 最新順にソート
    notifications.sort((a, b) {
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });

    return notifications;
  }

  // 通知を既読にする
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection(AppConstants.collectionNotifications).doc(notificationId).update({
      'isRead': true,
    });
  }

  // すべての通知を既読にする
  Future<void> markAllAsRead(String userId) async {
    final querySnapshot = await _firestore
        .collection(AppConstants.collectionNotifications)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}
