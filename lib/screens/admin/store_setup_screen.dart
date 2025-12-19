import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../admin/staff_management_screen.dart';

class StoreSetupScreen extends ConsumerStatefulWidget {
  const StoreSetupScreen({super.key});

  @override
  ConsumerState<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends ConsumerState<StoreSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateStore() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final storeRepository = ref.read(storeRepositoryProvider);
      final currentUser = authRepository.currentUser;

      if (currentUser == null) {
        throw Exception('ログインしてください');
      }

      // 店舗を作成
      final store = await storeRepository.createStore(
        name: _storeNameController.text.trim(),
        ownerId: currentUser.uid,
      );

      // ユーザー情報に店舗IDを設定
      await authRepository.updateUserData(
        uid: currentUser.uid,
        storeId: store.id,
      );

      if (mounted) {
        // スタッフ管理画面へ遷移
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const StaffManagementScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
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
        title: const Text('店舗初期設定'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // アイコン
                  const Icon(
                    Icons.store,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),

                  // タイトル
                  const Text(
                    '店舗情報を登録',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'シフト管理を始めるために、店舗情報を入力してください',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // 店舗名
                  TextFormField(
                    controller: _storeNameController,
                    decoration: const InputDecoration(
                      labelText: '店舗名',
                      hintText: '例: カフェ○○ 渋谷店',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '店舗名を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // 作成ボタン
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreateStore,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '店舗を作成',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // 注意事項
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Freeプラン',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• スタッフ数: 最大5人\n'
                          '• シフト作成: ◯\n'
                          '• 希望・変更申請: ◯\n'
                          '• 自動割当: ✕',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
