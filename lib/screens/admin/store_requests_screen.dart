import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shift_request_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/shift_provider.dart';
import '../../models/shift_request_model.dart';
import '../../models/staff_model.dart';
import '../../services/notification_service.dart';
import '../../core/constants/app_constants.dart';

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
      appBar: AppBar(title: const Text(AppConstants.titleShiftRequestList)),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) return const Center(child: Text(AppConstants.msgNoPendingRequests));

          return staffsAsync.when(
            data: (staffs) {
              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  // 志願者がいる場合は初期値としてセット
                  if (request.type == AppConstants.requestTypeSubstitute && 
                      request.volunteerStaffId != null && 
                      !_selectedSubstitutes.containsKey(request.id)) {
                    _selectedSubstitutes[request.id] = request.volunteerStaffId!;
                  }

                  final staff = staffs.firstWhere(
                    (s) => s.id == request.staffId,
                    orElse: () => const StaffModel(
                      id: '',
                      userId: '',
                      storeId: '',
                      name: AppConstants.labelUnknown,
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
            error: (e, _) => Center(child: Text('${AppConstants.errMsgGeneric}: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${AppConstants.errMsgGeneric}: $e')),
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
    final isSubstitute = request.type == AppConstants.requestTypeSubstitute;
    final String typeLabel;
    if (request.type == AppConstants.requestTypeWish) {
      typeLabel = AppConstants.labelShiftWish;
    } else if (isSubstitute) {
      typeLabel = AppConstants.labelSubstituteWish;
    } else if (request.type == AppConstants.requestTypeChange) {
      typeLabel = AppConstants.labelChangeTime;
    } else {
      typeLabel = AppConstants.labelStoreRequest;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('${staff.name}${AppConstants.labelHonorificStaff} - $typeLabel'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${request.date} ${request.startTime ?? ''}-${request.endTime ?? ''}'),
                Text('${AppConstants.labelReasonMessage}: ${request.reason ?? AppConstants.labelNone}'),
                if (isSubstitute && request.volunteerStaffId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        AppConstants.msgVolunteerExists,
                        style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            trailing: request.status == AppConstants.requestStatusPending 
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _handleStatusChange(context, ref, AppConstants.requestStatusApproved),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _handleStatusChange(context, ref, AppConstants.requestStatusRejected),
                    ),
                  ],
                )
              : Text('${AppConstants.labelStatus}: ${request.status}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (isSubstitute && request.status == AppConstants.requestStatusPending)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  const Text('${AppConstants.labelSubstituteStaff}: '),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedSubstituteId,
                      hint: const Text(AppConstants.labelSelect),
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
    if (request.type == AppConstants.requestTypeSubstitute && newStatus == AppConstants.requestStatusApproved && selectedSubstituteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.valSelectStaff), backgroundColor: Colors.orange),
      );
      return;
    }

    final repository = ref.read(shiftRequestRepositoryProvider);
    final shiftRepository = ref.read(shiftRepositoryProvider);

    // 承認時のシフト反映処理
    if (newStatus == AppConstants.requestStatusApproved) {
      try {
        if (request.type == AppConstants.requestTypeWish) {
          // シフト希望の承認：新規シフト(下書き)を作成
          await shiftRepository.createShift(
            storeId: request.storeId,
            staffId: request.staffId,
            date: request.date,
            startTime: request.startTime ?? '09:00',
            endTime: request.endTime ?? '18:00',
            status: AppConstants.shiftStatusDraft,
          );
        } else if (request.type == AppConstants.requestTypeChange || request.type == AppConstants.requestTypeSubstitute) {
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
            final String? newStaffId = request.type == AppConstants.requestTypeSubstitute ? selectedSubstituteId : null;

            await shiftRepository.updateShift(
              shiftId: shift.id,
              staffId: newStaffId,
              startTime: request.startTime ?? shift.startTime,
              endTime: request.endTime ?? shift.endTime,
              status: shift.status,
              clearRequest: true,
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppConstants.msgShiftUpdateFailed}: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else if (newStatus == AppConstants.requestStatusRejected) {
      // 見送り時もシフト側の申請フラグをクリアする
      try {
        if (request.targetShiftId != null) {
          await shiftRepository.updateShift(
            shiftId: request.targetShiftId!,
            clearRequest: true,
          );
        }
      } catch (e) {
        // エラー時は静かに続行
      }
    }

    await repository.updateRequestStatus(request.id, newStatus);
    
    // 通知送信
    final userId = staff.userId;
    if (userId.isNotEmpty) {
      final notificationService = ref.read(notificationServiceProvider);
      final statusText = newStatus == AppConstants.requestStatusApproved ? AppConstants.labelApproved : AppConstants.labelRejected;
      await notificationService.notifyUser(
        userId: userId,
        title: '${AppConstants.msgRequestUpdateTitle}${statusText}${AppConstants.msgRequestUpdateBodyPrefix}',
        body: '${request.date}${AppConstants.labelParticleNo}${request.type == AppConstants.requestTypeWish ? AppConstants.labelShiftWish : AppConstants.labelChangeRequest}${AppConstants.labelParticleGa}$statusText${AppConstants.msgNotificationStatusSuffix}',
      );
    }

    // 代打相手にも通知（任意）
    if (request.type == AppConstants.requestTypeSubstitute && newStatus == AppConstants.requestStatusApproved && selectedSubstituteId != null) {
      final subStaff = allStaffs.firstWhere((s) => s.id == selectedSubstituteId);
      if (subStaff.userId.isNotEmpty) {
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.notifyUser(
          userId: subStaff.userId,
          title: AppConstants.msgAssignSubstituteTitle,
          body: '${request.date}${AppConstants.labelParticleNi}${staff.name}${AppConstants.msgSubstituteAssignBodySuffix}',
        );
      }
    }

    ref.invalidate(storeRequestsProvider(request.storeId));
    ref.invalidate(staffRequestsProvider(StaffRequestQueryParams(
      staffId: request.staffId,
      storeId: request.storeId,
    )));
    // シフト一覧に関連するプロバイダーも無効化
    ref.invalidate(storeShiftsProvider);
    ref.invalidate(staffShiftsProvider);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppConstants.msgUpdateComplete)));
    }
  }
}
