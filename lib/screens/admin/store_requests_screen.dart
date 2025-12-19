import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shift_request_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/shift_provider.dart';
import '../../models/shift_request_model.dart';
import '../../models/staff_model.dart';
import '../../services/notification_service.dart';

class StoreRequestsScreen extends ConsumerStatefulWidget {
  const StoreRequestsScreen({super.key});

  @override
  ConsumerState<StoreRequestsScreen> createState() => _StoreRequestsScreenState();
}

class _StoreRequestsScreenState extends ConsumerState<StoreRequestsScreen> {
  // 代打スタッフの選択状態を保持 (requestId -> staffId)
  final Map<String, String> _selectedSubstitutes = {};

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    if (user?.storeId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final requestsAsync = ref.watch(storeRequestsProvider(user!.storeId!));
    final staffsAsync = ref.watch(storeStaffsProvider(user.storeId!));

    return Scaffold(
      appBar: AppBar(title: const Text('シフト申請一覧')),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) return const Center(child: Text('未処理の申請はありません'));

          return staffsAsync.when(
            data: (staffs) {
              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  final staff = staffs.firstWhere(
                    (s) => s.id == request.staffId,
                    orElse: () => const StaffModel(
                      id: '',
                      userId: '',
                      storeId: '',
                      name: '不明',
                      hourlyWage: 0,
                    ),
                  );
                  return _RequestListItem(
                    request: request, 
                    staff: staff,
                    allStaffs: staffs,
                    selectedSubstituteId: _selectedSubstitutes[request.id],
                    onSubstituteChanged: (newStaffId) {
                      setState(() {
                        if (newStaffId != null) {
                          _selectedSubstitutes[request.id] = newStaffId;
                        }
                      });
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('エラー: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
      ),
    );
  }
}

class _RequestListItem extends ConsumerWidget {
  final ShiftRequestModel request;
  final StaffModel staff;
  final List<StaffModel> allStaffs;
  final String? selectedSubstituteId;
  final ValueChanged<String?> onSubstituteChanged;

  const _RequestListItem({
    required this.request, 
    required this.staff,
    required this.allStaffs,
    this.selectedSubstituteId,
    required this.onSubstituteChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubstitute = request.type == 'substitute';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('${staff.name} さん - ${request.type == 'wish' ? '希望' : (isSubstitute ? '代打' : '変更')}'),
            subtitle: Text('${request.date} ${request.startTime ?? ''}-${request.endTime ?? ''}\n理由: ${request.reason ?? 'なし'}'),
            trailing: request.status == 'pending' 
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _handleStatusChange(context, ref, 'approved'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _handleStatusChange(context, ref, 'rejected'),
                    ),
                  ],
                )
              : Text('ステータス: ${request.status}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (isSubstitute && request.status == 'pending')
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  const Text('代打スタッフ: '),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedSubstituteId,
                      hint: const Text('選択してください'),
                      items: allStaffs
                          .where((s) => s.id != request.staffId) // 自分以外
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ))
                          .toList(),
                      onChanged: onSubstituteChanged,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleStatusChange(BuildContext context, WidgetRef ref, String newStatus) async {
    // 代打申請の承認時にスタッフが選択されているかチェック
    if (request.type == 'substitute' && newStatus == 'approved' && selectedSubstituteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('代打スタッフを選択してください'), backgroundColor: Colors.orange),
      );
      return;
    }

    final repository = ref.read(shiftRequestRepositoryProvider);
    final shiftRepository = ref.read(shiftRepositoryProvider);

    // 承認時のシフト反映処理
    if (newStatus == 'approved') {
      try {
        if (request.type == 'wish') {
          // シフト希望の承認：新規シフト(下書き)を作成
          await shiftRepository.createShift(
            storeId: request.storeId,
            staffId: request.staffId,
            date: request.date,
            startTime: request.startTime ?? '09:00',
            endTime: request.endTime ?? '18:00',
            status: 'draft',
          );
        } else if (request.type == 'change' || request.type == 'substitute') {
          // 変更・代打の承認：対象日の既存シフトを探して更新
          final existingShifts = await shiftRepository.getShiftsByStaffAndDateRange(
            staffId: request.staffId,
            storeId: request.storeId,
            startDate: request.date,
            endDate: request.date,
          );
          
          if (existingShifts.isNotEmpty) {
            final shift = existingShifts.first;
            
            // 代打の場合はスタッフIDも変更する
            final String? newStaffId = request.type == 'substitute' ? selectedSubstituteId : null;

            await shiftRepository.updateShift(
              shiftId: shift.id,
              staffId: newStaffId,
              startTime: request.startTime ?? shift.startTime,
              endTime: request.endTime ?? shift.endTime,
            );
          }
        }
      } catch (e) {
        debugPrint('Shift conversion error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('シフト反映に失敗しました: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    await repository.updateRequestStatus(request.id, newStatus);
    
    // 通知送信
    final userId = staff.userId;
    if (userId.isNotEmpty) {
      final notificationService = ref.read(notificationServiceProvider);
      final statusText = newStatus == 'approved' ? '承認' : '却下';
      await notificationService.notifyUser(
        userId: userId,
        title: '申請が$statusTextされました',
        body: '${request.date}の${request.type == 'wish' ? 'シフト希望' : '変更申請'}が$statusTextされました。',
      );
    }

    // 代打相手にも通知（任意）
    if (request.type == 'substitute' && newStatus == 'approved' && selectedSubstituteId != null) {
      final subStaff = allStaffs.firstWhere((s) => s.id == selectedSubstituteId);
      if (subStaff.userId.isNotEmpty) {
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.notifyUser(
          userId: subStaff.userId,
          title: '代打シフトが割り当てられました',
          body: '${request.date}に${staff.name}さんの代わりとしてシフトが割り当てられました。',
        );
      }
    }

    ref.invalidate(storeRequestsProvider(request.storeId));
    ref.invalidate(staffRequestsProvider(request.staffId));
    // シフト一覧に関連するプロバイダーも無効化
    ref.invalidate(storeShiftsProvider);
    ref.invalidate(staffShiftsProvider);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ステータスを更新しました')));
    }
  }
}
