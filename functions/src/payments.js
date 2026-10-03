const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const crypto = require('node:crypto');
const { quotePayment, fulfillPayment, subscriptionFields, validateDiscount } = require('./payment_service');
const paystackSecretKey = defineSecret('PAYSTACK_SECRET_KEY');
const options = { cors: true, secrets: [paystackSecretKey], timeoutSeconds: 30 };
function requireUser(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Must be signed in.');
  return request.auth.uid;
}
async function paystack(path, init = {}) {
  const response = await fetch(`https://api.paystack.co/${path}`, {
    ...init, signal: AbortSignal.timeout(20000),
    headers: { Authorization: `Bearer ${paystackSecretKey.value()}`, 'Content-Type': 'application/json' },
  });
  const result = await response.json();
  if (!response.ok || result.status !== true) throw new HttpsError('unavailable', 'Payment provider unavailable. Try again.');
  return result.data;
}
exports.initializePaystackPayment = onCall(options, async (request) => {
  const uid = requireUser(request);
  const { email, planId, amount, currency, discountCode } = request.data || {};
  if (typeof email !== 'string' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) throw new HttpsError('invalid-argument', 'Valid email required.');
  const db = getFirestore();
  const order = await quotePayment(db, uid, planId, discountCode);
  if (order.amount === 0) throw new HttpsError('failed-precondition', 'Use free activation for this plan.');
  if (!Number.isFinite(amount) || Math.round(amount * 100) !== order.amount || currency !== order.currency) {
    throw new HttpsError('failed-precondition', 'The price has changed. Reload your plan and try again.');
  }
  const reference = 'CP-' + crypto.randomUUID();
  await db.collection('payment_orders').doc(reference).create({ ...order, status: 'pending', createdAt: new Date().toISOString() });
  const payment = await paystack('transaction/initialize', {
    method: 'POST', body: JSON.stringify({ email, amount: order.amount, currency: order.currency, reference,
      metadata: { user_id: uid, plan_id: order.planId, app: 'CarePass' },
      callback_url: 'https://carepassghana.com/payment/callback' }),
  });
  return { authorizationUrl: payment.authorization_url, reference };
});
exports.verifyPaystackPayment = onCall(options, async (request) => {
  const uid = requireUser(request);
  const reference = request.data?.reference;
  if (typeof reference !== 'string' || !/^[\w-]+$/.test(reference)) throw new HttpsError('invalid-argument', 'Invalid reference.');
  const payment = await paystack(`transaction/verify/${encodeURIComponent(reference)}`);
  if (payment.status !== 'success') return { success: false };
  return { success: await fulfillPayment(getFirestore(), payment, uid) };
});
exports.activateFreeSubscription = onCall({ cors: true, timeoutSeconds: 30 }, async (request) => {
  const uid = requireUser(request);
  const db = getFirestore();
  const order = await quotePayment(db, uid, request.data?.planId, request.data?.discountCode);
  if (order.amount !== 0) throw new HttpsError('failed-precondition', 'This order requires payment.');
  const key = crypto.createHash('sha256').update(JSON.stringify([uid, order.planId, order.discountId])).digest('hex');
  await db.runTransaction(async (tx) => {
    const receipt = db.collection('payment_orders').doc(`free-${key}`);
    if ((await tx.get(receipt)).exists) return;
    const discountRef = order.discountId && db.collection('discount_codes').doc(order.discountId);
    if (discountRef) {
      const discount = await tx.get(discountRef);
      if (!discount.exists) throw new HttpsError('not-found', 'Discount no longer exists.');
      validateDiscount(discount.data());
    }
    const now = new Date();
    tx.update(db.collection('users').doc(uid), subscriptionFields(order, now));
    tx.create(receipt, { ...order, status: 'success', createdAt: now.toISOString() });
    if (discountRef) tx.update(discountRef, { currentUses: FieldValue.increment(1), lastUsedAt: now.toISOString() });
  });
  return { success: true };
});
exports.paystackWebhook = onRequest(options, async (req, res) => {
  if (req.method !== 'POST') return res.status(405).send('Method not allowed');
  const signature = req.headers['x-paystack-signature'];
  if (typeof signature !== 'string' || !/^[a-f0-9]{128}$/i.test(signature)) return res.status(401).send('Unauthorized');
  const hash = crypto.createHmac('sha512', paystackSecretKey.value()).update(req.rawBody).digest();
  if (!crypto.timingSafeEqual(hash, Buffer.from(signature, 'hex'))) return res.status(401).send('Unauthorized');
  if (req.body?.event === 'charge.success') {
    try { await fulfillPayment(getFirestore(), req.body.data); }
    catch (error) {
      console.error('Payment fulfillment failed', error);
      return res.status(500).send('Fulfillment failed');
    }
  }
  return res.status(200).send('OK');
});
