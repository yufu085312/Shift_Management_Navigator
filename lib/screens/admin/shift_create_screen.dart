import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/shift_provider.dart';
import '../../models/shift_model.dart';
import '../../models/staff_model.dart';
import '../../providers/store_provider.dart';
import '../../services/auto_assign_service.dart';
import '../../services/notification_service.dart';

class ShiftCreateScreen extends ConsumerStatefulWidget {
  const ShiftCreateScreen({super.key});

  @override
  ConsumerState<ShiftCreateScreen> createState() => _ShiftCreateScreenState();
}

class _ShiftCreateScreenState extends ConsumerState<ShiftCreateScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;

  Future<void> _handleAutoAssign(BuildContext context) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser?.storeId == null) return;

    final store = ref.read(storeProvider(currentUser!.storeId!)).value;
    if (store == null) return;

    // プランチェック (Freeプランは不可)
    if (store.plan == 'free') {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('プラン制限'),
          content: const Text('自動割当機能はBasicプラン以上でご利用いただけます。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // 週の開始日と終了日を計算
    final weekStart = _focusedDay.subtract(Duration(days: _focusedDay.weekday % 7));
    final weekEnd = weekStart.add(const Duration(days: 6));

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自動割当を実行'),
        content: Text(
          '${DateFormat('M月d日').format(weekStart)} 〜 ${DateFormat('M月d日').format(weekEnd)} の期間で、スタッフの希望に基づきシフトを自動作成しますか？\n\n※既存のシフトは上書きされません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('実行する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final autoAssignService = ref.read(autoAssignServiceProvider);
      final count = await autoAssignService.autoAssign(
        storeId: currentUser.storeId!,
        startDate: DateFormat('yyyy-MM-dd').format(weekStart),
        endDate: DateFormat('yyyy-MM-dd').format(weekEnd),
      );

      if (context.mounted) {
        ref.invalidate(storeShiftsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count件のシフトを自動作成しました。'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('自動割当中にエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('シフト作成'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '更新',
            onPressed: () {
              ref.invalidate(storeShiftsProvider);
              ref.invalidate(storeStaffsProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('最新の情報を取得しました')),
              );
            },
          ),
          // 自動割当ボタン
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: '自動割当',
            onPressed: () => _handleAutoAssign(context),
          ),
          // シフト公開ボタン
          IconButton(
            icon: const Icon(Icons.publish),
            tooltip: 'シフト公開',
            onPressed: () => _showPublishDialog(context),
          ),
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

          return Column(
            children: [
              // カレンダー
              _buildCalendar(user.storeId!),
              
              const Divider(height: 1),
              
              // 選択日のシフト一覧
              Expanded(
                child: _selectedDay != null
                    ? _buildShiftList(user.storeId!, _selectedDay!)
                    : const Center(
                        child: Text('日付を選択してください'),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
      floatingActionButton: _selectedDay != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddShiftDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('シフト追加'),
            )
          : null,
    );
  }

  Widget _buildCalendar(String storeId) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: TableCalendar(
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
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: const CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.blueGrey,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
        ),
      ),
    );
  }

  Widget _buildShiftList(String storeId, DateTime selectedDay) {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
    final shiftsAsync = ref.watch(storeShiftsProvider(ShiftQueryParams(
      storeId: storeId,
      startDate: dateStr,
      endDate: dateStr,
    )));
    final staffsAsync = ref.watch(storeStaffsProvider(storeId));

    return shiftsAsync.when(
      data: (shifts) {
        if (shifts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  '${DateFormat('M月d日(E)', 'ja').format(selectedDay)}のシフトはありません',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '右下のボタンからシフトを追加してください',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return staffsAsync.when(
          data: (staffs) {
            final staffMap = {for (var s in staffs) s.id: s};
            
            return ListView.builder(
              itemCount: shifts.length,
              itemBuilder: (context, index) {
                final shift = shifts[index];
                final staff = staffMap[shift.staffId];
                
                return _ShiftListItem(
                  shift: shift,
                  staff: staff,
                  onEdit: () => _showEditShiftDialog(context, shift, staffs),
                  onDelete: () => _confirmDeleteShift(context, shift),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('エラー: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('エラー: $error')),
    );
  }

  void _showAddShiftDialog(BuildContext context) {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser?.storeId == null || _selectedDay == null) return;

    final staffsAsync = ref.read(storeStaffsProvider(currentUser!.storeId!));
    staffsAsync.when(
      data: (staffs) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (context) => _ShiftDialog(
            storeId: currentUser.storeId!,
            date: _selectedDay!,
            staffs: staffs,
          ),
        );
      },
      loading: () {},
      error: (_, _) {},
    );
  }

  void _showEditShiftDialog(BuildContext context, ShiftModel shift, List<StaffModel> staffs) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => _ShiftDialog(
        storeId: shift.storeId,
        date: DateTime.parse(shift.date),
        staffs: staffs,
        shift: shift,
      ),
    );
  }

  void _confirmDeleteShift(BuildContext context, ShiftModel shift) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('シフトを削除'),
        content: const Text('このシフトを削除してもよろしいですか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              final shiftRepository = ref.read(shiftRepositoryProvider);
              await shiftRepository.deleteShift(shift.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ref.invalidate(storeShiftsProvider);
              }
            },
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showPublishDialog(BuildContext context) {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser?.storeId == null) return;

    // 現在のフォーカス日の週の開始日と終了日を計算
    final weekStart = _focusedDay.subtract(Duration(days: _focusedDay.weekday % 7));
    final weekEnd = weekStart.add(const Duration(days: 6));

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('シフトを公開'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('以下の期間のシフトを公開しますか?'),
            const SizedBox(height: 16),
            Text(
              '${DateFormat('M月d日(E)', 'ja').format(weekStart)} 〜 ${DateFormat('M月d日(E)', 'ja').format(weekEnd)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '公開すると、スタッフに通知が送信されます。',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final shiftRepository = ref.read(shiftRepositoryProvider);
                await shiftRepository.publishShifts(
                  storeId: currentUser!.storeId!,
                  startDate: DateFormat('yyyy-MM-dd').format(weekStart),
                  endDate: DateFormat('yyyy-MM-dd').format(weekEnd),
                );

                // スタッフ全員に通知を送信
                final notificationService = ref.read(notificationServiceProvider);
                await notificationService.notifyAllStaff(
                  storeId: currentUser.storeId!,
                  title: 'シフトが公開されました',
                  body: '${DateFormat('M/d').format(weekStart)}〜${DateFormat('M/d').format(weekEnd)}のシフトが確定しました。',
                );

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ref.invalidate(storeShiftsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('シフトを公開しました'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('エラー: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('公開'),
          ),
        ],
      ),
    );
  }
}

class _ShiftListItem extends StatelessWidget {
  final ShiftModel shift;
  final StaffModel? staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ShiftListItem({
    required this.shift,
    required this.staff,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(staff?.name.isNotEmpty == true ? staff!.name[0] : '?'),
        ),
        title: Text(staff?.name ?? '未設定'),
        subtitle: Text('${shift.startTime} - ${shift.endTime}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (shift.status == 'draft')
              const Chip(
                label: Text('下書き', style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.orange,
                labelPadding: EdgeInsets.symmetric(horizontal: 8),
              )
            else
              const Chip(
                label: Text('確定', style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.green,
                labelPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftDialog extends ConsumerStatefulWidget {
  final String storeId;
  final DateTime date;
  final List<StaffModel> staffs;
  final ShiftModel? shift;

  const _ShiftDialog({
    required this.storeId,
    required this.date,
    required this.staffs,
    this.shift,
  });

  @override
  ConsumerState<_ShiftDialog> createState() => _ShiftDialogState();
}

class _ShiftDialogState extends ConsumerState<_ShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedStaffId;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.shift != null) {
      _selectedStaffId = widget.shift!.staffId;
      _startTime = _parseTime(widget.shift!.startTime);
      _endTime = _parseTime(widget.shift!.endTime);
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final initialTime = isStart
        ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 18, minute: 0));

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('スタッフを選択してください')),
      );
      return;
    }
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('時間を設定してください')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final shiftRepository = ref.read(shiftRepositoryProvider);
      final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);

      if (widget.shift == null) {
        // 新規作成
        await shiftRepository.createShift(
          storeId: widget.storeId,
          staffId: _selectedStaffId!,
          date: dateStr,
          startTime: _formatTime(_startTime!),
          endTime: _formatTime(_endTime!),
        );
      } else {
        // 更新
        await shiftRepository.updateShift(
          shiftId: widget.shift!.id,
          staffId: _selectedStaffId,
          startTime: _formatTime(_startTime!),
          endTime: _formatTime(_endTime!),
        );
      }

      if (mounted) {
        ref.invalidate(storeShiftsProvider);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Colors.red,
          ),
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
    return AlertDialog(
      title: Text(widget.shift == null ? 'シフト追加' : 'シフト編集'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 日付表示
              Text(
                DateFormat('yyyy年M月d日(E)', 'ja').format(widget.date),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // スタッフ選択
              DropdownButtonFormField<String>(
                initialValue: _selectedStaffId,
                decoration: const InputDecoration(
                  labelText: 'スタッフ',
                  prefixIcon: Icon(Icons.person),
                ),
                items: widget.staffs.map((staff) {
                  return DropdownMenuItem(
                    value: staff.id,
                    child: Text(staff.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStaffId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'スタッフを選択してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 開始時刻
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('開始時刻'),
                trailing: TextButton(
                  onPressed: () => _selectTime(context, true),
                  child: Text(
                    _startTime != null
                        ? _formatTime(_startTime!)
                        : '選択してください',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              // 終了時刻
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('終了時刻'),
                trailing: TextButton(
                  onPressed: () => _selectTime(context, false),
                  child: Text(
                    _endTime != null
                        ? _formatTime(_endTime!)
                        : '選択してください',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.shift == null ? '追加' : '更新'),
        ),
      ],
    );
  }
}
