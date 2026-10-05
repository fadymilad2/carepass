const { test } = require('node:test');
const assert = require('node:assert/strict');
const { payableAmount, validateDiscount, fulfillPayment } = require('../src/payment_service');
const { validateMapsUrl, fetchMapsUrl } = require('../src/maps_url');

test('pricing uses minor units and bounds discounts', () => {
  assert.equal(payableAmount(100), 12000);
  assert.equal(payableAmount(100, { type: 'percent', discount: 50 }), 6000);
  assert.equal(payableAmount(100, { type: 'percent', discount: 150 }), 0);
  assert.equal(payableAmount(100, { type: 'fixed', discount: 150 }), 0);
  assert.equal(payableAmount(0.2), 24);
  assert.throws(() => payableAmount(NaN));
  assert.throws(() => payableAmount(-1));
});
test('discount validation rejects malformed dates and exhausted codes', () => {
  assert.throws(() => validateDiscount({ isActive: true, expiryDate: 'invalid' }));
  assert.throws(() => validateDiscount({ isActive: true, maxUses: 1, currentUses: 1 }));
  assert.doesNotThrow(() => validateDiscount({ isActive: true, maxUses: 0 }));
});

function fakeDatabase() {
  const records = new Map([
    ['payment_orders/CP-123', { uid: 'alice', amount: 12000, currency: 'GHS', status: 'pending',
      durationDays: 30, subscriptionType: 'individual', planId: 'monthly', discountId: 'half', discountCode: 'HALF' }],
    ['users/alice', {}], ['discount_codes/half', {}],
  ]);
  let writes = 0;
  const ref = (path) => ({ path, collection: (name) => collection(`${path}/${name}`) });
  const collection = (path) => ({ doc: (id) => ref(`${path}/${id}`) });
  const tx = {
    get: async (r) => ({ exists: records.has(r.path), data: () => records.get(r.path) }),
    update: (r, data) => { writes++; records.set(r.path, { ...records.get(r.path), ...data }); },
    set: (r, data) => { writes++; records.set(r.path, data); },
  };
  return { collection, runTransaction: (callback) => callback(tx), records, writes: () => writes };
}
const payment = { reference: 'CP-123', status: 'success', amount: 12000, currency: 'GHS', metadata: { user_id: 'alice' } };
test('payment completion cannot restore an account after deletion starts', async () => {
  const db = fakeDatabase();
  db.records.set('account_deletions/alice', { status: 'pending' });
  await assert.rejects(fulfillPayment(db, payment, 'alice'), { code: 'failed-precondition' });
  assert.equal(db.writes(), 0);
});
test('verification cannot activate another account', async () => {
  const db = fakeDatabase();
  await assert.rejects(fulfillPayment(db, payment, 'bob'), { code: 'permission-denied' });
  assert.equal(db.writes(), 0);
});
test('underpayment cannot activate a subscription', async () => {
  const db = fakeDatabase();
  await assert.rejects(fulfillPayment(db, { ...payment, amount: 1 }, 'alice'), { code: 'failed-precondition' });
  assert.equal(db.writes(), 0);
});
test('webhook and verification fulfill an order only once', async () => {
  const db = fakeDatabase();
  assert.equal(await fulfillPayment(db, payment, 'alice'), true);
  const writes = db.writes();
  const expiry = db.records.get('users/alice').cardExpiryDate;
  assert.equal(await fulfillPayment(db, payment), true);
  assert.equal(db.writes(), writes);
  assert.equal(db.records.get('users/alice').cardExpiryDate, expiry);
  assert.equal(db.records.get('users/alice/payments/CP-123').status, 'success');
});
test('Maps URL validation rejects arbitrary hosts and credentials', () => {
  for (const url of ['http://google.com/maps', 'https://127.0.0.1', 'https://google.com.evil.test/maps', 'https://user:pass@google.com/maps']) {
    assert.throws(() => validateMapsUrl(url));
  }
  assert.equal(validateMapsUrl('https://maps.app.goo.gl/example').hostname, 'maps.app.goo.gl');
});
test('Maps redirects are validated before fetching the destination', async (t) => {
  let calls = 0;
  t.mock.method(global, 'fetch', async () => {
    calls++;
    return new Response(null, { status: 302, headers: { location: 'http://127.0.0.1/internal' } });
  });
  await assert.rejects(fetchMapsUrl('https://maps.app.goo.gl/example'));
  assert.equal(calls, 1);
});
