import test from 'node:test';
import assert from 'node:assert/strict';
import worker, { handle, SKUS } from '../src/worker.mjs';

const sku = 'com.ScrapSquad.app.founder';
const payload = { userId: 'user/with+symbols', receiptId: 'receipt/:+=', sku, environment: 'PRODUCTION' };
const receipt = { receiptId: payload.receiptId, productId: sku, productType: 'ENTITLED', purchaseDate: 123456789, cancelDate: null };
function environment(values = {}) { return { RVS_ENVIRONMENT: 'PRODUCTION', AMAZON_SHARED_SECRET: 'server/secret', IP_LIMIT: { limit: async () => ({ success: true }) }, USER_LIMIT: { limit: async () => ({ success: true }) }, ...values }; }
function request(body = payload, options = {}) { return new Request('https://example.test/v1/amazon/verify', { method: 'POST', headers: { 'Content-Type': 'application/json', 'CF-Connecting-IP': '192.0.2.1' }, body: JSON.stringify(body), ...options }); }
const good = async () => Response.json(receipt);

test('binds the exact Amazon user/receipt/product and makes repeat verification idempotent', async () => {
  let calls = 0;
  const amazon = async (url, options) => {
    calls++; assert.equal(url, 'https://appstore-sdk.amazon.com/version/1.0/verifyReceiptId/developer/server%2Fsecret/user/user%2Fwith%2Bsymbols/receiptId/receipt%2F%3A%2B%3D');
    assert.equal(options.redirect, 'error'); return Response.json(receipt);
  };
  for (let i = 0; i < 2; i++) {
    const response = await handle(request(), environment(), amazon);
    assert.equal(response.status, 200); assert.equal(response.headers.get('cache-control'), 'no-store');
    assert.equal(response.headers.get('access-control-allow-origin'), null);
    assert.deepEqual(await response.json(), { ...payload, active: true });
  }
  assert.equal(calls, 2); assert.equal(SKUS.size, 7);
});
test('canceled receipts including zero cancel timestamp never grant', async () => {
  for (const cancelDate of [0, 123456790]) {
    const response = await handle(request(), environment(), async () => Response.json({ ...receipt, cancelDate }));
    assert.equal(response.status, 200); assert.equal((await response.json()).active, false);
  }
});
test('Amazon 400/410 revoke, while errors and throttling do not masquerade as revocation', async () => {
  for (const status of [400, 410, 429, 496, 497, 500, 302]) {
    const response = await handle(request(), environment(), async () => new Response(null, { status }));
    assert.equal(response.status, [400, 410].includes(status) ? 200 : 503);
    if (response.status === 200) assert.equal((await response.json()).active, false);
    else assert.equal(Object.hasOwn(await response.json(), 'active'), false);
  }
});
test('rejects receipt/product/type and malformed cancellation or purchase fields', async () => {
  const variants = [{ receiptId: 'other' }, { productId: 'other' }, { productType: 'CONSUMABLE' }, { purchaseDate: '123' }, { cancelDate: '0' }, { cancelDate: -1 }];
  for (const variant of variants) assert.equal((await handle(request(), environment(), async () => Response.json({ ...receipt, ...variant }))).status, 502);
  const { cancelDate, ...missing } = receipt;
  assert.equal((await handle(request(), environment(), async () => Response.json(missing))).status, 502);
});
test('invalid and oversized bodies cannot reach Amazon', async () => {
  const never = async () => { assert.fail('Unexpected upstream request'); };
  for (const body of [null, [], {}, { ...payload, sku: 'foreign' }, { ...payload, userId: ' ' }, { ...payload, environment: 'SANDBOX' }, { ...payload, endpoint: 'https://attacker.test' }, { ...payload, receiptId: 'x'.repeat(9000) }]) {
    assert.equal((await handle(request(body), environment(), never)).status, 400);
  }
  assert.equal((await handle(request(null, { body: '{broken' }), environment(), never)).status, 400);
});
test('sandbox deployment uses only Amazon sandbox and rejects production inputs', async () => {
  const env = environment({ RVS_ENVIRONMENT: 'SANDBOX' });
  const response = await handle(request({ ...payload, environment: 'SANDBOX' }), env, async url => { assert.ok(url.startsWith('https://appstore-sdk.amazon.com/sandbox/version/')); return good(); });
  assert.equal(response.status, 200); assert.equal((await response.json()).environment, 'SANDBOX');
  assert.equal((await handle(request(), env, good)).status, 400);
});
test('both independent rate limiters are enforced before verification', async () => {
  for (const binding of ['IP_LIMIT', 'USER_LIMIT']) {
    const env = environment({ [binding]: { limit: async ({ key }) => { assert.match(key, /^[0-9a-f]{64}$/); return { success: false }; } } });
    assert.equal((await handle(request(), env, async () => assert.fail('Unexpected upstream'))).status, 429);
  }
});
test('missing secret, mode, limiter or edge metadata fails closed', async () => {
  for (const field of ['AMAZON_SHARED_SECRET', 'RVS_ENVIRONMENT', 'IP_LIMIT', 'USER_LIMIT']) assert.equal((await handle(request(), environment({ [field]: undefined }), good)).status, 503);
  assert.equal((await handle(request(payload, { headers: { 'Content-Type': 'application/json' } }), environment(), good)).status, 503);
});
test('upstream exceptions, non-JSON and oversized responses cannot expose secrets', async () => {
  for (const amazon of [async () => { throw new Error('server/secret'); }, async () => new Response('bad json'), async () => new Response(' '.repeat(33000))]) {
    const response = await handle(request(), environment(), amazon);
    assert.ok(response.status >= 500); const text = await response.text(); assert.ok(!text.includes('server/secret')); assert.ok(!text.includes(payload.receiptId));
  }
});
test('unexpected paths, query strings, methods and media types are rejected', async () => {
  for (const suffix of ['/other', '/v1/amazon/verify?receipt=secret']) assert.equal((await handle(new Request('https://example.test'+suffix), environment(), good)).status, 404);
  assert.equal((await handle(new Request('https://example.test/v1/amazon/verify'), environment(), good)).status, 405);
  assert.equal((await handle(request(payload, { headers: { 'Content-Type': 'text/plain' } }), environment(), good)).status, 415);
});
test('Cloudflare entry point does not treat execution context as an HTTP client', async () => {
  assert.equal((await worker.fetch(request(), {}, { waitUntil() {} })).status, 503);
});
