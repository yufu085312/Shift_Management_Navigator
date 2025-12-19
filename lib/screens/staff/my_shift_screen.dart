import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/shift_provider.dart';
import '../../models/staff_model.dart';
import 'wish_submission_screen.dart';
import 'change_request_screen.dart';
import 'notifications_screen.dart';

class MyShiftScreen extends ConsumerStatefulWidget {
  const MyShiftScreen({super.key});

  @override
  ConsumerState<MyShiftScreen> createState() => _MyShiftScreenState();
}

class _MyShiftScreenState extends ConsumerState<MyShiftScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(currentStaffProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイシフト'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(staffShiftsProvider);
              ref.invalidate(currentStaffProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('情報を更新しました')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
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
      body: staffAsync.when(
        data: (staff) {
          if (staff == null) {
            return const Center(child: Text('スタッフ情報が見つかりません'));
          }

          return Column(
            children: [
              _buildCalendar(),
              const Divider(height: 1),
              Expanded(
                child: _buildShiftInfo(staff),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'メニュー',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('マイシフト'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar),
              title: const Text('シフト希望提出'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WishSubmissionScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('変更・代打申請'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangeRequestScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
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
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
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
    );
  }

  Widget _buildShiftInfo(StaffModel staff) {
    if (_selectedDay == null) {
      return const Center(child: Text('日付を選択してください'));
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final shiftsAsync = ref.watch(staffShiftsProvider(StaffShiftQueryParams(
      staffId: staff.id,
      storeId: staff.storeId,
      startDate: dateStr,
      endDate: dateStr,
    )));

    return shiftsAsync.when(
      data: (allShifts) {
        if (allShifts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('この日のシフトはありません'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: allShifts.length,
          itemBuilder: (context, index) {
            final shift = allShifts[index];
            final isDraft = shift.status == 'draft';
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Icon(
                  Icons.access_time, 
                  color: isDraft ? Colors.orange : Colors.blue
                ),
                title: Text(
                  '勤務時間${isDraft ? ' (承認済み・公開待ち)' : ''}',
                  style: isDraft ? const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold) : null,
                ),
                subtitle: Text('${shift.startTime} - ${shift.endTime}'),
                trailing: Icon(
                  isDraft ? Icons.pending : Icons.check_circle, 
                  color: isDraft ? Colors.orange : Colors.green
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('エラー: $error')),
    );
  }
}
