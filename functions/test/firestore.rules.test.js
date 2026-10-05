const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, getDoc, deleteDoc } = require('firebase/firestore');

let env;
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-carepass', firestore: {
    rules: readFileSync(require('node:path').join(__dirname, '../../firestore.rules'), 'utf8'),
  } });
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/alice'), { username: 'Alice', subscriptionStatus: 'active', bpChecksUsedThisMonth: 1 });
    await setDoc(doc(db, 'users/bob'), { username: 'Bob', subscriptionStatus: 'none' });
    await setDoc(doc(db, 'users/alice/notifications/n1'), { body: 'Private', isRead: false });
    await setDoc(doc(db, 'users/alice/payments/p1'), { amount: 100 });
    await setDoc(doc(db, 'providers/p1'), { name: 'Clinic' });
    await setDoc(doc(db, 'admin_users/admin'), { isActive: true });
  });
});
after(async () => { await env?.cleanup(); });
test('deletion markers block old sessions from reading or recreating private data', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'account_deletions/deleted'), { status: 'completed' });
    await setDoc(doc(context.firestore(), 'users/deleted/notifications/late'), { isRead: false });
  });
  const db = env.authenticatedContext('deleted').firestore();
  await assertFails(setDoc(doc(db, 'users/deleted'), { username: 'Recreated' }));
  await assertFails(getDoc(doc(db, 'users/deleted/notifications/late')));
  await assertFails(setDoc(doc(db, 'users/deleted/favorites/p1'), { providerId: 'p1' }));
  await assertFails(deleteDoc(doc(db, 'account_deletions/deleted')));
  await assertFails(setDoc(doc(db, 'account_deletions/alice'), { status: 'pending' }));
});
test('users cannot read another account or its private subcollections', async () => {
  const db = env.authenticatedContext('bob').firestore();
  await assertFails(getDoc(doc(db, 'users/alice')));
  await assertFails(getDoc(doc(db, 'users/alice/notifications/n1')));
  await assertFails(getDoc(doc(db, 'users/alice/payments/p1')));
  await assertSucceeds(getDoc(doc(db, 'users/bob')));
});
test('profile edits work while subscription, role and quota edits fail', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertSucceeds(updateDoc(doc(db, 'users/alice'), { username: 'Updated' }));
  await assertFails(updateDoc(doc(db, 'users/alice'), { subscriptionStatus: 'none' }));
  await assertFails(updateDoc(doc(db, 'users/alice'), { bpChecksUsedThisMonth: 0 }));
  await assertFails(updateDoc(doc(db, 'users/alice'), { role: 'admin' }));
  await assertFails(updateDoc(doc(db, 'users/alice'), { username: 42 }));
  await assertFails(setDoc(doc(db, 'admin_users/alice'), { isActive: true }));
});
test('new profiles cannot self-activate subscriptions', async () => {
  const db = env.authenticatedContext('new').firestore();
  await assertFails(setDoc(doc(db, 'users/new'), { username: 'New', subscriptionStatus: 'active' }));
  await assertSucceeds(setDoc(doc(db, 'users/new'), { username: 'New', subscriptionStatus: 'none' }));
  await assertFails(updateDoc(doc(db, 'users/new'), { subscriptionStatus: 'active' }));
});
test('notification owners may mark read and delete but not alter content', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertSucceeds(updateDoc(doc(db, 'users/alice/notifications/n1'), { isRead: true }));
  await assertFails(updateDoc(doc(db, 'users/alice/notifications/n1'), { body: 'Forged' }));
  await assertSucceeds(deleteDoc(doc(db, 'users/alice/notifications/n1')));
});
test('guest catalog access works without exposing private records', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertSucceeds(getDoc(doc(db, 'providers/p1')));
  await assertFails(getDoc(doc(db, 'users/alice')));
});

test('a legacy token-only profile can complete registration safely', async () => {
  const db = env.authenticatedContext('partial').firestore();
  await assertSucceeds(setDoc(doc(db, 'users/partial'), { fcmToken: 'token' }));
  await assertFails(setDoc(doc(db, 'users/partial'), { username: 'New', subscriptionStatus: 'active' }));
  await assertSucceeds(setDoc(doc(db, 'users/partial'), { username: 'New', subscriptionStatus: 'none', planName: '', memberId: '', cardExpiryDate: '', subscriptionType: 'individual', bpChecksUsedThisMonth: 0, sugarChecksUsedThisMonth: 0, checksResetMonth: '' }));
});

test('favorites are private and restricted to existing providers', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  const bob = env.authenticatedContext('bob').firestore();
  await assertSucceeds(setDoc(doc(alice, 'users/alice/favorites/p1'), { providerId: 'p1' }));
  await assertFails(getDoc(doc(bob, 'users/alice/favorites/p1')));
  await assertFails(setDoc(doc(alice, 'users/alice/favorites/missing'), { providerId: 'missing' }));
});

test('concurrent health checks cannot exceed the monthly quota', async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('An emulator is required.');
  const functions = require('../index');
  const db = require('firebase-admin/firestore').getFirestore();
  await db.doc('users/quota').set({ subscriptionStatus: 'active', cardExpiryDate: new Date(Date.now() + 86400000).toISOString(), checksResetMonth: '2000-01', bpChecksUsedThisMonth: 9, sugarChecksUsedThisMonth: 9 });
  await db.doc('settings/app_config').set({ bloodPressureChecksPerMonth: 1 });
  const request = { auth: { uid: 'quota' }, data: { type: 'blood_pressure' } };
  const results = await Promise.allSettled([functions.recordHealthCheck.run(request), functions.recordHealthCheck.run(request)]);
  assert.equal(results.filter((r) => r.status === 'fulfilled').length, 1);
  const user = (await db.doc('users/quota').get()).data();
  assert.equal(user.bpChecksUsedThisMonth, 1);
  assert.equal(user.sugarChecksUsedThisMonth, 0);
});
