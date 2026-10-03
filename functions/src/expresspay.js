const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret, defineString } = require('firebase-functions/params');
const { getFirestore } = require('firebase-admin/firestore');
const crypto = require('node:crypto');
const { quotePayment, fulfillPayment } = require('./payment_service');
const { createExpressPayClient, normalizeQuery } = require('./expresspay_client');

const merchantId = defineSecret('EXPRESSPAY_MERCHANT_ID');
const apiKey = defineSecret('EXPRESSPAY_API_KEY');
const environment = defineString('EXPRESSPAY_ENVIRONMENT', { default: 'sandbox' });
const sandboxUsers = defineString('EXPRESSPAY_SANDBOX_UIDS', { default: '' });
const options = { region: 'us-central1', cors: true, secrets: [merchantId, apiKey], timeoutSeconds: 30 };
function client() {
  return createExpressPayClient({ merchantId: merchantId.value(), apiKey: apiKey.value(), environment: environment.value() });
}
function requireUser(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Must be signed in.');
  return request.auth.uid;
}
function validateReference(reference) {
  if (typeof reference !== 'string' || !/^CP-[\w-]{1,64}$/.test(reference)) {
    throw new HttpsError('invalid-argument', 'Invalid order reference.');
  }
}

// Exported separately for deterministic tests without sending real payments.
async function verifyOrder(db, provider, reference, { uid, token, environment: expectedEnvironment } = {}) {
  validateReference(reference);
  const doc = await db.collection('payment_orders').doc(reference).get();
  if (!doc.exists) throw new HttpsError('not-found', 'Payment order not found.');
  const order = doc.data();
  if (order.provider !== 'expresspay' || order.environment !== expectedEnvironment ||
      (uid && uid !== order.uid) || (token !== undefined && token !== order.providerToken)) {
    throw new HttpsError('permission-denied', 'Payment does not match the order.');
  }
  if (!order.providerToken) throw new HttpsError('unavailable', 'Checkout is still being prepared.');
  if (order.status === 'success') return { status: 'success' };
  const payment = normalizeQuery(await provider.query(order.providerToken), reference, order);
  if (payment.status === 'success') await fulfillPayment(db, payment, uid);
  return { status: payment.status };
}

exports.initializeExpressPayPayment = onCall(options, async (request) => {
  const uid = requireUser(request);
  const currentEnvironment = environment.value();
  if (currentEnvironment === 'sandbox' && !sandboxUsers.value().split(',').map((s) => s.trim()).filter(Boolean).includes(uid)) {
    throw new HttpsError('permission-denied', 'Sandbox payments are only available to configured test accounts.');
  }
  const provider = client();
  const { email, planId, amount, currency, discountCode } = request.data || {};
  if (typeof email !== 'string' || email.length > 64 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new HttpsError('invalid-argument', 'A valid email (up to 64 characters) is required.');
  }
  const db = getFirestore();
  const order = await quotePayment(db, uid, planId, discountCode);
  if (order.amount === 0) throw new HttpsError('failed-precondition', 'Use free activation for this plan.');
  if (!Number.isFinite(amount) || Math.round(amount * 100) !== order.amount || currency !== order.currency) {
    throw new HttpsError('failed-precondition', 'The price has changed. Reload your plan and try again.');
  }
  const user = (await db.collection('users').doc(uid).get()).data();
  const name = typeof user?.username === 'string' ? user.username.trim() : '';
  const phone = typeof user?.phoneNumber === 'string' ? user.phoneNumber.trim() : '';
  if (!name || !/^\+?\d{9,15}$/.test(phone)) throw new HttpsError('failed-precondition', 'Complete your name and phone number before paying.');
  const projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
  if (!projectId) throw new HttpsError('failed-precondition', 'Payment callback is not configured.');
  const functionBase = `https://us-central1-${projectId}.cloudfunctions.net`;
  const reference = 'CP-' + crypto.randomUUID();
  const orderRef = db.collection('payment_orders').doc(reference);
  await orderRef.create({ ...order, provider: 'expresspay', environment: currentEnvironment,
    status: 'pending', createdAt: new Date().toISOString() });
  const parts = name.split(/\s+/);
  const payment = await provider.submit({
    firstname: parts[0].slice(0, 32), lastname: parts.slice(1).join(' ').slice(0, 64),
    email, phonenumber: phone, username: uid, accountnumber: uid, currency: order.currency,
    amount: (order.amount / 100).toFixed(2), 'order-id': reference,
    'order-desc': `CarePass ${order.planId}`.slice(0, 256),
    'redirect-url': `${functionBase}/expressPayCallback`, 'post-url': `${functionBase}/expressPayWebhook`,
  });
  await orderRef.update({ providerToken: payment.token });
  return { authorizationUrl: payment.authorizationUrl, reference };
});

exports.verifyExpressPayPayment = onCall(options, (request) => {
  const uid = requireUser(request);
  return verifyOrder(getFirestore(), client(), request.data?.reference, { uid, environment: environment.value() });
});

exports.expressPayWebhook = onRequest(options, async (req, res) => {
  if (req.method !== 'POST') return res.status(405).send('Method not allowed');
  const body = req.body || {};
  if (typeof body.token !== 'string' || !body.token || body.token.length > 1024) return res.status(400).send('Invalid request');
  try {
    // Callback contents are untrusted. Always query expressPay before fulfillment.
    await verifyOrder(getFirestore(), client(), body['order-id'], { token: body.token, environment: environment.value() });
    return res.status(200).send('OK');
  } catch (error) {
    const status = { 'invalid-argument': 400, 'permission-denied': 403, 'not-found': 404 }[error.code] || 503;
    return res.status(status).send('Unable to confirm payment');
  }
});

exports.expressPayCallback = onRequest({ region: 'us-central1' }, (req, res) => {
  // The app intercepts this URL. This fallback never treats a redirect as payment proof.
  res.set('Cache-Control', 'no-store').set('Content-Security-Policy', "default-src 'none'; style-src 'unsafe-inline'")
    .status(200).send('<!doctype html><html lang="en"><meta name="viewport" content="width=device-width, initial-scale=1"><title>CarePass payment</title><body><h1>Return to CarePass</h1><p>Your payment will be confirmed in the app. Mobile money payments may take a few minutes.</p></body></html>');
});

// Non-enumerable so Firebase does not attempt to deploy the test helper.
Object.defineProperty(exports, 'verifyOrder', { value: verifyOrder });
