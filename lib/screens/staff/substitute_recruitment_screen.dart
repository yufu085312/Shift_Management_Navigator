import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/staff_provider.dart';
import '../../providers/shift_provider.dart';
import '../../providers/shift_request_provider.dart';
import '../../models/shift_model.dart';
import '../../services/notification_service.dart';

class SubstituteRecruitmentScreen extends ConsumerWidget {
  const SubstituteRecruitmentScreen({super.key});

  Future<void> _volunteer(BuildContext context, WidgetRef ref, ShiftModel shift) async {
    final staff = ref.read(currentStaffProvider).value;
    if (staff == null || shift.requestId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('代打を引き受ける'),
        content: Text('${shift.date} ${shift.startTime}-${shift.endTime} のシフトを引き受けますか？\n（管理者の承認後に確定します）'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('引き受ける')),
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
          title: '代打志願者あり',
          body: '${staff.name}さんが${shift.date}の代打を志願しています。',
        );
      } catch (notifyError) {
        // 通知失敗はログに出力せず静かに処理
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('志願しました。管理者の承認をお待ちください。')),
        );
        ref.invalidate(recruitingSubstitutesProvider(staff.storeId));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('志願処理でエラーが発生しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(currentStaffProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('代打募集一覧')),
      body: staffAsync.when(
        data: (staff) {
          if (staff == null) return const Center(child: Text('スタッフ情報が見つかりません'));

          final recruitmentAsync = ref.watch(recruitingSubstitutesProvider(staff.storeId));

          return recruitmentAsync.when(
            data: (shifts) {
              if (shifts.isEmpty) {
                return const Center(child: Text('現在募集中の代打はありません'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: shifts.length,
                itemBuilder: (context, index) {
                  final shift = shifts[index];
                  // 自分の募集はグレイアウトまたは非表示
                  final isOwn = shift.staffId == staff.id;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('${shift.date} (${shift.startTime} - ${shift.endTime})'),
                      subtitle: Text(isOwn ? '募集中の自分のシフト' : '代打を募集中です'),
                      trailing: isOwn
                          ? const Text('自分の募集', style: TextStyle(color: Colors.grey))
                          : ElevatedButton(
                              onPressed: () => _volunteer(context, ref, shift),
                              child: const Text('引き受ける'),
                            ),
                    ),
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
