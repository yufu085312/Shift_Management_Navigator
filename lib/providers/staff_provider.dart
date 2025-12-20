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
      if (user == null) return null;
      final repository = ref.watch(staffRepositoryProvider);
      
      if (user.storeId == null) {
        // ユーザー情報のstoreIdが未設定の場合、staffsコレクションを全検索して同期を試みる
        final staff = await repository.findStaffByUserId(user.uid);
        if (staff != null) {
          // 同期処理
          await ref.read(authRepositoryProvider).updateUserData(
            uid: user.uid,
            storeId: staff.storeId,
          );
          // ユーザー情報を最新にするためにinvalidate
          ref.invalidate(currentUserProvider);
          return staff;
        }
        return null;
      }
      
      return repository.getStaffByUserId(user.uid, user.storeId!);
    },
    orElse: () => null,
  );
});
