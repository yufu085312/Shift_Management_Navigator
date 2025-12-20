# サブスクリプション機能 ドキュメント

このドキュメントでは、Stripe を利用したサブスクリプション機能の管理、テスト、および本番環境への反映手順について説明します。

## 機能概要

このアプリでは、店舗管理者がサブスクリプションプランを変更することで、以下の機能制限を解除できます。

| プラン | 制限内容 | 備考 |
| :--- | :--- | :--- |
| **Free** | スタッフ最大 5 名まで | 基本シフト管理機能のみ |
| **Basic** | スタッフ最大 20 名まで | シフト自動割当機能の開放 |
| **Pro** | スタッフ無制限 | すべてのプレミアム機能が利用可能 |

## テスト決済の動作確認方法

開発環境（テストモード）での動作確認手順は以下の通りです。

### 1. 準備物
- **Stripe テスト用 Secret Key**: `sk_test_...`
- **Firebase Blaze プラン**: Cloud Functions の実行に必要です（アップグレード済み）。
- **環境変数**: `functions/.env` に `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `APP_URL` がセットされていること。

### 2. 確認手順
1. アプリを起動 (`flutter run -d chrome --web-port=8080`)。
2. 管理者アカウントでログインし、ダッシュボードの「サブスクリプション管理」へ移動。
3. プラン（Basic または Pro）を選択し、「このプランを選択」をクリック。
4. Stripe Checkout 画面（Stripe ホストの決済ページ）へリダイレクトされることを確認。
5. 以下のテストカード情報を使用して決済を完了。
   - **カード番号**: `4242 4242 4242 4242`
   - **有効期限**: 未来の日付（例: `12/34`）
   - **CVC**: `123`
6. 決済完了後、アプリに戻り、プランが「Basic プラン」または「Pro プラン」に更新されていることを確認。

## 本番環境への反映手順

本番環境（ライブモード）へ移行する際は、以下のステップを実行してください。

### 1. Stripe ライブモードの設定
1. Stripe ダッシュボードで「ライブモード」に切り替えます。
2. 本番用の「商品」と「価格（Price）」を Basic/Pro それぞれ作成し、**Price ID** (`price_...`) を取得します。
3. ライブ用の **Secret Key** (`sk_live_...`) を取得します。

### 2. 環境変数の更新
`functions/.env` を本番環境用に書き換え、再度デプロイします。
```bash
STRIPE_SECRET_KEY=sk_live_YourSecretKey
STRIPE_WEBHOOK_SECRET=whsec_YourWebhookSecret
APP_URL=https://your-production-url.web.app
```

### 3. Flutter コードの修正
`lib/screens/admin/subscription_screen.dart` 内の `Case 'basic'` および `Case 'pro'` の `priceId` を、ライブモードで取得した Price ID に置き換えます。

### 4. Cloud Functions のデプロイ
環境変数を反映させるために、再度デプロイを実行します。
```bash
cd functions
firebase deploy --only functions
```

### 5. Webhook の設定
1. Stripe ダッシュボード（ライブモード）の「開発者」 > 「Webhook」で、エンドポイントを追加します。
2. **エンドポイント URL**: `https://us-central1-[PROJECT_ID].cloudfunctions.net/stripeWebhook`
3. **イベント**:
   - `checkout.session.completed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`

## トラブルシューティング

- **プランが更新されない**:
  - Firebase コンソールの「関数」タブから `stripeWebhook` のログを確認してください。
  - Stripe ダッシュボードの「イベント」ログで、Webhook 送信時にエラー（403, 500等）が出ていないか確認してください。
  - Price ID が `functions/index.js` の判定ロジックと一致しているか確認してください。
- **Stripe 画面が開かない**:
  - `url_launcher` が `chrome` などのブラウザ設定で正しく動作するか確認してください（`mode: LaunchMode.externalApplication`）。
