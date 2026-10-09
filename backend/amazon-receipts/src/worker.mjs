// No database, receipt cache or application logging. Amazon remains authoritative.
export const SKUS = new Set(['founder', 'styles', 'ronin', 'bastion', 'medic', 'prism', 'collection'].map(id => `com.ScrapSquad.app.${id}`));
const MAX_BODY = 8192;
function reply(status, value) {
  return Response.json(value, { status, headers: { 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff', 'X-Scrap-Receipt-Version': '2' } });
}
async function boundedText(stream, max) {
  if (!stream) throw new Error('missing body');
  const reader = stream.getReader(); let size = 0; const chunks = [];
  try {
    while (true) {
      const { value, done } = await reader.read(); if (done) break;
      size += value.length;
      if (size > max) { await reader.cancel(); throw new Error('body too large'); }
      chunks.push(value);
    }
  } finally { reader.releaseLock(); }
  const bytes = new Uint8Array(size); let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
  return new TextDecoder('utf-8', { fatal: true }).decode(bytes);
}
async function digest(value) {
  const bytes = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(value));
  return Array.from(new Uint8Array(bytes), byte => byte.toString(16).padStart(2, '0')).join('');
}
function identifier(value) { return typeof value === 'string' && value.length > 0 && value.length <= 2048 && !/[\s\u0000-\u001f\u007f]/u.test(value); }

export async function handle(request, env, fetchAmazon = (url, options) => globalThis.fetch(url, options)) {
  const url = new URL(request.url);
  if (url.pathname !== '/v1/amazon/verify' || url.search) return reply(404, { error: 'not_found' });
  if (request.method !== 'POST') return reply(405, { error: 'method_not_allowed' });
  if (request.headers.get('content-type')?.split(';')[0].trim().toLowerCase() !== 'application/json') return reply(415, { error: 'json_required' });
  if (!['PRODUCTION', 'SANDBOX'].includes(env.RVS_ENVIRONMENT) || !env.IP_LIMIT || !env.USER_LIMIT || !env.AMAZON_SHARED_SECRET) return reply(503, { error: 'not_configured' });
  let stage = 'ip_limit';
  try {
    // Edge-supplied IP limits pre-parse abuse; hash keys, never log raw identifiers.
    const ip = request.headers.get('CF-Connecting-IP');
    if (!ip) return reply(503, { error: 'edge_required' });
    if (!(await env.IP_LIMIT.limit({ key: await digest(ip) })).success) return reply(429, { error: 'retry_later' });
    let input;
    try { input = JSON.parse(await boundedText(request.body, MAX_BODY)); } catch { return reply(400, { error: 'invalid_request' }); }
    if (!input || Array.isArray(input) || Object.keys(input).sort().join(',') !== 'environment,receiptId,sku,userId' ||
        !identifier(input.userId) || !identifier(input.receiptId) || !SKUS.has(input.sku) || input.environment !== env.RVS_ENVIRONMENT) return reply(400, { error: 'invalid_request' });
    stage = 'user_limit';
    if (!(await env.USER_LIMIT.limit({ key: await digest(input.userId) })).success) return reply(429, { error: 'retry_later' });
    stage = 'amazon_request';
    const prefix = env.RVS_ENVIRONMENT === 'SANDBOX' ? '/sandbox' : '';
    const upstream = `https://appstore-sdk.amazon.com${prefix}/version/1.0/verifyReceiptId/developer/${encodeURIComponent(env.AMAZON_SHARED_SECRET)}/user/${encodeURIComponent(input.userId)}/receiptId/${encodeURIComponent(input.receiptId)}`;
    // Never follow redirects: the merchant secret is part of Amazon's required URL.
    let response;
    try {
      response = await fetchAmazon(upstream, { redirect: 'manual', signal: AbortSignal.timeout(8000), headers: { Accept: 'application/json' } });
    } catch { return reply(503, { error: 'amazon_connection_error' }); }
    const result = { userId: input.userId, receiptId: input.receiptId, sku: input.sku, environment: env.RVS_ENVIRONMENT, active: false };
    // These are authoritative invalid/canceled receipts; other failures are transient.
    if (response.status === 400 || response.status === 410) return reply(200, result);
    // Distinguish setup errors using fixed codes, without exposing credentials or upstream data.
    if (response.status === 496) return reply(503, { error: 'merchant_configuration_error' });
    if (response.status === 497) return reply(503, { error: 'invalid_amazon_user' });
    if (response.status !== 200) return reply(503, { error: 'verification_unavailable', upstreamStatus: response.status });
    let receipt;
    try { receipt = JSON.parse(await boundedText(response.body, 32768)); } catch { return reply(502, { error: 'invalid_upstream' }); }
    if (!receipt || receipt.receiptId !== input.receiptId || receipt.productId !== input.sku || receipt.productType !== 'ENTITLED' ||
        !Number.isSafeInteger(receipt.purchaseDate) || receipt.purchaseDate <= 0 || !Object.hasOwn(receipt, 'cancelDate') ||
        (receipt.cancelDate !== null && (!Number.isSafeInteger(receipt.cancelDate) || receipt.cancelDate < 0))) return reply(502, { error: 'invalid_upstream' });
    result.active = receipt.cancelDate === null;
    return reply(200, result);
  } catch {
    // Do not return/log upstream URLs, receipt data, merchant secrets or exceptions.
    return reply(503, { error: 'verification_unavailable', stage });
  }
}
export default { fetch: (request, env) => handle(request, env) };
