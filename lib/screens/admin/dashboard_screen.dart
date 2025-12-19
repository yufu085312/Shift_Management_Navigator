import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/shift_provider.dart';
import '../../providers/shift_request_provider.dart';
import 'staff_management_screen.dart';
import 'shift_create_screen.dart';
import 'store_requests_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理者ダッシュボード'),
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
            return const Center(child: Text('店舗情報が見つかりません'));
          }

          final storeAsync = ref.watch(storeProvider(user.storeId!));
          final staffCountAsync = ref.watch(staffCountProvider(user.storeId!));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 店舗情報カード
              storeAsync.when(
                data: (store) => _buildStoreCard(
                  context,
                  store?.name ?? '店舗名',
                  user.storeId!,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const SizedBox(),
              ),
              const SizedBox(height: 24),

              // クイックメニュー
              const Text(
                'クイックメニュー',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildMenuCard(
                    context,
                    'シフト作成・公開',
                    Icons.calendar_month,
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShiftCreateScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    'シフト申請',
                    Icons.pending_actions,
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StoreRequestsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    'スタッフ管理',
                    Icons.people,
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StaffManagementScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    '設定',
                    Icons.settings,
                    Colors.grey,
                    () {}, // TODO: 設定画面
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ステータス概要
              const Text(
                '現在状況',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatusRow(
                        '登録スタッフ',
                        staffCountAsync.when(
                          data: (count) => '$count名',
                          loading: () => '...',
                          error: (_, _) => 'エラー',
                        ),
                        Icons.person,
                      ),
                      const Divider(),
                      _buildStatusRow(
                        '今週の未公開シフト',
                        ref.watch(storeShiftsProvider(ShiftQueryParams(
                          storeId: user.storeId!,
                          startDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          endDate: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 7))),
                        ))).when(
                          data: (shifts) => '${shifts.where((s) => s.status == 'draft').length}件',
                          loading: () => '...',
                          error: (_, _) => 'エラー',
                        ),
                        Icons.edit_calendar,
                      ),
                      const Divider(),
                      _buildStatusRow(
                        '未処理の申請',
                        ref.watch(storeRequestsProvider(user.storeId!)).when(
                          data: (requests) => '${requests.where((r) => r.status == 'pending').length}件',
                          loading: () => '...',
                          error: (_, _) => 'エラー',
                        ),
                        Icons.pending_actions,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
    );
  }


  Widget _buildStoreCard(BuildContext context, String storeName, String storeId) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '店舗名',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: storeId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('店舗IDをコピーしました')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'ID: $storeId',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            storeName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
