# 開発ガイドライン & チェックリスト

このプロジェクト「シフト管理ナビ」を開発・保守する上での重要な確認事項と手順をまとめています。

## 1. 開発環境のセットアップ

### プロジェクトの起動
```bash
flutter pub get
flutter run -d chrome --web-port=8080
```
※ Web 版の Firebase 認証や Stripe 連携を正しく動作させるため、ポート `8080` での起動を推奨します。

### プラットフォーム別セットアップ
- **iOS/macOS**:
  - CocoaPods のインストールが必要です (`brew install cocoapods`)。
  - `ios` または `macos` ディレクトリで `pod install` を実行してください。
- **Android**:
  - Android Studio と Android SDK のセットアップが必要です。

### Firebase の設定 (重要)
セキュリティ保護のため、以下の設定ファイルは Git 管理から除外されています。新規環境では既存のプロジェクトから取得するか、Firebase CLI で再生成して配置してください。

1. **設定ファイルの配置場所**:
   - `ios/Runner/GoogleService-Info.plist`
   - `macos/Runner/GoogleService-Info.plist`
   - `lib/firebase_options.dart`
2. **プロジェクト設定**:
   - **Blaze プラン**: Cloud Functions (第2世代) を使用するため必須です。
   - **Authentication**: Email/Password 認証を有効にしてください。
   - **Firestore**: 日本時間での運用を想定したインデックス設定が必要です。

## 2. 実装時のチェックリスト

### コーディング規約
- **Riverpod**: 状態管理は原則として Riverpod を使用してください。
- **Repository パターン**: Firestore への直接アクセスは避け、`lib/repositories` 配下のクラスを介して行ってください。
- **Lint**: 提出前に必ず解析を実行してください。
  ```bash
  flutter analyze
  ```

### 機密情報の取り扱い
- `.env` ファイルは絶対に Git に含めないでください（`.gitignore` で除外済み）。
- Stripe のシークレットキーや Firebase のサービスアカウントキーは環境変数を経由して読み込んでください。

## 3. 頻出するエラーと対処法

### Firebase Auth の 400 エラー (OPERATION_NOT_ALLOWED)
- **原因**: Firebase コンソールで Email/Password 認証が有効になっていない。
- **対処**: [Firebase Console](https://console.firebase.google.com/) > Authentication > Sign-in method で設定を確認。

### Cloud Functions のデプロイ失敗
- **原因**: ESLint のエラー、または `firebase-functions` のバージョン不一致。
- **対処**: 
  ```bash
  cd functions
  npm run lint -- --fix
  firebase deploy --only functions
  ```

### Web での url_launcher が動作しない
- **原因**: ポップアップブロック、または `LaunchMode.externalApplication` の未指定。
- **対処**: `launchUrl(uri, mode: LaunchMode.externalApplication)` を使用してください。

## 4. データベース (Firestore) 構造

主要なコレクションと役割:
- `/stores`: 店舗情報、サブスクリプションプラン、Stripe ID
- `/users`: ユーザープロフィール、所属店舗 ID、ロール (admin/staff)
- `/shifts`: シフトスケジュール（店舗 ID・スタッフ ID でフィルタリング）
- `/shift_requests`: 欠勤・代打・変更申請のステータス管理

## 5. デプロイ手順

### Flutter Web (Firebase Hosting)
```bash
flutter build web --release
firebase deploy --only hosting
```

### Cloud Functions
```bash
cd functions
firebase deploy --only functions
```

## 6. 定期チェック
- [ ] `flutter analyze` で警告が出ていないか。
- [ ] Firestore のセキュリティルールが意図せず全公開になっていないか。
- [ ] Stripe のシークレットキーが有効期限切れになっていないか。
