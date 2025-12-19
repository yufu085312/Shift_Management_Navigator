import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/staff_provider.dart';
import '../../providers/shift_request_provider.dart';

class WishSubmissionScreen extends ConsumerStatefulWidget {
  const WishSubmissionScreen({super.key});

  @override
  ConsumerState<WishSubmissionScreen> createState() => _WishSubmissionScreenState();
}

class _WishSubmissionScreenState extends ConsumerState<WishSubmissionScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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

  Future<void> _submitWish() async {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日付を選択してください')),
      );
      return;
    }

    final staff = ref.read(currentStaffProvider).value;
    if (staff == null) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(shiftRequestRepositoryProvider);
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
      
      String? startTimeStr;
      String? endTimeStr;
      if (_startTime != null && _endTime != null) {
        startTimeStr = '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
        endTimeStr = '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';
      }

      await repository.createRequest(
        storeId: staff.storeId,
        staffId: staff.id,
        type: 'wish',
        date: dateStr,
        startTime: startTimeStr,
        endTime: endTimeStr,
        reason: _reasonController.text.isEmpty ? null : _reasonController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('シフト希望を提出しました')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('シフト希望提出')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '希望する日付を選択してください',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 90)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blueGrey,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedDay != null) ...[
              Text(
                '選択日: ${DateFormat('yyyy年M月d日(E)', 'ja').format(_selectedDay!)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('希望時間(未指定の場合は終日)'),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectTime(context, true),
                      icon: const Icon(Icons.access_time),
                      label: Text(_startTime?.format(context) ?? '開始時間'),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('〜'),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectTime(context, false),
                      icon: const Icon(Icons.access_time),
                      label: Text(_endTime?.format(context) ?? '終了時間'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: '備考・理由 (任意)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitWish,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('提出する', style: TextStyle(fontSize: 18)),
                ),
              ),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('カレンダーから日付を選択してください'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
