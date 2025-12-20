import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/constants/app_constants.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.titleNotifications),
        actions: [
          userAsync.when(
            data: (user) => user != null
                ? IconButton(
                    icon: const Icon(Icons.done_all),
                    tooltip: AppConstants.labelMarkAllAsRead,
                    onPressed: () async {
                      final repository = ref.read(notificationRepositoryProvider);
                      await repository.markAllAsRead(user.uid);
                      ref.invalidate(notificationsProvider(user.uid));
                    },
                  )
                : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, _) => const SizedBox(),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text(AppConstants.errMsgUserNotFound));

          final notificationsAsync = ref.watch(notificationsProvider(user.uid));

          return notificationsAsync.when(
            data: (notifications) {
              if (notifications.isEmpty) {
                return const Center(child: Text(AppConstants.msgNoNotifications));
              }

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return ListTile(
                    leading: Icon(
                      notification.isRead ? Icons.notifications_none : Icons.notifications_active,
                      color: notification.isRead ? Colors.grey : Colors.blue,
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.body),
                        const SizedBox(height: 4),
                        Text(
                          notification.createdAt != null
                              ? DateFormat('yyyy/MM/dd HH:mm').format(notification.createdAt!)
                              : '',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    onTap: () async {
                      if (!notification.isRead) {
                        final repository = ref.read(notificationRepositoryProvider);
                        await repository.markAsRead(notification.id);
                        ref.invalidate(notificationsProvider(user.uid));
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('${AppConstants.errMsgGeneric}: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${AppConstants.errMsgGeneric}: $e')),
      ),
    );
  }
}
