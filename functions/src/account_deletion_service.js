const { HttpsError } = require('firebase-functions/v2/https');

function deletionUid(request, now = Date.now()) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in before deleting your account.');
  if (request.data?.confirm !== true) throw new HttpsError('invalid-argument', 'Confirm account deletion.');
  const age = now / 1000 - Number(request.auth.token?.auth_time);
  if (!Number.isFinite(age) || age < -60 || age > 300) {
    throw new HttpsError('failed-precondition', 'Sign out and sign in again, then retry deletion within five minutes.');
  }
  // Never accept a UID supplied by the client.
  return request.auth.uid;
}

async function eraseAccount(db, auth, uid) {
  // The server-only deletion marker blocks client writes while cleanup runs.
  // Keep it after completion so still-valid ID tokens cannot recreate the profile.
  const marker = db.collection('account_deletions').doc(uid);
  const orders = db.collection('payment_orders').where('uid', '==', uid);
  while (true) {
    const page = await orders.limit(200).get();
    if (page.empty) break;
    await Promise.all(page.docs.map((doc) => db.recursiveDelete(doc.ref)));
  }
  // Firestore document deletion alone does not remove subcollections.
  await db.recursiveDelete(db.collection('users').doc(uid));
  try {
    await auth.deleteUser(uid);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
  }
  await marker.set({ status: 'completed', completedAt: new Date().toISOString() }, { merge: true });
  return { deleted: true };
}

async function requestDeletion(request, db, auth) {
  const uid = deletionUid(request);
  const admin = await db.collection('admin_users').doc(uid).get();
  if (admin.exists) throw new HttpsError('failed-precondition', 'Administrator accounts require administrator support for deletion.');
  const marker = db.collection('account_deletions').doc(uid);
  await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(marker);
    if (!snapshot.exists) tx.create(marker, { status: 'pending', requestedAt: new Date().toISOString() });
  });
  return eraseAccount(db, auth, uid);
}

module.exports = { deletionUid, eraseAccount, requestDeletion };
