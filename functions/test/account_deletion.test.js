const { test } = require('node:test');
const assert = require('node:assert/strict');
const { deletionUid, requestDeletion, eraseAccount } = require('../src/account_deletion_service');

const request = () => ({ auth: { uid: 'alice', token: { auth_time: Date.now() / 1000 } }, data: { confirm: true, uid: 'bob' } });

test('deletion requires confirmation and recent authentication and ignores supplied UID', () => {
  assert.equal(deletionUid(request()), 'alice');
  assert.throws(() => deletionUid({}), { code: 'unauthenticated' });
  assert.throws(() => deletionUid({ ...request(), data: {} }), { code: 'invalid-argument' });
  assert.throws(() => deletionUid({ ...request(), auth: { uid: 'alice', token: { auth_time: 1 } } }), { code: 'failed-precondition' });
  assert.throws(() => deletionUid({ ...request(), auth: { uid: 'alice', token: {} } }), { code: 'failed-precondition' });
});

function fixture() {
  const records = new Map([
    ['users/alice', { username: 'Alice' }],
    ['users/alice/favorites/p1', {}],
    ['users/alice/payments/p1', {}],
    ['users/alice/notifications/n1', {}],
    ['users/bob', { username: 'Bob' }],
    ['payment_orders/bob-order', { uid: 'bob' }],
  ]);
  for (let i = 0; i < 205; i++) records.set(`payment_orders/a-${i}`, { uid: 'alice' });
  const deletedAuth = [];
  const ref = (path) => ({ path,
    get: async () => ({ exists: records.has(path), data: () => records.get(path) }),
    set: async (data) => records.set(path, { ...records.get(path), ...data }),
  });
  const db = {
    collection: (name) => ({ doc: (id) => ref(`${name}/${id}`), where: (field, op, uid) => ({ limit: (limit) => ({ get: async () => {
      const docs = [...records].filter(([path, value]) => path.startsWith(`${name}/`) && value[field] === uid).slice(0, limit).map(([path]) => ({ ref: ref(path) }));
      return { docs, empty: docs.length === 0 };
    } }) }) }),
    runTransaction: async (fn) => fn({ get: (r) => r.get(), create: (r, data) => records.set(r.path, data) }),
    recursiveDelete: async (r) => {
      for (const path of records.keys()) if (path === r.path || path.startsWith(`${r.path}/`)) records.delete(path);
    },
  };
  const auth = { deleteUser: async (uid) => deletedAuth.push(uid) };
  return { db, auth, records, deletedAuth };
}

test('deletes only caller account, all nested data and paginated orders before confirming', async () => {
  const f = fixture();
  assert.deepEqual(await requestDeletion(request(), f.db, f.auth), { deleted: true });
  assert.deepEqual(f.deletedAuth, ['alice']);
  assert.deepEqual([...f.records.keys()].sort(), ['account_deletions/alice', 'payment_orders/bob-order', 'users/bob']);
  assert.equal(f.records.get('account_deletions/alice').status, 'completed');
});

test('a data deletion failure cannot report success or delete authentication; retry completes', async () => {
  const f = fixture();
  const remove = f.db.recursiveDelete;
  f.db.recursiveDelete = async () => { throw new Error('temporary failure'); };
  await assert.rejects(requestDeletion(request(), f.db, f.auth), /temporary failure/);
  assert.equal(f.records.get('account_deletions/alice').status, 'pending');
  assert.deepEqual(f.deletedAuth, []);
  f.db.recursiveDelete = remove;
  await eraseAccount(f.db, f.auth, 'alice');
  assert.equal(f.records.get('account_deletions/alice').status, 'completed');
});

test('authentication failures remain retryable, and already removed auth users are safe', async () => {
  const f = fixture();
  f.auth.deleteUser = async () => { throw Object.assign(new Error('offline'), { code: 'auth/internal-error' }); };
  await assert.rejects(requestDeletion(request(), f.db, f.auth), /offline/);
  assert.equal(f.records.get('account_deletions/alice').status, 'pending');
  f.auth.deleteUser = async () => { throw { code: 'auth/user-not-found' }; };
  assert.deepEqual(await eraseAccount(f.db, f.auth, 'alice'), { deleted: true });
});

test('administrator account cannot be removed through customer self-service', async () => {
  const f = fixture();
  f.records.set('admin_users/alice', { isActive: true });
  await assert.rejects(requestDeletion(request(), f.db, f.auth), { code: 'failed-precondition' });
  assert.equal(f.records.has('account_deletions/alice'), false);
});
