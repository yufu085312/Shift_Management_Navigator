import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/store_setup_screen.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/staff/my_shift_screen.dart';
import 'screens/staff/join_store_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 日本語ロケール初期化
  await initializeDateFormatting('ja');
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'シフト管理ナビ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

// 認証状態に基づいて画面を切り替えるラッパー
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // 未ログイン → ログイン画面
          return const LoginScreen();
        } else {
          // ログイン済み → ホーム画面
          return const HomePage();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return currentUser.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 管理者で店舗未設定の場合は店舗初期設定画面へ
        if (user.role == 'admin' && user.storeId == null) {
          return const StoreSetupScreen();
        }

        // 管理者で店舗設定済みの場合はダッシュボードへ
        if (user.role == 'admin') {
          return const AdminDashboardScreen();
        }

        // スタッフの場合は紐付け状態を確認
        if (user.role == 'staff') {
          if (user.storeId == null) {
            return const JoinStoreScreen();
          }
          return const MyShiftScreen();
        }

        return const Center(child: Text('不明なロールです'));
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('エラー: $error')),
      ),
    );
  }
}
