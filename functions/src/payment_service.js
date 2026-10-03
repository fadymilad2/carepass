const { HttpsError } = require('firebase-functions/v2/https');
const { FieldValue } = require('firebase-admin/firestore');

function payableAmount(price, discount) {
  if (!Number.isFinite(price) || price < 0) throw new HttpsError('failed-precondition', 'Invalid plan price.');
  let reduction = 0;
  if (discount) {
    const value = discount.discount;
    if (!Number.isFinite(value) || value < 0 || !['percent', 'fixed'].includes(discount.type)) {
      throw new HttpsError('failed-precondition', 'Invalid discount configuration.');
    }
    reduction = discount.type === 'percent' ? price * Math.min(value, 100) / 100 : value;
  }
  // Preserve the existing application charge calculation.
  return Math.round(Math.max(0, price - reduction) * 1.2 * 100);
}

function validateDiscount(data, now = Date.now()) {
  const expiry = data.expiryDate && new Date(data.expiryDate).getTime();
  if (data.isActive !== true || (data.maxUses > 0 && (data.currentUses || 0) >= data.maxUses) ||
      (data.expiryDate && (!Number.isFinite(expiry) || expiry <= now))) {
    throw new HttpsError('failed-precondition', 'Discount code is unavailable or expired.');
  }
}

async function resolvePlan(db, id) {
  if (typeof id !== 'string' || !id.trim() || id.includes('/')) throw new HttpsError('invalid-argument', 'Invalid plan.');
  let doc = await db.collection('subscription_plans').doc(id).get();
  if (!doc.exists) {
    const plans = await db.collection('subscription_plans').where('isActive', '==', true).get();
    doc = plans.docs.find((p) => (p.data().name || '').toLowerCase() === id.toLowerCase());
  }
  if (!doc || !doc.exists || doc.data().isActive !== true) throw new HttpsError('not-found', 'Active plan not found.');
  return { ...doc.data(), id: doc.id };
}

async function quotePayment(db, uid, planId, discountCode) {
  const plan = await resolvePlan(db, planId);
  let price = plan.price;
  const user = (await db.collection('users').doc(uid).get()).data();
  if (!user) throw new HttpsError('failed-precondition', 'Complete your profile first.');
  const expiry = new Date(user.cardExpiryDate).getTime();
  if (plan.type === 'family' && user.subscriptionStatus === 'active' && user.subscriptionType !== 'family' && expiry > Date.now()) {
    const current = await resolvePlan(db, user.planName);
    if (current.durationDays >= 365) throw new HttpsError('failed-precondition', 'Contact support to upgrade an annual plan.');
    const remaining = Math.min(current.durationDays, Math.floor((expiry - Date.now()) / 86400000));
    if (current.durationDays - remaining <= 15) price = Math.max(0, price - current.price);
  }
  let discount = null;
  let discountId = null;
  if (discountCode) {
    if (typeof discountCode !== 'string') throw new HttpsError('invalid-argument', 'Invalid discount code.');
    const snap = await db.collection('discount_codes').where('code', '==', discountCode.trim().toUpperCase()).limit(1).get();
    if (snap.empty) throw new HttpsError('not-found', 'Discount code not found.');
    discount = snap.docs[0].data();
    discountId = snap.docs[0].id;
    validateDiscount(discount);
  }
  const durationDays = plan.durationDays ?? 30;
  if (!Number.isInteger(durationDays) || durationDays <= 0) throw new HttpsError('failed-precondition', 'Invalid plan duration.');
  return { uid, planId: plan.id, amount: payableAmount(price, discount), currency: plan.currency || 'GHS',
    durationDays, subscriptionType: (plan.type || 'individual').toLowerCase(), discountId, discountCode: discount?.code || null };
}

function subscriptionFields(order, now) {
  return { subscriptionStatus: 'active', planName: order.planId, subscriptionType: order.subscriptionType,
    cardExpiryDate: new Date(now.getTime() + order.durationDays * 86400000).toISOString(),
    memberId: 'CP-' + order.uid.substring(0, 8).toUpperCase(), bpChecksUsedThisMonth: 0,
    sugarChecksUsedThisMonth: 0, checksResetMonth: now.toISOString().slice(0, 7) };
}

async function fulfillPayment(db, payment, callerUid) {
  if (typeof payment?.reference !== 'string' || !/^[\w-]+$/.test(payment.reference)) throw new HttpsError('invalid-argument', 'Invalid reference.');
  const orderRef = db.collection('payment_orders').doc(payment.reference);
  return db.runTransaction(async (tx) => {
    const doc = await tx.get(orderRef);
    if (!doc.exists) throw new HttpsError('not-found', 'Payment order not found.');
    const order = doc.data();
    if ((order.provider || 'paystack') !== (payment.provider || 'paystack') ||
        (order.provider === 'expresspay' && (payment.providerToken !== order.providerToken || payment.environment !== order.environment))) {
      throw new HttpsError('failed-precondition', 'Payment provider does not match the order.');
    }
    if ((callerUid && callerUid !== order.uid) || payment.metadata?.user_id !== order.uid) {
      throw new HttpsError('permission-denied', 'Payment belongs to another account.');
    }
    if (payment.status !== 'success' || payment.amount !== order.amount || payment.currency !== order.currency) {
      throw new HttpsError('failed-precondition', 'Payment does not match the order.');
    }
    if (order.status === 'success') return true;
    const now = new Date();
    const userRef = db.collection('users').doc(order.uid);
    tx.update(userRef, subscriptionFields(order, now));
    tx.update(orderRef, { status: 'success', fulfilledAt: now.toISOString() });
    tx.set(userRef.collection('payments').doc(payment.reference), {
      reference: payment.reference, amount: order.amount / 100, currency: order.currency,
      planId: order.planId, status: 'success', provider: order.provider || 'paystack',
      environment: order.environment || 'live', discountCode: order.discountCode, createdAt: now.toISOString() });
    if (order.discountId) tx.update(db.collection('discount_codes').doc(order.discountId), {
      currentUses: FieldValue.increment(1), lastUsedAt: now.toISOString() });
    return true;
  });
}
module.exports = { payableAmount, validateDiscount, quotePayment, fulfillPayment, subscriptionFields };
