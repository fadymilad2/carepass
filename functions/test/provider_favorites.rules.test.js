const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { resolve } = require('node:path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { collection, doc, setDoc, getDoc, getDocs, query, where, updateDoc, deleteDoc } = require('firebase/firestore');

let baseline;
let fixed;
before(async () => {
  const original = JSON.parse(readFileSync(resolve(__dirname, '../../docs/firestore-deployed-before-providers-fix.json'), 'utf8')).files[0].content;
  baseline = await initializeTestEnvironment({ projectId: 'demo-providers-before', firestore: { rules: original } });
  fixed = await initializeTestEnvironment({ projectId: 'demo-providers-after', firestore: { rules: readFileSync(resolve(__dirname, '../../firestore.providers-hotfix.rules'), 'utf8') } });
  for (const env of [baseline, fixed]) {
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'providers/clinic'), { name: 'Clinic', isActive: true, area: 'Accra' });
      await setDoc(doc(db, 'users/alice'), { username: 'Alice' });
      await setDoc(doc(db, 'users/bob'), { username: 'Bob' });
      await setDoc(doc(db, 'users/alice/favorites/clinic'), { providerId: 'clinic' });
    });
  }
});
after(async () => { await baseline?.cleanup(); await fixed?.cleanup(); });

test('reproduces production: catalog succeeds but signed-in favorites list fails', async () => {
  const db = baseline.authenticatedContext('alice').firestore();
  await assertSucceeds(getDocs(query(collection(db, 'providers'), where('isActive', '==', true), where('area', '==', 'Accra'))));
  await assertFails(getDocs(collection(db, 'users/alice/favorites')));
});
test('fixed rules allow the exact provider and favorites queries after sign-in', async () => {
  const db = fixed.authenticatedContext('alice').firestore();
  const providers = await assertSucceeds(getDocs(query(collection(db, 'providers'), where('isActive', '==', true), where('area', '==', 'Accra'))));
  const favorites = await assertSucceeds(getDocs(collection(db, 'users/alice/favorites')));
  assert.equal(providers.size, 1);
  assert.equal(favorites.docs[0].id, 'clinic');
});
test('guest catalog access still works; private favorites are inaccessible', async () => {
  const db = fixed.unauthenticatedContext().firestore();
  await assertSucceeds(getDocs(query(collection(db, 'providers'), where('isActive', '==', true))));
  await assertFails(getDocs(collection(db, 'users/alice/favorites')));
  await assertFails(setDoc(doc(db, 'users/alice/favorites/clinic'), { providerId: 'clinic' }));
});
test('another user cannot read, list, create, update or delete favorites', async () => {
  const db = fixed.authenticatedContext('bob').firestore();
  const ref = doc(db, 'users/alice/favorites/clinic');
  await assertFails(getDoc(ref));
  await assertFails(getDocs(collection(db, 'users/alice/favorites')));
  await assertFails(setDoc(ref, { providerId: 'clinic' }));
  await assertFails(updateDoc(ref, { providerId: 'clinic' }));
  await assertFails(deleteDoc(ref));
});
test('owner can toggle favorites but cannot forge or corrupt their payload', async () => {
  const db = fixed.authenticatedContext('alice').firestore();
  const ref = doc(db, 'users/alice/favorites/clinic');
  await assertSucceeds(deleteDoc(ref));
  await assertSucceeds(setDoc(ref, { providerId: 'clinic' }));
  await assertSucceeds(updateDoc(ref, { providerId: 'clinic' }));
  await assertFails(updateDoc(ref, { role: 'admin' }));
  await assertFails(updateDoc(ref, { providerId: 42 }));
  await assertFails(setDoc(ref, {}));
  await assertFails(setDoc(ref, { providerId: 'wrong' }));
  await assertFails(setDoc(doc(db, 'users/alice/favorites/missing'), { providerId: 'missing' }));
});
