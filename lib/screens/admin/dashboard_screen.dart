import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/shift_provider.dart';
import '../../providers/shift_request_provider.dart';
import '../../providers/store_provider.dart';
import '../../core/constants/app_constants.dart';
import 'shift_create_screen.dart';
import 'staff_management_screen.dart';
import 'store_requests_screen.dart';
import 'subscription_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  String _getPlanDisplayName(String? plan) {
    switch (plan) {
      case AppConstants.planFree:
        return AppConstants.labelFreePlan;
      case AppConstants.planBasic:
        return AppConstants.labelBasicPlan;
      case AppConstants.planPro:
        return AppConstants.labelProPlan;
      default:
        return AppConstants.labelFreePlan;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.titleAdminDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final signOut = ref.read(signOutProvider);
              await signOut();
            },
          ),
        ],
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null || user.storeId == null) {
            return const Center(child: Text(AppConstants.errMsgNoStore));
          }

          final now = DateTime.now();
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));
          final startDate = DateFormat('yyyy-MM-dd').format(weekStart);
          final endDate = DateFormat('yyyy-MM-dd').format(weekEnd);

          final storeAsync = ref.watch(storeProvider(user.storeId!));
          final staffsAsync = ref.watch(storeStaffsProvider(user.storeId!));
          final shiftsAsync = ref.watch(storeShiftsProvider(ShiftQueryParams(
            storeId: user.storeId!,
            startDate: startDate,
            endDate: endDate,
          )));
          final requestsAsync = ref.watch(storeRequestsProvider(user.storeId!));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 店舗情報カード
                storeAsync.when(
                  data: (store) => Card(
                    color: Colors.blue.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.store, color: Colors.blue, size: 40),
                      title: Text(
                        store?.name ?? AppConstants.labelStoreName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${AppConstants.labelCurrentPlan}: ${_getPlanDisplayName(store?.plan)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        tooltip: AppConstants.msgIdCopied,
                        onPressed: () {
                          // TODO: Copy store ID
                        },
                      ),
                    ),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (err, _) => Text('${AppConstants.labelError}: $err'),
                ),

                const SizedBox(height: 24),

                // ステータス概要
                Text(AppConstants.labelDashboardCurrentStatus, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _StatusCard(
                      title: AppConstants.labelDashboardRegisteredStaff,
                      value: staffsAsync.maybeWhen(
                        data: (staffs) => '${staffs.length}${AppConstants.labelPersonSuffix}',
                        orElse: () => '-',
                      ),
                      icon: Icons.people,
                      color: Colors.orange,
                    ),
                    _StatusCard(
                      title: AppConstants.labelDashboardUnpublishedShifts,
                      value: shiftsAsync.maybeWhen(
                        data: (shifts) => '${shifts.where((s) => s.status == AppConstants.shiftStatusDraft).length}${AppConstants.labelItemSuffix}',
                        orElse: () => '-',
                      ),
                      icon: Icons.edit_calendar,
                      color: Colors.blue,
                    ),
                    _StatusCard(
                      title: AppConstants.labelDashboardPendingRequests,
                      value: requestsAsync.maybeWhen(
                        data: (requests) => '${requests.where((r) => r.status == AppConstants.requestStatusPending).length}${AppConstants.labelItemSuffix}',
                        orElse: () => '-',
                      ),
                      icon: Icons.pending_actions,
                      color: Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // クイックメニュー
                Text(AppConstants.labelDashboardQuickMenu, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _MenuTile(
                  title: AppConstants.labelDashboardMenuCreate,
                  icon: Icons.calendar_today,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftCreateScreen())),
                ),
                _MenuTile(
                  title: AppConstants.labelDashboardMenuRequest,
                  icon: Icons.approval,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreRequestsScreen())),
                ),
                _MenuTile(
                  title: AppConstants.labelDashboardMenuStaff,
                  icon: Icons.badge,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffManagementScreen())),
                ),
                _MenuTile(
                  title: AppConstants.labelDashboardMenuSub,
                  icon: Icons.subscriptions,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('${AppConstants.labelError}: $error')),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatusCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
