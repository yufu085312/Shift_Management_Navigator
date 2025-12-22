import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/shift_provider.dart';
import '../../models/shift_model.dart';
import '../../models/shift_request_model.dart';
import 'wish_submission_screen.dart';
import 'change_request_screen.dart';
import 'notifications_screen.dart';
import 'substitute_recruitment_screen.dart';
import '../../providers/shift_request_provider.dart';
import '../../core/constants/app_constants.dart';

class MyShiftScreen extends ConsumerStatefulWidget {
  const MyShiftScreen({super.key});

  @override
  ConsumerState<MyShiftScreen> createState() => _MyShiftScreenState();
}

class _MyShiftScreenState extends ConsumerState<MyShiftScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  void _confirmLeaveStore(BuildContext context) {
    final staff = ref.read(currentStaffProvider).value;
    if (staff == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.diagLeaveStoreTitle),
        content: const Text(AppConstants.diagLeaveStoreConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppConstants.labelCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // ScaffoldMessengerを先に取得（invalidate後はcontextが無効になるため）
              final messenger = ScaffoldMessenger.of(context);
              
              try {
                final staffRepository = ref.read(staffRepositoryProvider);
                final authRepository = ref.read(authRepositoryProvider);
                final user = ref.read(currentUserProvider).value;

                if (user == null || user.storeId == null) return;

                final storeIdForMessage = user.storeId!;

                // 重要: ユーザー情報の storeId を更新する前に、シフトと申請を削除
                // （isSameStore() が正しく評価されるため）
                await staffRepository.leaveStore(
                  userId: user.uid,
                  storeId: user.storeId!,
                );

                // ユーザー情報のstoreIdをnullにする
                await authRepository.updateUserData(
                  uid: user.uid,
                  clearStoreId: true,
                );

                // プロバイダーを無効化（これにより画面が再構築される）
                ref.invalidate(currentUserProvider);
                ref.invalidate(currentStaffProvider);

                // 成功メッセージを表示
                messenger.showSnackBar(
                  SnackBar(content: Text('$storeIdForMessage${AppConstants.msgLeaveSuccess}')),
                );
              } catch (e) {
                // エラーメッセージを表示
                messenger.showSnackBar(
                  SnackBar(content: Text('${AppConstants.errMsgGeneric}: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text(AppConstants.labelLeaveStore, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(currentStaffProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.titleMyShift),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: AppConstants.titleNotifications,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                AppConstants.labelMenu,
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text(AppConstants.labelSubstituteRecruitment),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SubstituteRecruitmentScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text(AppConstants.labelLeaveStore, style: TextStyle(color: Colors.red)),
              onTap: () => _confirmLeaveStore(context),
            ),
          ],
        ),
      ),
      body: staffAsync.when(
        data: (staff) {
          if (staff == null) return const Center(child: Text(AppConstants.labelStaffNotFound));

          final shiftsAsync = ref.watch(staffShiftsProvider(StaffShiftQueryParams(
            staffId: staff.id,
            storeId: staff.storeId,
            startDate: DateFormat('yyyy-MM-dd').format(_focusedDay.subtract(const Duration(days: 42))),
            endDate: DateFormat('yyyy-MM-dd').format(_focusedDay.add(const Duration(days: 42))),
          )));

          final requestsAsync = ref.watch(staffRequestsProvider(StaffRequestQueryParams(
            staffId: staff.id,
            storeId: staff.storeId,
          )));

          return shiftsAsync.when(
            data: (shifts) => requestsAsync.when(
              data: (requests) {
                // 申請中または見送り（却下）された希望を抽出
                final relevantWishes = requests.where((r) {
                  final isPendingOrRejected = r.status == AppConstants.requestStatusPending || r.status == AppConstants.requestStatusRejected;
                  // 本人の希望申請、または本人が志願している交代申請
                  return isPendingOrRejected && (r.type == AppConstants.requestTypeWish || r.volunteerStaffId == staff.id);
                }).toList();

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
                      eventLoader: (day) {
                        final dateStr = DateFormat('yyyy-MM-dd').format(day);
                        final dayShifts = shifts.where((s) => s.date == dateStr).toList();
                        final dayRequests = relevantWishes.where((r) => r.date == dateStr).toList();
                        return [...dayShifts, ...dayRequests];
                      },
                      calendarStyle: const CalendarStyle(
                        todayDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        selectedDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          if (events.isEmpty) return const SizedBox.shrink();
                          
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: events.take(3).map((event) {
                              Color color = Colors.grey;
                              if (event is ShiftModel) {
                                color = event.status == AppConstants.shiftStatusConfirmed
                                    ? Colors.green
                                    : Colors.blue;
                              } else if (event is ShiftRequestModel) {
                                color = event.status == AppConstants.requestStatusRejected
                                    ? Colors.red
                                    : Colors.orange;
                              }
                              
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    if (_selectedDay != null)
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
                            final dayShifts = shifts.where((s) => s.date == dateStr).toList();
                            final dayRequests = relevantWishes.where((r) => r.date == dateStr).toList();
                            
                            if (dayShifts.isEmpty && dayRequests.isEmpty) {
                              return const Center(child: Text(AppConstants.labelShiftNoShifts));
                            }

                            return ListView(
                              children: [
                                ...dayShifts.map((shift) => _ShiftRequestItem(shift: shift)),
                                ...dayRequests.map((request) => _PendingWishItem(request: request)),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('${AppConstants.errMsgGeneric}: $error')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('${AppConstants.errMsgGeneric}: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('${AppConstants.errMsgGeneric}: $error')),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'wish',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WishSubmissionScreen()),
              );
            },
            tooltip: AppConstants.titleWishSubmission,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'change',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ChangeRequestScreen()),
              );
            },
            tooltip: AppConstants.titleChangeRequest,
            child: const Icon(Icons.edit),
          ),
        ],
      ),
    );
  }
}

class _ShiftRequestItem extends StatelessWidget {
  final ShiftModel shift;

  const _ShiftRequestItem({required this.shift});

  @override
  Widget build(BuildContext context) {
    final bool isDraft = shift.status == AppConstants.shiftStatusDraft;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDraft ? Colors.grey.shade100 : Colors.blue.shade50,
      child: ListTile(
        title: Text(
          isDraft ? AppConstants.labelShiftWaitingPublish : AppConstants.labelWorkingTime,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDraft ? Colors.grey : Colors.blue,
          ),
        ),
        subtitle: Text(
          '${shift.startTime} - ${shift.endTime}',
          style: const TextStyle(fontSize: 18),
        ),
        trailing: shift.requestId != null
            ? Chip(
                label: Text(shift.requestStatus == AppConstants.shiftRequestStatusPendingSubstitute
                    ? (shift.volunteerStaffId != null 
                        ? AppConstants.labelWaitSubstituteApproval 
                        : AppConstants.labelSubstituteRequesting)
                    : (shift.requestStatus == AppConstants.shiftRequestStatusPendingChange 
                        ? AppConstants.labelChangeRequesting 
                        : AppConstants.labelShiftRequesting)),
                backgroundColor: Colors.orange,
                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
              )
            : null,
      ),
    );
  }
}
class _PendingWishItem extends StatelessWidget {
  final dynamic request; // ShiftRequestModel

  const _PendingWishItem({required this.request});

  @override
  Widget build(BuildContext context) {
    final bool isRejected = request.status == AppConstants.requestStatusRejected;
    final bool isSubstitute = request.type == AppConstants.requestTypeSubstitute;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isRejected ? Colors.red.shade50 : Colors.orange.shade50,
      child: ListTile(
        title: Text(
          isSubstitute ? AppConstants.labelSubstituteWish : AppConstants.labelShiftWish,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isRejected ? Colors.red : Colors.orange,
          ),
        ),
        subtitle: Text(
          '${request.startTime ?? ""} - ${request.endTime ?? ""}',
          style: const TextStyle(fontSize: 18),
        ),
        trailing: Chip(
          label: Text(isRejected 
              ? AppConstants.labelRejected 
              : (isSubstitute ? AppConstants.labelWaitSubstituteApproval : AppConstants.labelShiftRequesting)),
          backgroundColor: isRejected ? Colors.red : Colors.orange,
          labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}
