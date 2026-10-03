const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getFirestore } = require('firebase-admin/firestore');

exports.recordHealthCheck = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Must be signed in.');
  const type = request.data?.type;
  if (!['blood_pressure', 'blood_sugar'].includes(type)) throw new HttpsError('invalid-argument', 'Invalid check type.');
  const db = getFirestore();
  const userRef = db.collection('users').doc(request.auth.uid);
  await db.runTransaction(async (tx) => {
    const userDoc = await tx.get(userRef);
    const configDoc = await tx.get(db.collection('settings').doc('app_config'));
    const user = userDoc.data();
    if (!user || user.subscriptionStatus !== 'active' || !(new Date(user.cardExpiryDate).getTime() > Date.now())) {
      throw new HttpsError('failed-precondition', 'An active subscription is required.');
    }
    const month = new Date().toISOString().slice(0, 7);
    const reset = user.checksResetMonth !== month;
    const bp = reset ? 0 : (user.bpChecksUsedThisMonth || 0);
    const sugar = reset ? 0 : (user.sugarChecksUsedThisMonth || 0);
    const isBp = type === 'blood_pressure';
    const settings = configDoc.data() || {};
    const limit = settings[isBp ? 'bloodPressureChecksPerMonth' : 'bloodSugarChecksPerMonth'] ?? 1;
    if (!Number.isInteger(limit) || limit < 0 || (isBp ? bp : sugar) >= limit) {
      throw new HttpsError('resource-exhausted', 'You have used all your checks for this month.');
    }
    tx.update(userRef, { checksResetMonth: month,
      bpChecksUsedThisMonth: bp + (isBp ? 1 : 0),
      sugarChecksUsedThisMonth: sugar + (isBp ? 0 : 1) });
  });
  return { success: true };
});
