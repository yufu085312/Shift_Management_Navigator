import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/staff_provider.dart';
import '../../providers/shift_provider.dart';
import '../../models/shift_model.dart';
import '../../models/staff_model.dart';
import '../../core/constants/app_constants.dart';

class ShiftScheduleScreen extends ConsumerStatefulWidget {
  const ShiftScheduleScreen({super.key});

  @override
  ConsumerState<ShiftScheduleScreen> createState() => _ShiftScheduleScreenState();
}

class _ShiftScheduleScreenState extends ConsumerState<ShiftScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(currentStaffProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.titleShiftSchedule),
      ),
      body: staffAsync.when(
        data: (staff) {
          if (staff == null) {
            return const Center(child: Text(AppConstants.labelStaffNotFound));
          }

          final shiftsAsync = ref.watch(storeShiftsProvider(ShiftQueryParams(
            storeId: staff.storeId,
            startDate: DateFormat('yyyy-MM-dd').format(_focusedDay.subtract(const Duration(days: 42))),
            endDate: DateFormat('yyyy-MM-dd').format(_focusedDay.add(const Duration(days: 42))),
          )));

          final staffsAsync = ref.watch(storeStaffsProvider(staff.storeId));

          return Column(
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
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: (day) {
                  final dateStr = DateFormat('yyyy-MM-dd').format(day);
                  final dayShifts = shiftsAsync.value
                      ?.where((s) => s.date == dateStr && s.status == AppConstants.shiftStatusConfirmed)
                      .toList() ?? [];
                  return dayShifts;
                },
                headerStyle: const HeaderStyle(titleCentered: true),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return const SizedBox.shrink();
                    
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: shiftsAsync.when(
                  data: (allShifts) {
                    if (_selectedDay == null) {
                      return const Center(
                        child: Text('日付を選択してください'),
                      );
                    }

                    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
                    final dayShifts = allShifts
                        .where((s) => s.date == selectedDateStr && s.status == AppConstants.shiftStatusConfirmed)
                        .toList();

                    if (dayShifts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              AppConstants.labelShiftNoShifts,
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }

                    return staffsAsync.when(
                      data: (staffs) {
                        // スタッフIDからスタッフ名を取得するマップを作成
                        final staffMap = {for (var s in staffs) s.id: s};

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: dayShifts.length,
                          itemBuilder: (context, index) {
                            final shift = dayShifts[index];
                            final shiftStaff = staffMap[shift.staffId];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    shiftStaff?.name.isNotEmpty == true
                                        ? shiftStaff!.name[0]
                                        : '?',
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ),
                                title: Text(
                                  shiftStaff?.name ?? AppConstants.labelUnknown,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${shift.startTime} 〜 ${shift.endTime}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                trailing: const Icon(Icons.access_time),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Text('${AppConstants.errMsgGeneric}: $error'),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text('${AppConstants.errMsgGeneric}: $error'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('${AppConstants.errMsgGeneric}: $error'),
        ),
      ),
    );
  }
}
