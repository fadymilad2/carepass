const { HttpsError } = require('firebase-functions/v2/https');

function createExpressPayClient({ merchantId, apiKey, environment = 'sandbox', fetchImpl = fetch }) {
  if (!['sandbox', 'live'].includes(environment)) throw new Error('Invalid expressPay environment');
  const origin = environment === 'live' ? 'https://expresspaygh.com' : 'https://sandbox.expresspaygh.com';
  async function request(endpoint, fields) {
    if (!merchantId || !apiKey) throw new HttpsError('failed-precondition', 'Payment service is not configured.');
    try {
      const response = await fetchImpl(`${origin}/api/${endpoint}.php`, {
        method: 'POST', redirect: 'error', signal: AbortSignal.timeout(20000),
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({ ...fields, 'merchant-id': merchantId, 'api-key': apiKey }).toString(),
      });
      if (!response.ok) throw new Error('Provider HTTP error');
      const data = await response.json();
      if (!data || typeof data !== 'object' || Array.isArray(data)) throw new Error('Invalid response');
      return data;
    } catch (_) {
      // Provider responses and request bodies may contain credentials or tokens.
      throw new HttpsError('unavailable', 'Unable to contact the payment provider. Please check again shortly.');
    }
  }
  return {
    async submit(fields) {
      const data = await request('submit', fields);
      if (Number(data.status) !== 1 || data['order-id'] !== fields['order-id'] ||
          typeof data.token !== 'string' || !data.token || data.token.length > 1024) {
        throw new HttpsError('unavailable', 'Unable to start checkout. Please contact support if this continues.');
      }
      return { token: data.token, authorizationUrl: `${origin}/payment?token=${encodeURIComponent(data.token)}` };
    },
    query: (token) => request('query', { token }),
  };
}

function amountInMinorUnits(value) {
  const text = String(value);
  if (!/^\d+(\.\d{1,2})?$/.test(text)) throw new HttpsError('failed-precondition', 'Invalid payment amount.');
  const [whole, fraction = ''] = text.split('.');
  const amount = Number(whole) * 100 + Number(fraction.padEnd(2, '0'));
  if (!Number.isSafeInteger(amount)) throw new HttpsError('failed-precondition', 'Invalid payment amount.');
  return amount;
}

// Only a server-to-server query result is passed here, never a callback payload.
function normalizeQuery(data, reference, order) {
  if (data['order-id'] !== reference || data.token !== order.providerToken) {
    throw new HttpsError('failed-precondition', 'Payment does not match the order.');
  }
  const result = Number(data.result);
  if (result === 4) return { status: 'pending' };
  if (result === 2) return { status: 'failed' };
  if (result !== 1) throw new HttpsError('unavailable', 'Payment status is unavailable. Please check again shortly.');
  return { status: 'success', reference, provider: 'expresspay', providerToken: data.token,
    environment: order.environment, amount: amountInMinorUnits(data.amount), currency: data.currency,
    metadata: { user_id: order.uid } };
}

module.exports = { createExpressPayClient, amountInMinorUnits, normalizeQuery };
