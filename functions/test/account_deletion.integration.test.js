const { test } = require('node:test');
const assert = require('node:assert/strict');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const { requestDeletion } = require('../src/account_deletion_service');

test('emulators: removes Auth, nested Firestore records and orders; preserves other users', async () => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'Never run against production');
  assert.ok(process.env.FIREBASE_AUTH_EMULATOR_HOST, 'Never run against production');
  const app = initializeApp({ projectId: 'demo-carepass' }, 'deletion-integration');
  const db = getFirestore(app);
  const auth = getAuth(app);
  const uid = 'deletion-test-alice';
  try {
    await auth.createUser({ uid });
    await db.doc(`users/${uid}`).set({ username: 'Synthetic test' });
    await db.doc(`users/${uid}/payments/test`).set({ amount: 1 });
    await db.doc(`users/${uid}/favorites/test`).set({ providerId: 'test' });
    await db.doc(`users/${uid}/notifications/test`).set({ isRead: false });
    await db.doc('payment_orders/deletion-test-order').set({ uid });
    await db.doc('users/deletion-test-bob').set({ username: 'Keep' });
    const result = await requestDeletion({ auth: { uid, token: { auth_time: Date.now() / 1000 } }, data: { confirm: true } }, db, auth);
    assert.deepEqual(result, { deleted: true });
    await assert.rejects(auth.getUser(uid), { code: 'auth/user-not-found' });
    for (const path of [`users/${uid}`, `users/${uid}/payments/test`, `users/${uid}/favorites/test`, `users/${uid}/notifications/test`, 'payment_orders/deletion-test-order']) {
      assert.equal((await db.doc(path).get()).exists, false, path);
    }
    assert.equal((await db.doc('users/deletion-test-bob').get()).exists, true);
    assert.equal((await db.doc(`account_deletions/${uid}`).get()).data().status, 'completed');
  } finally {
    await deleteApp(app);
  }
});
