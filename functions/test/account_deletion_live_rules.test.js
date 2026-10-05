const { test, before, after } = require('node:test');
const { readFileSync } = require('node:fs');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, deleteDoc } = require('firebase/firestore');
let env;
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-carepass-deletion-rules', firestore: {
    rules: readFileSync(require('node:path').join(__dirname, '../../firestore.account-deletion.rules'), 'utf8'),
  } });
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'account_deletions/deleted'), { status: 'completed' });
    await setDoc(doc(ctx.firestore(), 'users/deleted/notifications/late'), { body: 'Private' });
    await setDoc(doc(ctx.firestore(), 'providers/p1'), { name: 'Clinic' });
  });
});
after(async () => { await env?.cleanup(); });
test('scoped live rules block deleted users and protect deletion markers', async () => {
  const db = env.authenticatedContext('deleted').firestore();
  await assertFails(setDoc(doc(db, 'users/deleted'), { username: 'Recreated' }));
  await assertFails(setDoc(doc(db, 'users/deleted/favorites/p1'), { providerId: 'p1' }));
  await assertFails(getDoc(doc(db, 'users/deleted/notifications/late')));
  await assertFails(deleteDoc(doc(db, 'account_deletions/deleted')));
  await assertFails(setDoc(doc(db, 'account_deletions/other'), { status: 'pending' }));
});
test('scoped live rules preserve ordinary profile access and public catalog', async () => {
  const db = env.authenticatedContext('ordinary').firestore();
  await assertSucceeds(setDoc(doc(db, 'users/ordinary'), { username: 'Ordinary' }));
  await assertSucceeds(getDoc(doc(db, 'users/ordinary')));
  await assertSucceeds(getDoc(doc(env.unauthenticatedContext().firestore(), 'providers/p1')));
});
