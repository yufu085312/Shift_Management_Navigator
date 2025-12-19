import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/staff_repository.dart';
import '../models/staff_model.dart';
import 'auth_provider.dart';

// StaffRepositoryのプロバイダー
final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository();
});

// 店舗のスタッフ一覧を取得するプロバイダー
final storeStaffsProvider = FutureProvider.family<List<StaffModel>, String>((ref, storeId) async {
  final staffRepository = ref.watch(staffRepositoryProvider);
  return await staffRepository.getStaffsByStore(storeId);
});

// スタッフ数を取得するプロバイダー
final staffCountProvider = FutureProvider.family<int, String>((ref, storeId) async {
  final staffRepository = ref.watch(staffRepositoryProvider);
  return await staffRepository.getStaffCount(storeId);
});

// 現在ログインしているユーザーのスタッフ情報を取得するプロバイダー
final currentStaffProvider = FutureProvider<StaffModel?>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.maybeWhen(
    data: (user) async {
      if (user == null || user.storeId == null) return null;
      final repository = ref.watch(staffRepositoryProvider);
      return repository.getStaffByUserId(user.uid, user.storeId!);
    },
    orElse: () => null,
  );
});
