import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  Future<void> _launchStripeCheckout(BuildContext context, WidgetRef ref, String plan, String storeId) async {
    try {
      // プランに応じた Price ID を設定
      String priceId;
      switch (plan) {
        case 'basic':
          priceId = 'price_1SgH5lRtXrMjtYcv0p2BqrQ1';
          break;
        case 'pro':
          priceId = 'price_1SgH81RtXrMjtYcvQiz7cPQ5';
          break;
        default:
          throw Exception('Invalid plan');
      }

      // Cloud Functions を呼び出して Checkout セッションを作成
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('createCheckoutSession').call({
        'priceId': priceId,
        'storeId': storeId,
      });

      final checkoutUrl = result.data['url'] as String;

      // Stripe Checkout ページを開く
      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $checkoutUrl');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchCustomerPortal(BuildContext context, WidgetRef ref, String storeId) async {
    try {
      // Cloud Functions を呼び出して Customer Portal セッションを作成
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('createCustomerPortalSession').call({
        'storeId': storeId,
      });

      final portalUrl = result.data['url'] as String;

      // Stripe Customer Portal ページを開く
      final uri = Uri.parse(portalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $portalUrl');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('サブスクリプション管理'),
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null || user.storeId == null) {
            return const Center(child: Text('店舗情報が見つかりません'));
          }

          final storeAsync = ref.watch(storeProvider(user.storeId!));

          return storeAsync.when(
            data: (store) {
              if (store == null) {
                return const Center(child: Text('店舗情報が見つかりません'));
              }

              final currentPlan = store.plan;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 現在のプラン表示
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '現在のプラン',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getPlanDisplayName(currentPlan),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (currentPlan != 'free')
                              ElevatedButton.icon(
                                onPressed: () => _launchCustomerPortal(context, ref, user.storeId!),
                                icon: const Icon(Icons.settings),
                                label: const Text('プラン管理'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'プランを選択',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Free プラン
                    _PlanCard(
                      planName: 'Free',
                      price: '¥0',
                      features: const [
                        'スタッフ最大5名',
                        '基本的なシフト管理',
                        '申請・通知機能',
                      ],
                      isCurrentPlan: currentPlan == 'free',
                      onSelect: null, // Freeは選択不可
                    ),

                    const SizedBox(height: 16),

                    // Basic プラン
                    _PlanCard(
                      planName: 'Basic',
                      price: '¥2,980/月',
                      features: const [
                        'スタッフ最大20名',
                        'シフト自動割当機能',
                        '優先サポート',
                      ],
                      isCurrentPlan: currentPlan == 'basic',
                      onSelect: currentPlan == 'basic'
                          ? null
                          : () => _launchStripeCheckout(context, ref, 'basic', user.storeId!),
                    ),

                    const SizedBox(height: 16),

                    // Pro プラン
                    _PlanCard(
                      planName: 'Pro',
                      price: '¥9,800/月',
                      features: const [
                        'スタッフ無制限',
                        '全機能開放',
                        '専任サポート',
                        'カスタマイズ対応',
                      ],
                      isCurrentPlan: currentPlan == 'pro',
                      onSelect: currentPlan == 'pro'
                          ? null
                          : () => _launchStripeCheckout(context, ref, 'pro', user.storeId!),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('エラー: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  String _getPlanDisplayName(String plan) {
    switch (plan) {
      case 'free':
        return 'Free プラン';
      case 'basic':
        return 'Basic プラン';
      case 'pro':
        return 'Pro プラン';
      default:
        return 'Unknown';
    }
  }
}

class _PlanCard extends StatelessWidget {
  final String planName;
  final String price;
  final List<String> features;
  final bool isCurrentPlan;
  final VoidCallback? onSelect;

  const _PlanCard({
    required this.planName,
    required this.price,
    required this.features,
    required this.isCurrentPlan,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isCurrentPlan ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentPlan ? Colors.blue : Colors.grey.shade300,
          width: isCurrentPlan ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  planName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isCurrentPlan)
                  const Chip(
                    label: Text('現在のプラン'),
                    backgroundColor: Colors.blue,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(feature),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            if (onSelect != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('このプランを選択'),
                ),
              )
            else if (!isCurrentPlan)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('利用不可'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
