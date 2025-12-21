import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/shift_provider.dart';
import '../../providers/shift_request_provider.dart';
import '../../models/shift_model.dart';
import '../../services/notification_service.dart';
import '../../core/constants/app_constants.dart';

class ChangeRequestScreen extends ConsumerStatefulWidget {
  const ChangeRequestScreen({super.key});

  @override
  ConsumerState<ChangeRequestScreen> createState() => _ChangeRequestScreenState();
}

class _ChangeRequestScreenState extends ConsumerState<ChangeRequestScreen> {
  String _requestType = AppConstants.requestTypeChange; // デフォルトは時間変更
  ShiftModel? _selectedShift;
  TimeOfDay? _newStartTime;
  TimeOfDay? _newEndTime;
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
        const SnackBar(content: Text(AppConstants.valSelectTargetShift)),
      );
      return;
    }

    if (_requestType == AppConstants.requestTypeChange && (_newStartTime == null || _newEndTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.valSetNewTime)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final staff = ref.read(currentStaffProvider).value;
      if (staff == null) throw Exception(AppConstants.labelStaffNotFound);

      final repository = ref.read(shiftRequestRepositoryProvider);
      
      // createRequestの中でシフトの更新も行われる
      await repository.createRequest(
        staffId: staff.id,
        storeId: staff.storeId,
        date: _selectedShift!.date,
        type: _requestType,
        startTime: _requestType == AppConstants.requestTypeChange ? _formatTime(_newStartTime!) : _selectedShift!.startTime,
        endTime: _requestType == AppConstants.requestTypeChange ? _formatTime(_newEndTime!) : _selectedShift!.endTime,
        reason: _reasonController.text.trim(),
        targetShiftId: _selectedShift!.id,
      );

      // 通知処理 (失敗しても申請自体は完了とする)
      try {
        final notificationService = ref.read(notificationServiceProvider);
        if (_requestType == AppConstants.requestTypeSubstitute) {
          await notificationService.notifyAllStaff(
            storeId: staff.storeId,
            title: AppConstants.notifSubstituteTitle,
            body: '${staff.name}${AppConstants.msgRecruitSubstituteBody}',
            excludeUserId: staff.userId,
          );
        } else {
          await notificationService.notifyAdmins(
            storeId: staff.storeId,
            title: AppConstants.notifChangeRequestTitle,
            body: '${staff.name}${AppConstants.msgTimeChangeRequestBody}',
          );
        }
      } catch (notifyError) {
        // 通知失敗はログに出力せず静かに処理
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.msgRequestSubmitted)),
        );
        ref.invalidate(staffShiftsProvider);
        ref.invalidate(staffRequestsProvider);
        ref.invalidate(storeRequestsProvider); // 管理者側の通知用
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppConstants.errMsgGeneric}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(currentStaffProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.titleChangeRequest)),
      body: staffAsync.when(
        data: (staff) {
          if (staff == null) return const Center(child: Text(AppConstants.labelStaffNotFound));

          // 直近30日の自分のシフトを取得
          final now = DateTime.now();
          final shiftsAsync = ref.watch(staffShiftsProvider(StaffShiftQueryParams(
            staffId: staff.id,
            storeId: staff.storeId,
            startDate: DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 7))),
            endDate: DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 30))),
          )));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.labelSelectRequestType, style: Theme.of(context).textTheme.titleMedium),
                RadioListTile<String>(
                  title: const Text(AppConstants.labelChangeTime),
                  value: AppConstants.requestTypeChange,
                  groupValue: _requestType,
                  onChanged: (v) => setState(() => _requestType = v!),
                ),
                RadioListTile<String>(
                  title: const Text(AppConstants.labelSubstituteWish),
                  value: AppConstants.requestTypeSubstitute,
                  groupValue: _requestType,
                  onChanged: (v) => setState(() => _requestType = v!),
                ),
                const SizedBox(height: 24),

                Text(AppConstants.labelSelectTargetShift, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                shiftsAsync.when(
                  data: (shifts) {
                    final upcomingShifts = shifts.where((s) => s.requestId == null).toList();
                    if (upcomingShifts.isEmpty) return const Text(AppConstants.labelNoScheduledShifts);

                    return DropdownButtonFormField<ShiftModel>(
                      value: _selectedShift,
                      hint: const Text(AppConstants.labelSelect),
                      items: upcomingShifts.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s.date} ${s.startTime}-${s.endTime}'),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedShift = v),
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('${AppConstants.errMsgGeneric}: $e'),
                ),
                const SizedBox(height: 24),

                if (_requestType == AppConstants.requestTypeChange) ...[
                  Text(AppConstants.labelSetNewTime, style: Theme.of(context).textTheme.titleMedium),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
                            if (time != null) setState(() => _newStartTime = time);
                          },
                          child: Text(_newStartTime?.format(context) ?? AppConstants.labelTimeStart),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('〜')),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
                            if (time != null) setState(() => _newEndTime = time);
                          },
                          child: Text(_newEndTime?.format(context) ?? AppConstants.labelTimeEnd),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                Text(AppConstants.labelReasonMessage, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    hintText: AppConstants.labelReasonHint,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isLoading ? const CircularProgressIndicator() : const Text(AppConstants.labelSubmitRequest),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${AppConstants.errMsgGeneric}: $e')),
      ),
    );
  }
}
