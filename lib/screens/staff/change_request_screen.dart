import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/staff_provider.dart';
import '../../providers/shift_provider.dart';
import '../../providers/shift_request_provider.dart';
import '../../models/shift_model.dart';
import '../../services/notification_service.dart';

class ChangeRequestScreen extends ConsumerStatefulWidget {
  const ChangeRequestScreen({super.key});

  @override
  ConsumerState<ChangeRequestScreen> createState() => _ChangeRequestScreenState();
}

class _ChangeRequestScreenState extends ConsumerState<ChangeRequestScreen> {
  ShiftModel? _selectedShift;
  String _requestType = 'change'; // 'change' or 'substitute'
  String? _newStartTime;
  String? _newEndTime;
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_selectedShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('対象のシフトを選択してください')),
      );
      return;
    }

    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('理由を入力してください')),
      );
      return;
    }

    if (_requestType == 'change' && (_newStartTime == null || _newEndTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('変更後の時間を指定してください')),
      );
      return;
    }

    final staff = ref.read(currentStaffProvider).value;
    if (staff == null) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(shiftRequestRepositoryProvider);
      
      await repository.createRequest(
        storeId: staff.storeId,
        staffId: staff.id,
        type: _requestType,
        date: _selectedShift!.date,
        startTime: _requestType == 'change' ? _newStartTime : _selectedShift!.startTime,
        endTime: _requestType == 'change' ? _newEndTime : _selectedShift!.endTime,
        reason: _reasonController.text,
        targetShiftId: _selectedShift!.id,
      );

      // 通知処理 (失敗しても申請自体は完了とする)
      try {
        final notificationService = ref.read(notificationServiceProvider);
        if (_requestType == 'substitute') {
          await notificationService.notifyAllStaff(
            storeId: staff.storeId,
            title: '代打募集中',
            body: '${staff.name}さんが${_selectedShift!.date}の代打を募集しています。',
          );
        } else if (_requestType == 'change') {
          await notificationService.notifyAdmins(
            storeId: staff.storeId,
            title: '時間変更申請',
            body: '${staff.name}さんが${_selectedShift!.date}の時間を $_newStartTime - $_newEndTime へ変更申請しました。',
          );
        }
      } catch (notifyError) {
        // 通知失敗はログに出力せず静かに処理
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('申請を提出しました')),
        );
        Navigator.pop(context);
        ref.invalidate(staffRequestsProvider(staff.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(currentStaffProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('変更・代打申請')),
      body: staffAsync.when(
        data: (staff) {
          if (staff == null) return const Center(child: Text('スタッフ情報が見つかりません'));

          // 直近30日の自分のシフトを取得
          final now = DateTime.now();
          final startDate = DateFormat('yyyy-MM-dd').format(now);
          final endDate = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 30)));

          final shiftsAsync = ref.watch(staffShiftsProvider(StaffShiftQueryParams(
            staffId: staff.id,
            storeId: staff.storeId,
            startDate: startDate,
            endDate: endDate,
          )));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '申請種類を選択',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('時間変更'),
                        value: 'change',
                        groupValue: _requestType,
                        onChanged: (v) => setState(() => _requestType = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('代打希望'),
                        value: 'substitute',
                        groupValue: _requestType,
                        onChanged: (v) => setState(() => _requestType = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  '対象のシフトを選択',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                shiftsAsync.when(
                  data: (shifts) {
                    final confirmedShifts = shifts.where((s) => s.status == 'confirmed').toList();
                    if (confirmedShifts.isEmpty) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('予定されているシフトはありません'),
                      ));
                    }

                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: confirmedShifts.length,
                        itemBuilder: (context, index) {
                          final shift = confirmedShifts[index];
                          final isSelected = _selectedShift?.id == shift.id;
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: Colors.blue.withValues(alpha: 0.1),
                            title: Text(shift.date),
                            subtitle: Text('${shift.startTime} - ${shift.endTime}'),
                            onTap: () => setState(() => _selectedShift = shift),
                            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('エラー: $e'),
                ),
                if (_requestType == 'change' && _selectedShift != null) ...[
                  const SizedBox(height: 24),
                  const Text(
                    '変更後の時間を指定',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _newStartTime != null 
                                ? TimeOfDay(
                                    hour: int.parse(_newStartTime!.split(':')[0]), 
                                    minute: int.parse(_newStartTime!.split(':')[1])
                                  )
                                : TimeOfDay(
                                    hour: int.parse(_selectedShift!.startTime.split(':')[0]), 
                                    minute: int.parse(_selectedShift!.startTime.split(':')[1])
                                  ),
                            );
                            if (time != null) {
                              setState(() => _newStartTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
                            }
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text(_newStartTime ?? '開始時間'),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('〜'),
                      ),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _newEndTime != null 
                                ? TimeOfDay(
                                    hour: int.parse(_newEndTime!.split(':')[0]), 
                                    minute: int.parse(_newEndTime!.split(':')[1])
                                  )
                                : TimeOfDay(
                                    hour: int.parse(_selectedShift!.endTime.split(':')[0]), 
                                    minute: int.parse(_selectedShift!.endTime.split(':')[1])
                                  ),
                            );
                            if (time != null) {
                              setState(() => _newEndTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
                            }
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text(_newEndTime ?? '終了時間'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: '理由・メッセージ',
                    hintText: '例: 急用のため代わりをお願いしたいです。',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('申請を送信する', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
      ),
    );
  }
}
