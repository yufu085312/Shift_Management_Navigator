import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/shift_provider.dart';
import '../../providers/store_provider.dart';
import '../../models/shift_model.dart';
import '../../models/staff_model.dart';
import '../../services/auto_assign_service.dart';
import '../../services/notification_service.dart';
import '../../core/constants/app_constants.dart';

class ShiftCreateScreen extends ConsumerStatefulWidget {
  const ShiftCreateScreen({super.key});

  @override
  ConsumerState<ShiftCreateScreen> createState() => _ShiftCreateScreenState();
}

class _ShiftCreateScreenState extends ConsumerState<ShiftCreateScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    if (user?.storeId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final staffsAsync = ref.watch(storeStaffsProvider(user!.storeId!));
    final shiftsAsync = ref.watch(storeShiftsProvider(ShiftQueryParams(
      storeId: user.storeId!,
      startDate: DateFormat('yyyy-MM-dd').format(_focusedDay.subtract(const Duration(days: 42))),
      endDate: DateFormat('yyyy-MM-dd').format(_focusedDay.add(const Duration(days: 42))),
    )));

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.titleShiftCreate)),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            headerStyle: const HeaderStyle(titleCentered: true),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle),
              selectedDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            ),
          ),
          const Divider(),
          if (_selectedDay != null)
            Expanded(
              child: shiftsAsync.when(
                data: (shifts) {
                  final dayShifts = shifts.where((s) => s.date == DateFormat('yyyy-MM-dd').format(_selectedDay!)).toList();
                  
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat(AppConstants.labelDateFormatFull, 'ja').format(_selectedDay!),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showShiftDialog(context, date: _selectedDay!),
                              icon: const Icon(Icons.add),
                              label: const Text(AppConstants.labelAdd),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: staffsAsync.when(
                          data: (staffs) {
                            if (dayShifts.isEmpty) return const Center(child: Text(AppConstants.labelShiftNoShifts));
                            return ListView.builder(
                              itemCount: dayShifts.length,
                              itemBuilder: (context, index) {
                                final shift = dayShifts[index];
                                final staff = staffs.firstWhere((s) => s.id == shift.staffId, orElse: () => const StaffModel(id: '', userId: '', storeId: '', name: AppConstants.labelUnknown, hourlyWage: 0));
                                return _ShiftListItem(
                                  shift: shift,
                                  staffName: staff.name,
                                  onEdit: () => _showShiftDialog(context, date: _selectedDay!, shift: shift),
                                  onDelete: () => _confirmDelete(context, shift.id),
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('${AppConstants.errMsgGeneric}: $e')),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('${AppConstants.errMsgGeneric}: $e')),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _selectedDay != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () => _autoAssign(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text(AppConstants.diagAutoAssignTitle),
          ),
          ElevatedButton(
            onPressed: () => _confirmPublish(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            child: const Text(AppConstants.labelPublish),
          ),
        ],
      ),
    );
  }

  void _showShiftDialog(BuildContext context, {required DateTime date, ShiftModel? shift}) {
    showDialog(
      context: context,
      builder: (context) => _ShiftEditDialog(date: date, shift: shift),
    );
  }

  void _confirmDelete(BuildContext context, String shiftId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.diagDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppConstants.labelCancel)),
          TextButton(
            onPressed: () async {
              await ref.read(shiftRepositoryProvider).deleteShift(shiftId);
              if (mounted) {
                Navigator.pop(context);
                ref.invalidate(storeShiftsProvider);
              }
            },
            child: const Text(AppConstants.labelDelete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _autoAssign() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.diagAutoAssignTitle),
        content: const Text(AppConstants.diagAutoAssignConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text(AppConstants.labelCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text(AppConstants.labelOk)),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = ref.read(currentUserProvider).value;
      final store = ref.read(storeProvider(user!.storeId!)).value;
      
      if (store?.plan == AppConstants.planFree) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(AppConstants.diagPlanLimitTitle),
            content: const Text(AppConstants.diagPlanLimitAutoAssign),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppConstants.labelClose)),
            ],
          ),
        );
        return;
      }

      await ref.read(autoAssignServiceProvider).autoAssign(
        storeId: user.storeId!,
        startDate: DateFormat('yyyy-MM-dd').format(_selectedDay!),
        endDate: DateFormat('yyyy-MM-dd').format(_selectedDay!),
      );
      
      ref.invalidate(storeShiftsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppConstants.msgUpdateComplete)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppConstants.errMsgAutoAssign}: $e')));
    }
  }

  Future<void> _confirmPublish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.diagPublishConfirm),
        content: const Text(AppConstants.diagPublishNotice),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text(AppConstants.labelCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text(AppConstants.labelPublish)),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = ref.read(currentUserProvider).value;
      final publishDate = DateFormat('yyyy-MM-dd').format(_selectedDay!);
      await ref.read(shiftRepositoryProvider).publishShifts(
        storeId: user!.storeId!,
        startDate: publishDate,
        endDate: publishDate,
      );
      
      ref.invalidate(storeShiftsProvider);
      
      // 通知送信
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.notifyAllStaff(
        storeId: user.storeId!,
        title: AppConstants.notifShiftPublishedTitle,
        body: '${DateFormat('yyyy/MM/dd').format(_selectedDay!)}${AppConstants.msgShiftPublishedBodySuffix}',
      );

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppConstants.msgPublishSuccess)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppConstants.errMsgGeneric}: $e')));
    }
  }
}

class _ShiftListItem extends StatelessWidget {
  final ShiftModel shift;
  final String staffName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ShiftListItem({
    required this.shift,
    required this.staffName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDraft = shift.status == AppConstants.shiftStatusDraft;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(staffName),
        subtitle: Text('${shift.startTime} - ${shift.endTime}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDraft ? Colors.orange.shade100 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isDraft ? AppConstants.labelDraft : AppConstants.labelConfirmed,
                style: TextStyle(color: isDraft ? Colors.orange : Colors.blue, fontSize: 12),
              ),
            ),
            IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

class _ShiftEditDialog extends ConsumerStatefulWidget {
  final DateTime date;
  final ShiftModel? shift;

  const _ShiftEditDialog({required this.date, this.shift});

  @override
  ConsumerState<_ShiftEditDialog> createState() => _ShiftEditDialogState();
}

class _ShiftEditDialogState extends ConsumerState<_ShiftEditDialog> {
  String? _selectedStaffId;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  String _status = AppConstants.shiftStatusDraft;

  @override
  void initState() {
    super.initState();
    if (widget.shift != null) {
      _selectedStaffId = widget.shift!.staffId;
      _startTime = _parseTime(widget.shift!.startTime);
      _endTime = _parseTime(widget.shift!.endTime);
      _status = widget.shift!.status;
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(currentUserProvider).value;
    final staffsAsync = ref.watch(storeStaffsProvider(user!.storeId!));

    return AlertDialog(
      title: Text(widget.shift == null ? AppConstants.labelAdd : AppConstants.labelEdit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 日付表示
            ListTile(
              title: const Text(AppConstants.labelSelectedDate),
              subtitle: Text(DateFormat(AppConstants.labelDateFormatFull, 'ja').format(widget.date)),
            ),
            // スタッフ選択
            staffsAsync.when(
              data: (staffs) => DropdownButtonFormField<String>(
                value: _selectedStaffId,
                decoration: const InputDecoration(labelText: AppConstants.labelStaff),
                items: staffs.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: widget.shift != null ? null : (v) => setState(() => _selectedStaffId = v),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('${AppConstants.errMsgGeneric}: $e'),
            ),
            // 開始時刻
            ListTile(
              title: const Text(AppConstants.labelTimeStart),
              trailing: TextButton(
                onPressed: () async {
                  final time = await showTimePicker(context: context, initialTime: _startTime);
                  if (time != null) setState(() => _startTime = time);
                },
                child: Text(_formatTime(_startTime)),
              ),
            ),
            // 終了時刻
            ListTile(
              title: const Text(AppConstants.labelTimeEnd),
              trailing: TextButton(
                onPressed: () async {
                  final time = await showTimePicker(context: context, initialTime: _endTime);
                  if (time != null) setState(() => _endTime = time);
                },
                child: Text(_formatTime(_endTime)),
              ),
            ),
            // ステータス設定
            if (widget.shift != null)
              DropdownButtonFormField<String>(
                value: _status,
                items: [
                  DropdownMenuItem(value: AppConstants.shiftStatusDraft, child: const Text(AppConstants.labelDraft)),
                  DropdownMenuItem(value: AppConstants.shiftStatusConfirmed, child: const Text(AppConstants.labelConfirmed)),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppConstants.labelCancel)),
        TextButton(
          onPressed: _selectedStaffId == null ? null : () async {
            try {
              if (widget.shift == null) {
                // 新規作成
                await ref.read(shiftRepositoryProvider).createShift(
                  storeId: user.storeId!,
                  staffId: _selectedStaffId!,
                  date: DateFormat('yyyy-MM-dd').format(widget.date),
                  startTime: _formatTime(_startTime),
                  endTime: _formatTime(_endTime),
                  status: _status,
                );
              } else {
                // 更新
                await ref.read(shiftRepositoryProvider).updateShift(
                  shiftId: widget.shift!.id,
                  startTime: _formatTime(_startTime),
                  endTime: _formatTime(_endTime),
                  status: _status,
                );
              }
              if (mounted) {
                Navigator.pop(context);
                ref.invalidate(storeShiftsProvider);
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppConstants.errMsgGeneric}: $e')));
            }
          },
          child: const Text(AppConstants.labelSave),
        ),
      ],
    );
  }
}
