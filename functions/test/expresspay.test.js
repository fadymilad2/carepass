const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createExpressPayClient, amountInMinorUnits, normalizeQuery } = require('../src/expresspay_client');
const { verifyOrder } = require('../src/expresspay');
const { fulfillPayment } = require('../src/payment_service');

const credentials = { merchantId: 'merchant-test', apiKey: 'secret-test' };
const order = { provider: 'expresspay', environment: 'sandbox', providerToken: 'test-token', uid: 'alice',
  amount: 12000, currency: 'GHS', status: 'pending', durationDays: 30, subscriptionType: 'individual',
  planId: 'monthly', discountId: 'half', discountCode: 'HALF' };
const approved = { result: 1, 'order-id': 'CP-test', token: 'test-token', currency: 'GHS', amount: '120.00' };
function database() {
  const records = new Map([['payment_orders/CP-test', { ...order }], ['users/alice', {}], ['discount_codes/half', {}]]);
  let writes = 0;
  const ref = (path) => ({ path, get: async () => ({ exists: records.has(path), data: () => records.get(path) }),
    collection: (name) => collection(`${path}/${name}`) });
  const collection = (path) => ({ doc: (id) => ref(`${path}/${id}`) });
  const tx = { get: (r) => r.get(), update: (r, data) => { writes++; records.set(r.path, { ...records.get(r.path), ...data }); },
    set: (r, data) => { writes++; records.set(r.path, data); } };
  return { collection, records, writes: () => writes, runTransaction: (fn) => fn(tx) };
}
test('sandbox submit uses form encoding and a checkout token, not exposed API credentials', async () => {
  const client = createExpressPayClient({ ...credentials, fetchImpl: async (url, init) => {
    assert.equal(url, 'https://sandbox.expresspaygh.com/api/submit.php');
    assert.equal(init.headers['Content-Type'], 'application/x-www-form-urlencoded');
    assert.equal(init.redirect, 'error');
    const body = new URLSearchParams(init.body);
    assert.equal(body.get('api-key'), credentials.apiKey);
    assert.equal(body.get('merchant-id'), credentials.merchantId);
    assert.equal(body.get('amount'), '120.00');
    return Response.json({ status: 1, 'order-id': 'CP-test', token: 'a+b&c' });
  } });
  const payment = await client.submit({ 'order-id': 'CP-test', amount: '120.00' });
  assert.equal(payment.authorizationUrl, 'https://sandbox.expresspaygh.com/payment?token=a%2Bb%26c');
  assert.ok(!payment.authorizationUrl.includes(credentials.apiKey));
});
test('provider credential errors and invalid JSON are sanitized', async () => {
  for (const response of [Response.json({ status: 2, message: credentials.apiKey }), new Response('not json'), new Response('bad', { status: 500 })]) {
    const client = createExpressPayClient({ ...credentials, fetchImpl: async () => response });
    await assert.rejects(client.submit({ 'order-id': 'CP-test' }), (e) => !e.message.includes(credentials.apiKey));
  }
  assert.throws(() => createExpressPayClient({ ...credentials, environment: 'production' }));
});
test('amounts are converted exactly and invalid formats are rejected', () => {
  assert.equal(amountInMinorUnits('0.29'), 29);
  assert.equal(amountInMinorUnits(120), 12000);
  for (const value of ['1.001', '-1', 'NaN', null, '1e2', '', '9007199254740991']) assert.throws(() => amountInMinorUnits(value));
});
test('query result distinguishes pending, declined and temporary provider errors', () => {
  assert.equal(normalizeQuery({ ...approved, result: 4 }, 'CP-test', order).status, 'pending');
  assert.equal(normalizeQuery({ ...approved, result: 2 }, 'CP-test', order).status, 'failed');
  for (const result of [3, 0, undefined]) assert.throws(() => normalizeQuery({ ...approved, result }, 'CP-test', order));
});
test('wrong owner, environment, provider or callback token cannot trigger a query', async () => {
  const provider = { query: async () => { assert.fail('Must not query an unrelated order'); } };
  for (const options of [{ uid: 'bob', environment: 'sandbox' }, { uid: 'alice', environment: 'live' }, { token: 'forged', environment: 'sandbox' }]) {
    await assert.rejects(verifyOrder(database(), provider, 'CP-test', options), { code: 'permission-denied' });
  }
  const db = database();
  db.records.get('payment_orders/CP-test').provider = 'paystack';
  await assert.rejects(verifyOrder(db, provider, 'CP-test', { uid: 'alice', environment: 'sandbox' }));
});
test('forged callbacks, mismatched amounts and currencies cannot activate subscriptions', async () => {
  for (const result of [{ ...approved, amount: '1.00' }, { ...approved, currency: 'USD' }, { ...approved, token: 'other' }, { ...approved, 'order-id': 'CP-other' }]) {
    const db = database();
    await assert.rejects(verifyOrder(db, { query: async () => result }, 'CP-test', { token: 'test-token', environment: 'sandbox' }));
    assert.equal(db.writes(), 0);
  }
});
test('pending and declined results never grant access', async () => {
  for (const result of [2, 4]) {
    const db = database();
    const response = await verifyOrder(db, { query: async () => ({ ...approved, result }) }, 'CP-test', { uid: 'alice', environment: 'sandbox' });
    assert.equal(response.status, result === 2 ? 'failed' : 'pending');
    assert.equal(db.writes(), 0);
  }
});
test('webhook queries the provider and repeated client verification fulfills once', async () => {
  const db = database();
  let calls = 0;
  const provider = { query: async () => { calls++; return approved; } };
  assert.deepEqual(await verifyOrder(db, provider, 'CP-test', { token: 'test-token', environment: 'sandbox' }), { status: 'success' });
  const writes = db.writes();
  assert.deepEqual(await verifyOrder(db, provider, 'CP-test', { uid: 'alice', environment: 'sandbox' }), { status: 'success' });
  assert.equal(db.writes(), writes);
  assert.equal(calls, 1);
  assert.equal(db.records.get('users/alice').subscriptionStatus, 'active');
  assert.equal(db.records.get('users/alice/payments/CP-test').environment, 'sandbox');
});
test('legacy Paystack fulfillment cannot fulfill expressPay orders', async () => {
  const db = database();
  await assert.rejects(fulfillPayment(db, { reference: 'CP-test', status: 'success', amount: 12000, currency: 'GHS', metadata: { user_id: 'alice' } }));
  assert.equal(db.writes(), 0);
});
