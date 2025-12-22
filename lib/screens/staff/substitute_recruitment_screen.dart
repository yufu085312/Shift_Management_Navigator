import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/staff_provider.dart';
import '../../providers/shift_provider.dart';
import '../../providers/shift_request_provider.dart';
import '../../models/shift_model.dart';
import '../../services/notification_service.dart';
import '../../core/constants/app_constants.dart';

class SubstituteRecruitmentScreen extends ConsumerWidget {
  const SubstituteRecruitmentScreen({super.key});

  Future<void> _volunteer(BuildContext context, WidgetRef ref, ShiftModel shift) async {
    final staff = ref.read(currentStaffProvider).value;
    if (staff == null || shift.requestId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.labelTakeSubstitute),
        content: Text('${shift.date} ${shift.startTime}-${shift.endTime} ${AppConstants.msgSubstituteConfirm}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text(AppConstants.labelCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text(AppConstants.labelAccept)),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(shiftRequestRepositoryProvider);
      await repository.volunteerForSubstitute(shift.requestId!, staff.id);

      try {
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.notifyAdmins(
          storeId: staff.storeId,
          title: AppConstants.msgVolunteerExists,
          body: '${staff.name}${AppConstants.msgVolunteerBodySuffix}',
        );
      } catch (notifyError) {
        // 通知失敗はログに出力せず静かに処理
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.msgVolunteerSuccess)),
        );
        ref.invalidate(recruitingSubstitutesProvider(staff.storeId));
        ref.invalidate(staffRequestsProvider);
        ref.invalidate(staffShiftsProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppConstants.errMsgGeneric}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(currentStaffProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.labelSubstituteRecruitment)),
      body: staffAsync.when(
        data: (staff) {
          if (staff == null) return const Center(child: Text(AppConstants.labelStaffNotFound));

          final recruitmentAsync = ref.watch(recruitingSubstitutesProvider(staff.storeId));

          return recruitmentAsync.when(
            data: (shifts) {
              if (shifts.isEmpty) {
                return const Center(child: Text(AppConstants.msgNoSubstituteRecruitment));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: shifts.length,
                itemBuilder: (context, index) {
                  final shift = shifts[index];
                  // 自分の募集はグレイアウトまたは非表示
                  final isOwn = shift.staffId == staff.id;
                  final hasVolunteer = shift.volunteerStaffId != null;
                  final isVolunteer = shift.volunteerStaffId == staff.id;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('${shift.date} (${shift.startTime} - ${shift.endTime})'),
                      subtitle: Text(isOwn ? AppConstants.msgOwnRecruitment : AppConstants.msgRecruitingSubstitute),
                      trailing: isOwn
                          ? const Text(AppConstants.labelOwnRecruitment, style: TextStyle(color: Colors.grey))
                          : hasVolunteer
                              ? Text(isVolunteer ? AppConstants.labelAlreadyVolunteered : AppConstants.labelVolunteerInProgress,
                                  style: TextStyle(color: isVolunteer ? Colors.orange : Colors.grey))
                              : ElevatedButton(
                                  onPressed: () => _volunteer(context, ref, shift),
                                  child: const Text(AppConstants.labelAccept),
                                ),
                    ),
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
