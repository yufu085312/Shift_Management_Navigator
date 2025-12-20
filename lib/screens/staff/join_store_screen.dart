import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/store_provider.dart';
import '../../core/constants/app_constants.dart';

class JoinStoreScreen extends ConsumerStatefulWidget {
  const JoinStoreScreen({super.key});

  @override
  ConsumerState<JoinStoreScreen> createState() => _JoinStoreScreenState();
}

class _JoinStoreScreenState extends ConsumerState<JoinStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _storeIdController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final storeId = _storeIdController.text.trim();
      final storeRepository = ref.read(storeRepositoryProvider);
      final staffRepository = ref.read(staffRepositoryProvider);
      final authRepository = ref.read(authRepositoryProvider);
      final currentUser = ref.read(currentUserProvider).value;

      if (currentUser == null) throw Exception(AppConstants.errMsgRelogin);

      // 店舗の存在確認
      final store = await storeRepository.getStore(storeId);
      if (store == null) {
        throw Exception(AppConstants.errMsgStoreNotFound);
      }

      // スタッフデータの紐付け/作成
      await staffRepository.joinStore(
        userId: currentUser.uid,
        storeId: storeId,
        name: currentUser.name,
      );

      // ユーザーデータのstoreIdを更新
      await authRepository.updateUserData(
        uid: currentUser.uid,
        storeId: storeId,
      );

      if (mounted) {
        // プロバイダーを無効化して最新データを取得
        ref.invalidate(currentUserProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${store.name} ${AppConstants.msgJoinSuccess}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.titleStoreJoin),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(signOutProvider).call(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.store,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                const Text(
                  AppConstants.labelJoinStore,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  AppConstants.msgStoreIdConfirm,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _storeIdController,
                  decoration: const InputDecoration(
                    labelText: AppConstants.labelStoreId,
                    hintText: AppConstants.labelStoreIdHint,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppConstants.valInputStoreId;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleJoin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          AppConstants.labelJoin,
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
