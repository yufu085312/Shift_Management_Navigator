import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/staff_provider.dart';
import '../../providers/shift_provider.dart';
import '../../providers/shift_request_provider.dart';
import '../../models/shift_model.dart';

class ChangeRequestScreen extends ConsumerStatefulWidget {
  const ChangeRequestScreen({super.key});

  @override
  ConsumerState<ChangeRequestScreen> createState() => _ChangeRequestScreenState();
}

class _ChangeRequestScreenState extends ConsumerState<ChangeRequestScreen> {
  ShiftModel? _selectedShift;
  String _requestType = 'change'; // 'change' or 'substitute'
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
        startTime: _selectedShift!.startTime,
        endTime: _selectedShift!.endTime,
        reason: _reasonController.text,
      );

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
          SnackBar(content: Text('エラー: $e')),
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
