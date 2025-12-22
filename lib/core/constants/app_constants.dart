class AppConstants {
  // Firestore Collections
  static const String collectionStores = 'stores';
  static const String collectionUsers = 'users';
  static const String collectionShifts = 'shifts';
  static const String collectionShiftRequests = 'shift_requests';
  static const String collectionNotifications = 'notifications';
  static const String collectionStaffs = 'staffs';

  // Plans
  static const String planFree = 'free';
  static const String planBasic = 'basic';
  static const String planPro = 'pro';

  // Stripe Price IDs
  static const String priceIdBasic = 'price_1SgH5lRtXrMjtYcv0p2BqrQ1';
  static const String priceIdPro = 'price_1SgH81RtXrMjtYcvQiz7cPQ5';

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleStaff = 'staff';

  // Shift Status
  static const String shiftStatusDraft = 'draft';
  static const String shiftStatusConfirmed = 'confirmed';

  // Shift Request Type
  static const String requestTypeWish = 'wish';
  static const String requestTypeChange = 'change';
  static const String requestTypeSubstitute = 'substitute';

  // Notification Status
  static const String notificationStatusUnread = 'unread';
  static const String notificationStatusRead = 'read';

  // Shift Request Status
  static const String requestStatusPending = 'pending';
  static const String requestStatusApproved = '承認';
  static const String requestStatusRejected = '見送り';

  // Internal Shift Request Status (for Shift document)
  static const String shiftRequestStatusPendingChange = 'pending_change';
  static const String shiftRequestStatusPendingSubstitute = 'pending_substitute';

  // Common UI Labels
  static const String labelOk = 'OK';
  static const String labelCancel = 'キャンセル';
  static const String labelSave = '保存';
  static const String labelDelete = '削除';
  static const String labelUpdate = '更新';
  static const String labelAdd = '追加';
  static const String labelEdit = '編集';
  static const String labelRefresh = '更新';
  static const String labelLogout = 'ログアウト';
  static const String labelPublish = '公開';
  static const String labelSelect = '選択してください';
  static const String labelClose = '閉じる';

  // Screen Titles
  static const String titleShiftCreate = 'シフト作成';
  static const String titleShiftPublish = 'シフトを公開';
  static const String titleShiftDelete = 'シフトを削除';
  static const String titleStaffManagement = 'スタッフ管理';
  static const String titleSubscription = 'サブスクリプション';
  static const String titleAdminDashboard = '管理者ダッシュボード';
  static const String titleMyShift = 'マイシフト';
  static const String titleWishSubmission = 'シフト希望提出';
  static const String titleChangeRequest = '変更・交代申請';
  static const String titleNotifications = '通知一覧';
  static const String titleStoreJoin = '店舗への参加';

  // Success Messages
  static const String msgUpdateSuccess = '最新の情報を取得しました';
  static const String msgSaveSuccess = '保存しました';
  static const String msgDeleteSuccess = '削除しました';
  static const String msgPublishSuccess = 'シフトを公開しました';
  static const String msgUpdateComplete = '情報を更新しました';
  static const String msgRequestSubmitted = '申請を提出しました';
  static const String msgJoinSuccess = '店舗に参加しました！';

  // Error Messages
  static const String errMsgGeneric = 'エラーが発生しました';
  static const String errMsgNoStore = '店舗情報が見つかりません';
  static const String errMsgAutoAssign = '自動割当中にエラーが発生しました';
  static const String errMsgLoad = 'データの読み込みに失敗しました';
  static const String errMsgAuth = '認証エラーが発生しました';

  // Validation Messages
  static const String valSelectDate = '日付を選択してください';
  static const String valSelectStaff = 'スタッフを選択してください';
  static const String valInputReason = '理由を入力してください';
  static const String valSetTime = '時間を設定してください';
  static const String valInputName = '名前を入力してください';

  // Dialog Texts
  static const String diagAutoAssignTitle = '自動割当を実行';
  static const String diagAutoAssignConfirm = 'スタッフの希望に基づきシフトを自動作成しますか？\n\n※既存のシフトは上書きされません。';
  static const String diagDeleteConfirm = 'このシフトを削除してもよろしいですか?';
  static const String diagPublishConfirm = '以下の期間のシフトを公開しますか?';
  static const String diagPublishNotice = '公開すると、スタッフに通知が送信されます。';
  static const String diagPlanLimitTitle = 'プラン制限';
  static const String diagPlanLimitAutoAssign = '自動割当機能はBasicプラン以上でご利用いただけます。';

  // Notification Messages
  static const String notifShiftPublishedTitle = 'シフトが公開されました';
  static const String notifSubstituteTitle = '交代募集中';
  static const String notifChangeRequestTitle = '時間変更申請';

  // Dashboard Labels
  static const String labelDashboardMenuCreate = 'シフト作成・公開';
  static const String labelDashboardMenuRequest = 'シフト申請';
  static const String labelDashboardMenuStaff = 'スタッフ管理';
  static const String labelDashboardMenuSub = 'サブスクリプション';
  static const String labelDashboardCurrentStatus = '現在状況';
  static const String labelDashboardQuickMenu = 'クイックメニュー';
  static const String labelDashboardRegisteredStaff = '登録スタッフ';
  static const String labelDashboardUnpublishedShifts = '今週の未公開シフト';
  static const String labelDashboardPendingRequests = '未処理の申請';
  static const String msgIdCopied = '店舗IDをコピーしました';

  // Auth Labels
  static const String labelEmail = 'メールアドレス';
  static const String labelPassword = 'パスワード';
  static const String labelLogin = 'ログイン';
  static const String labelSignup = '新規登録';
  static const String labelNoAccount = 'アカウントをお持ちでない方はこちら';
  static const String labelAppName = 'シフト管理ナビ';
  static const String labelStoreName = '店舗名';
  static const String labelName = '名前';
  static const String labelAdminSignup = '管理者として登録 (店舗作成)';
  static const String labelStaffSignup = 'スタッフとして登録 (店舗に参加)';

  // Validation
  static const String valInputEmail = 'メールアドレスを入力してください';
  static const String valInputPassword = 'パスワードを入力してください';
  static const String valInvalidEmail = '正しいメールアドレスを入力してください';
  static const String valInputStoreName = '店舗名を入力してください';

  // Shift Request Labels
  static const String labelTimeStart = '開始時間';
  static const String labelTimeEnd = '終了時間';
  static const String labelSubmit = '提出する';
  static const String labelReasonOptional = '備考・理由 (任意)';

  static const String labelPasswordConfirm = 'パスワード(確認)';
  static const String labelPasswordHelper = '8文字以上で入力してください';
  static const String valPasswordMismatch = 'パスワードが一致しません';
  static const String labelRoleAdminDescription = '管理者(店長・オーナー)';
  static const String labelRoleStaffDescription = 'スタッフ(アルバイト・パート)';
  static const String labelRegister = '登録';

  // Join Store Labels
  static const String labelStoreId = '店舗ID';
  static const String labelStoreIdHint = '例: abc123def456';
  static const String labelJoin = '参加する';
  static const String labelJoinStore = '店舗に参加する';
  static const String msgStoreIdConfirm = '管理者に教えてもらった「店舗ID」を入力してください。';
  static const String valInputStoreId = '店舗IDを入力してください';
  static const String errMsgStoreNotFound = '指定された店舗IDが見つかりません。管理者に確認してください。';
  static const String errMsgRelogin = '再ログインしてください';

  // Staff Screen Labels
  static const String labelMenu = 'メニュー';
  static const String labelSubstituteRecruitment = '交代募集一覧';
  static const String labelShiftNoShifts = 'この日のシフトはありません';
  static const String labelShiftWaitingPublish = '作成中';
  static const String labelShiftRequesting = '申請中';
  static const String labelSubstituteRequesting = '交代申請中';
  static const String labelChangeRequesting = '変更申請中';
  static const String labelWorkingTime = '確定';
  static const String labelStaffNotFound = 'スタッフ情報が見つかりません';

  // Change/Substitute Request Labels
  static const String labelChangeTime = '時間変更';
  static const String labelSubstituteWish = '交代希望';
  static const String labelWaitSubstituteApproval = '交代承認待ち';
  static const String labelAlreadyVolunteered = '交代志願済み';
  static const String valSelectTargetShift = '対象のシフトを選択してください';
  static const String valSetNewTime = '変更後の時間を指定してください';
  static const String labelSelectRequestType = '申請種類を選択';
  static const String labelSelectTargetShift = '対象のシフトを選択';
  static const String labelSetNewTime = '変更後の時間を指定';
  static const String labelReasonMessage = '理由・メッセージ';
  static const String labelSubmitRequest = '申請を送信する';
  static const String labelNoScheduledShifts = '予定されているシフトはありません';

  // Staff Management Labels
  static const String labelStaffCount = 'スタッフ数';
  static const String labelInviteStaff = 'スタッフを招待しましょう';
  static const String msgInviteNotice = 'スタッフの方にこのアプリをインストールしてもらい、下記の「店舗ID」を入力してもらうことで、自動的にこちらの一覧に追加されます。';
  static const String labelCopyIdAndInvite = '店舗IDをコピーして招待';
  static const String labelYourStoreId = 'あなたの店舗ID';
  static const String labelCopyId = 'IDをコピーする';
  static const String labelHourlyWage = '時給';
  static const String valInputWage = '時給を入力してください';
  static const String valInputNumber = '数値を入力してください';
  static const String labelEditStaff = 'スタッフ編集';
  static const String labelDeleteStaff = 'スタッフを削除';
  static const String labelLeaveStore = '店舗から退出する';
  static const String diagLeaveStoreTitle = '店舗から退出';
  static const String diagLeaveStoreConfirm = '本当に店舗から退出しますか？\n本日以降のシフトと全ての申請が削除されます。\n再度参加するには店舗IDが必要です。';
  static const String msgLeaveSuccess = 'から退出しました';

  // Store Request Screen Labels
  static const String titleShiftRequestList = 'シフト申請一覧';
  static const String msgNoPendingRequests = '未処理の申請はありません';
  static const String labelSubstituteStaff = '交代スタッフ';
  static const String msgVolunteerExists = '志願者あり';
  static const String msgShiftUpdateFailed = 'シフト反映に失敗しました';
  static const String labelApproved = '承認';
  static const String labelRejected = '見送り';
  static const String labelStatus = 'ステータス';

  // Subscription Screen Labels
  static const String titleSubscriptionManagement = 'サブスクリプション管理';
  static const String labelCurrentPlan = '現在のプラン';
  static const String labelManagePlan = 'プラン管理';
  static const String labelSelectPlan = 'プランを選択';
  static const String labelChooseThisPlan = 'このプランを選択';
  static const String labelUnavailable = '利用不可';

  // Substitute Recruitment Labels
  static const String labelTakeSubstitute = '交代を引き受ける';
  static const String labelAccept = '引き受ける';
  static const String labelVolunteerInProgress = '他の人が申請中';
  static const String msgNoSubstituteRecruitment = '現在募集中の交代はありません';
  static const String labelOwnRecruitment = '自分の募集';
  static const String msgVolunteerSuccess = '志願しました。管理者の承認をお待ちください。';
  static const String msgRecruitingSubstitute = '交代を募集中です';
  static const String msgOwnRecruitment = '募集中の自分のシフト';

  // Notification Screen Labels
  static const String labelMarkAllAsRead = 'すべて既読にする';
  static const String msgNoNotifications = '通知はありません';
  static const String errMsgUserNotFound = 'ユーザー情報が見つかりません';
  static const String errMsgUnknownRole = '不明なロールです';

  // Specific Message Labels
  static const String labelShiftWish = 'シフト希望';
  static const String labelChangeRequest = '時間変更申請';
  static const String labelSubstituteRequest = '交代申請';
  static const String msgAssignSubstituteTitle = '交代シフトが割り当てられました';
  static const String msgDeleteStaffConfirm = 'さんを削除してもよろしいですか?';
  static const String labelYen = '円';
  static const String msgSubstituteConfirm = 'のシフトを引き受けますか？\n（管理者の承認後に確定します）';
  static const String msgRecruitSubstituteBody = 'さんが交代を募集しています。';
  static const String msgTimeChangeRequestBody = 'さんが時間の変更申請をしました。';
  static const String labelReasonHint = '例: 急用のため代わりをお願いしたいです。';
  static const String labelWishTimeHint = '希望時間(未指定の場合は終日)';
  static const String labelSelectedDate = '選択日';
  static const String labelDraft = '下書き';
  static const String labelConfirmed = '公開済み';
  static const String labelStaff = 'スタッフ';
  static const String labelNone = 'なし';
  static const String labelUnknown = '不明';
  static const String labelStoreRequest = '申請';
  static const String msgRequestUpdateTitle = '申請が';
  static const String msgRequestUpdateBodyPrefix = 'されました';
  static const String labelFreePlan = 'Free プラン';
  static const String labelBasicPlan = 'Basic プラン';
  static const String labelProPlan = 'Pro プラン';
  static const String labelReasonDefaultHint = '例: 通院のため';
  static const String labelHonorificStaff = ' さん';
  static const String msgShiftPublishedBodySuffix = 'のシフトが公開されました。';
  static const String msgNotificationStatusSuffix = 'されました。';
  static const String msgSubstituteAssignBodySuffix = 'の代わりとしてシフトが割り当てられました。';
  static const String msgVolunteerBodySuffix = 'が交代を志願しています。';
  static const String msgSharedToStaffSuffix = 'スタッフに共有してください。';
  static const String labelDateFormatFull = 'yyyy年M月d日(E)';
  static const String labelPersonSuffix = '名';
  static const String labelItemSuffix = '件';
  static const String labelError = 'エラー';
  static const String labelRole = '役割';
  static const String valInputPasswordConfirm = 'パスワード(確認)を入力してください';
  static const String labelSignupTitle = 'アカウント作成';
  static const String labelParticleNo = 'の';
  static const String labelParticleGa = 'が';
  static const String labelParticleNi = 'に';

  // Auth Error Messages
  static const String errMsgEmailInUse = 'このメールアドレスは既に登録されています';
  static const String errMsgInvalidCred = 'メールアドレスまたはパスワードが正しくありません';
  static const String errMsgTooManyRequests = 'ログイン試行回数が多すぎます。しばらくしてから再度お試しください';
  static const String errMsgUserDisabled = 'このアカウントは無効化されています';
  static const String errMsgOpNotAllowed = 'メール/パスワード認証が有効になっていません。Firebaseコンソールで有効にしてください。';

  // Subscription Plan Details
  static const String planFreePrice = '¥0';
  static const String planFreeFeature1 = 'スタッフ最大5名';
  static const String planFreeFeature2 = '基本的なシフト管理';
  static const String planFreeFeature3 = '申請・通知機能';
  static const String planBasicPrice = '¥2,980/月';
  static const String planBasicFeature1 = 'スタッフ最大20名';
  static const String planBasicFeature2 = 'シフト自動割当機能';
  static const String planBasicFeature3 = '優先サポート';
  static const String planProPrice = '¥9,800/月';
  static const String planProFeature1 = 'スタッフ無制限';
  static const String planProFeature2 = '全機能開放';
  static const String planProFeature3 = '専任サポート';
  static const String planProFeature4 = 'カスタマイズ対応';

  // Store Setup Screen Labels
  static const String titleStoreSetup = '店舗初期設定';
  static const String labelRegisterStoreInfo = '店舗情報を登録';
  static const String msgInputStoreInfo = 'シフト管理を始めるために、店舗情報を入力してください';
  static const String labelStoreNameHint = '例: カフェ○○ 渋谷店';
  static const String labelCreateStore = '店舗を作成';
  static const String msgFreePlanNotice = '• スタッフ数: 最大5人\n• シフト作成: ◯\n• 希望・変更申請: ◯\n• 自動割当: ✕';
}
