import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/store_provider.dart';
import '../../models/staff_model.dart';
import 'shift_create_screen.dart';
import '../../core/constants/app_constants.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() =>
      _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.titleStaffManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: AppConstants.titleShiftCreate,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ShiftCreateScreen(),
                ),
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
      body: currentUserAsync.when(
        data: (user) {
          if (user == null || user.storeId == null) {
            return const Center(child: Text(AppConstants.errMsgNoStore));
          }

          final staffsAsync = ref.watch(storeStaffsProvider(user.storeId!));
          final staffCountAsync = ref.watch(staffCountProvider(user.storeId!));
          final storeAsync = ref.watch(storeProvider(user.storeId!));

          return Column(
            children: [
              // ヘッダー情報
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    storeAsync.when(
                      data: (store) => Text(
                        store?.name ?? AppConstants.labelStoreName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, _) => const Text(AppConstants.labelStoreName),
                    ),
                    staffCountAsync.when(
                      data: (count) {
                        final maxStaff = _getMaxStaffByPlan(
                          storeAsync.value?.plan ?? AppConstants.planFree,
                        );
                        return Text(
                          '${AppConstants.labelStaffCount}: $count / $maxStaff',
                          style: TextStyle(
                            color: count >= maxStaff ? Colors.red : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                      loading: () => const SizedBox(),
                      error: (_, _) => const SizedBox(),
                    ),
                  ],
                ),
              ),

              // スタッフ一覧
              Expanded(
                child: staffsAsync.when(
                  data: (staffs) {
                    if (staffs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_add_outlined,
                                size: 80,
                                color: Colors.blue.shade200,
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                AppConstants.labelInviteStaff,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                AppConstants.msgInviteNotice,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 32),
                              _buildInviteCard(context, user.storeId!),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: staffs.length,
                      itemBuilder: (context, index) {
                        final staff = staffs[index];
                        return _StaffListItem(
                          staff: staff,
                          onEdit: () => _showStaffDialog(context, staff: staff),
                          onDelete: () => _confirmDelete(context, staff),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('${AppConstants.errMsgGeneric}: $error')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('${AppConstants.errMsgGeneric}: $error')),
      ),
      floatingActionButton: currentUserAsync.maybeMap(
        data: (data) {
          final user = data.value;
          if (user?.storeId == null) return null;
          return FloatingActionButton.extended(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: user!.storeId!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('${AppConstants.msgIdCopied}。${AppConstants.msgSharedToStaffSuffix}')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text(AppConstants.labelCopyIdAndInvite),
            backgroundColor: Colors.blue,
          );
        },
        orElse: () => null,
      ),
    );
  }

  Widget _buildInviteCard(BuildContext context, String storeId) {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              AppConstants.labelYourStoreId,
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            SelectableText(
              storeId,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: storeId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppConstants.msgIdCopied)),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text(AppConstants.labelCopyId),
            ),
          ],
        ),
      ),
    );
  }

  int _getMaxStaffByPlan(String plan) {
    switch (plan) {
      case AppConstants.planFree:
        return 5;
      case AppConstants.planBasic:
        return 20;
      case AppConstants.planPro:
        return 999;
      default:
        return 5;
    }
  }

  void _showStaffDialog(BuildContext context, {required StaffModel staff}) {
    showDialog(
      context: context,
      builder: (context) => _StaffDialog(staff: staff),
    );
  }

  void _confirmDelete(BuildContext context, StaffModel staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.labelDeleteStaff),
        content: Text('${staff.name}${AppConstants.msgDeleteStaffConfirm}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppConstants.labelCancel),
          ),
          TextButton(
            onPressed: () async {
              final staffRepository = ref.read(staffRepositoryProvider);
              await staffRepository.deleteStaff(staff.id, staff.userId);
              if (context.mounted) {
                Navigator.of(context).pop();
                ref.invalidate(storeStaffsProvider);
                ref.invalidate(staffCountProvider);
              }
            },
            child: const Text(
              AppConstants.labelDelete,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffListItem extends StatelessWidget {
  final StaffModel staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffListItem({
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
          backgroundColor: Colors.blue.shade100,
          child: Text(
            staff.name.isNotEmpty ? staff.name[0] : '?',
            style: const TextStyle(color: Colors.blue),
          ),
        ),
        title: Text(
          staff.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${AppConstants.labelHourlyWage}: ¥${staff.hourlyWage.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            )}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
              tooltip: AppConstants.labelEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
              tooltip: AppConstants.labelDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffDialog extends ConsumerStatefulWidget {
  final StaffModel staff;

  const _StaffDialog({required this.staff});

  @override
  ConsumerState<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends ConsumerState<_StaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _wageController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff.name);
    _wageController = TextEditingController(
      text: widget.staff.hourlyWage.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wageController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final staffRepository = ref.read(staffRepositoryProvider);
      
      // 更新のみ
      await staffRepository.updateStaff(
        staffId: widget.staff.id,
        name: _nameController.text.trim(),
        hourlyWage: int.tryParse(_wageController.text) ?? 0,
      );

      if (mounted) {
        ref.invalidate(storeStaffsProvider);
        ref.invalidate(staffCountProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.msgUpdateComplete)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppConstants.errMsgGeneric}: $e'),
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
      title: const Text(AppConstants.labelEditStaff),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: AppConstants.labelName,
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppConstants.valInputName;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _wageController,
              decoration: const InputDecoration(
                labelText: AppConstants.labelHourlyWage,
                prefixIcon: Icon(Icons.attach_money),
                suffixText: AppConstants.labelYen,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppConstants.valInputWage;
                }
                if (int.tryParse(value) == null) {
                  return AppConstants.valInputNumber;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(AppConstants.labelCancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(AppConstants.labelUpdate),
        ),
      ],
    );
  }
}
