/**
 * Stripe 連携 Cloud Functions
 *
 * このファイルには、Stripe Checkout セッションの作成、
 * Customer Portal セッションの作成、および Webhook 処理を行う関数が含まれています。
 */

// 環境変数を読み込み
require("dotenv").config();

const {onRequest, onCall} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

// Stripe SDK の初期化
// 本番環境では、Firebase Functions の環境変数に STRIPE_SECRET_KEY を設定してください
// firebase functions:config:set stripe.secret_key="sk_test_..."
const stripeKey = process.env.STRIPE_SECRET_KEY;
const stripe = require("stripe")(stripeKey);

// Firebase Admin SDK の初期化
admin.initializeApp();

setGlobalOptions({maxInstances: 10});

/**
 * Stripe Checkout セッションを作成
 *
 * @param {Object} data - { priceId: string, storeId: string }
 * @param {Object} context - Firebase Auth コンテキスト
 * @returns {Object} { sessionId: string, url: string }
 */
exports.createCheckoutSession = onCall(async (request) => {
  const {priceId, storeId} = request.data;
  const uid = request.auth?.uid;

  if (!uid) {
    throw new Error("認証が必要です");
  }

  if (!priceId || !storeId) {
    throw new Error("priceId と storeId が必要です");
  }

  try {
    // Stripe Checkout セッションを作成
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ["card"],
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      mode: "subscription",
      success_url: `${process.env.APP_URL ||
        "http://localhost:8080"}/admin/dashboard?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${process.env.APP_URL ||
        "http://localhost:8080"}/admin/subscription`,
      metadata: {
        storeId: storeId,
        uid: uid,
      },
    });

    logger.info("Checkout session created", {sessionId: session.id, storeId});

    return {
      sessionId: session.id,
      url: session.url,
    };
  } catch (error) {
    logger.error("Error creating checkout session", error);
    throw new Error("Checkout セッションの作成に失敗しました");
  }
});

/**
 * Stripe Customer Portal セッションを作成
 *
 * @param {Object} data - { storeId: string }
 * @param {Object} context - Firebase Auth コンテキスト
 * @returns {Object} { url: string }
 */
exports.createCustomerPortalSession = onCall(async (request) => {
  const {storeId} = request.data;
  const uid = request.auth?.uid;

  if (!uid) {
    throw new Error("認証が必要です");
  }

  if (!storeId) {
    throw new Error("storeId が必要です");
  }

  try {
    // Firestore から店舗の Stripe Customer ID を取得
    const storeDoc = await admin.firestore()
        .collection("stores").doc(storeId).get();
    const stripeCustomerId = storeDoc.data()?.stripeCustomerId;

    if (!stripeCustomerId) {
      throw new Error("Stripe Customer ID が見つかりません");
    }

    // Customer Portal セッションを作成
    const session = await stripe.billingPortal.sessions.create({
      customer: stripeCustomerId,
      return_url: `${process.env.APP_URL ||
        "http://localhost:8080"}/admin/subscription`,
    });

    logger.info("Customer portal session created", {storeId});

    return {
      url: session.url,
    };
  } catch (error) {
    logger.error("Error creating customer portal session", error);
    throw new Error("Customer Portal セッションの作成に失敗しました");
  }
});

/**
 * Stripe Webhook ハンドラー
 *
 * Stripe からのイベント (checkout.session.completed,
 * customer.subscription.updated など) を受け取り、
 * Firestore の店舗プランを更新します。
 */
exports.stripeWebhook = onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
  } catch (err) {
    logger.error("Webhook signature verification failed", err);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  logger.info("Webhook event received", {type: event.type});

  // イベントタイプに応じて処理
  switch (event.type) {
    case "checkout.session.completed": {
      const session = event.data.object;
      const {storeId} = session.metadata;
      const customerId = session.customer;

      // サブスクリプション情報を取得
      const subscription = await stripe.subscriptions.retrieve(
          session.subscription,
      );
      const priceId = subscription.items.data[0].price.id;

      // Price ID からプラン名を判定
      let plan = "free";
      if (priceId === "price_1SgH5lRtXrMjtYcv0p2BqrQ1") {
        plan = "basic";
      } else if (priceId === "price_1SgH81RtXrMjtYcvQiz7cPQ5") {
        plan = "pro";
      }

      // Firestore の店舗情報を更新
      await admin.firestore().collection("stores").doc(storeId).update({
        plan: plan,
        stripeCustomerId: customerId,
        stripeSubscriptionId: session.subscription,
      });

      logger.info("Store plan updated", {storeId, plan});
      break;
    }

    case "customer.subscription.updated":
    case "customer.subscription.deleted": {
      const subscription = event.data.object;
      const customerId = subscription.customer;

      // Customer ID から店舗を検索
      const storesSnapshot = await admin.firestore()
          .collection("stores")
          .where("stripeCustomerId", "==", customerId)
          .limit(1)
          .get();

      if (storesSnapshot.empty) {
        logger.warn("Store not found for customer", {customerId});
        break;
      }

      const storeDoc = storesSnapshot.docs[0];
      const storeId = storeDoc.id;

      if (event.type === "customer.subscription.deleted") {
        // サブスクリプションがキャンセルされた場合、Free プランに戻す
        await admin.firestore().collection("stores").doc(storeId).update({
          plan: "free",
          stripeSubscriptionId: null,
        });
        logger.info("Store downgraded to free", {storeId});
      } else {
        // サブスクリプションが更新された場合、プランを更新
        const priceId = subscription.items.data[0].price.id;
        let plan = "free";
        if (priceId === "price_1SgH5lRtXrMjtYcv0p2BqrQ1") {
          plan = "basic";
        } else if (priceId === "price_1SgH81RtXrMjtYcvQiz7cPQ5") {
          plan = "pro";
        }

        await admin.firestore().collection("stores").doc(storeId).update({
          plan: plan,
        });
        logger.info("Store plan updated", {storeId, plan});
      }
      break;
    }

    default:
      logger.info("Unhandled event type", {type: event.type});
  }

  res.json({received: true});
});

/**
 * スタッフが店舗から退出する際のクリーンアップ処理
 *
 * @param {Object} data - { userId: string, storeId: string }
 * @param {Object} context - Firebase Auth コンテキスト
 * @returns {Object} { success: boolean, deletedShifts: number, deletedRequests: number }
 */
exports.leaveStoreCleanup = onCall(async (request) => {
  const { userId, storeId } = request.data;
  const uid = request.auth?.uid;

  // 認証チェック
  if (!uid) {
    throw new Error("認証が必要です");
  }

  // 自分自身のデータのみ削除可能
  if (uid !== userId) {
    throw new Error("他のユーザーのデータは削除できません");
  }

  if (!userId || !storeId) {
    throw new Error("userId と storeId が必要です");
  }

  try {
    const db = admin.firestore();
    const nowStr = new Date().toISOString().split("T")[0];

    // 1. スタッフIDを取得
    const staffSnapshot = await db.collection("staffs")
      .where("userId", "==", userId)
      .where("storeId", "==", storeId)
      .limit(1)
      .get();

    if (staffSnapshot.empty) {
      throw new Error("スタッフデータが見つかりません");
    }

    const staffDoc = staffSnapshot.docs[0];
    const staffId = staffDoc.id;

    // 2. 未来のシフトを削除
    const shiftsSnapshot = await db.collection("shifts")
      .where("staffId", "==", staffId)
      .get();

    let deletedShiftsCount = 0;
    const shiftDeletePromises = [];
    shiftsSnapshot.forEach((doc) => {
      const date = doc.data().date;
      if (date >= nowStr) {
        shiftDeletePromises.push(doc.ref.delete());
        deletedShiftsCount++;
      }
    });
    await Promise.all(shiftDeletePromises);

    // 3. 全ての申請を削除
    const requestsSnapshot = await db.collection("shift_requests")
      .where("staffId", "==", staffId)
      .get();

    const requestDeletePromises = [];
    requestsSnapshot.forEach((doc) => {
      requestDeletePromises.push(doc.ref.delete());
    });
    await Promise.all(requestDeletePromises);

    // 4. スタッフデータのisActiveをfalseにする
    await staffDoc.ref.update({
      isActive: false,
    });

    logger.info("Leave store cleanup completed", {
      userId,
      storeId,
      staffId,
      deletedShifts: deletedShiftsCount,
      deletedRequests: requestsSnapshot.size,
    });

    return {
      success: true,
      deletedShifts: deletedShiftsCount,
      deletedRequests: requestsSnapshot.size,
    };
  } catch (error) {
    logger.error("Error in leave store cleanup", error);
    throw new Error(`クリーンアップ処理に失敗しました: ${error.message}`);
  }
});
