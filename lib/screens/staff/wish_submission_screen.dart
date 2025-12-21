import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/shift_request_provider.dart';
import '../../core/constants/app_constants.dart';

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

  Future<void> _submitWish() async {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.valSelectDate)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final staff = ref.read(currentStaffProvider).value;
      if (staff == null) throw Exception(AppConstants.labelStaffNotFound);

      final repository = ref.read(shiftRequestRepositoryProvider);
      
      await repository.createRequest(
        staffId: staff.id,
        storeId: staff.storeId,
        date: DateFormat('yyyy-MM-dd').format(_selectedDay!),
        type: AppConstants.requestTypeWish,
        startTime: _startTime != null ? _formatTime(_startTime!) : null,
        endTime: _endTime != null ? _formatTime(_endTime!) : null,
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.msgRequestSubmitted)),
        );
        ref.invalidate(staffRequestsProvider);
        Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.titleWishSubmission)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppConstants.valSelectDate, style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TableCalendar(
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
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              headerStyle: const HeaderStyle(titleCentered: true),
            ),
            const SizedBox(height: 24),
            
            if (_selectedDay != null) ...[
              Text(
                '${AppConstants.labelSelectedDate}: ${DateFormat(AppConstants.labelDateFormatFull, 'ja').format(_selectedDay!)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 24),
              const Text(AppConstants.labelWishTimeHint, style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
                        if (time != null) setState(() => _startTime = time);
                      },
                      child: Text(_startTime?.format(context) ?? AppConstants.labelTimeStart),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('〜')),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
                        if (time != null) setState(() => _endTime = time);
                      },
                      child: Text(_endTime?.format(context) ?? AppConstants.labelTimeEnd),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(AppConstants.labelReasonOptional, style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  hintText: AppConstants.labelReasonDefaultHint,
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitWish,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text(AppConstants.labelSubmit),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
