# Scrap Squad Amazon receipt service

Deployed to Cloudflare Workers Free on 9 October 2026. The owner's production
merchant secret is stored securely; a live synthetic invalid receipt was rejected.
Real purchase/restore/refund verification remains required. iOS is
unaffected. See [deployment status](DEPLOYMENT.md) for the actual endpoints and checks.

## Behavior and trust boundary

`POST /v1/amazon/verify`, JSON containing exactly `userId`, `receiptId`, `sku`,
`environment`. These are obtained from the Amazon SDK. The service calls only
Amazon's official Appstore SDK RVS, with its server-only merchant shared secret.
It requires a matching receipt ID, one of the seven original SKUs, product type
ENTITLED, a valid purchase date and a valid cancellation field. The user/receipt
pair is verified by Amazon's HTTP 200 response. A canceled receipt or Amazon
400/410 returns `active:false`; outages, throttling, configuration problems and
binding mismatches return errors, never a new grant. Repeat calls are idempotent.

The app checks the returned user, receipt, SKU, environment and Boolean before
granting. Production and sandbox are separate Workers with fixed upstream modes;
a client cannot select a different upstream host or downgrade production to
sandbox. Amazon's legitimate publishing/LAT test receipts may be returned by
production RVS; their test flag alone is not evidence of a forged purchase.

This is a public, rate-limited receipt verification endpoint, not an authenticated
player account service. Possession of an unguessable user/receipt pair is the
purchase proof checked by Amazon. There is no embedded client API secret, login,
cross-device profile service or server gameplay authority. Do not reuse it to
authorize private player data. If account services are added, bind verification
to an authenticated account. Treat receipt IDs as private bearer-like data.

Requests/responses are size bounded. Upstream requests time out after 8 seconds
and refuse redirects. Responses are `no-store`; no CORS headers are added.
Independent edge IP (120/minute) and user (40/minute) rate limits are required and
use SHA-256 keys. Cloudflare's limits are per location/eventually consistent, not
a global anti-abuse guarantee. Shared networks can be throttled. Free-plan daily
quotas can exhaust and temporarily disable verification; do not silently upgrade
to a paid plan. Previously verified local cosmetics remain available on outages.

No database, receipt cache, application logs or analytics are implemented.
Worker observability and preview URLs are disabled. Cloudflare still processes
network metadata and hashed rate-limit identifiers, and Amazon processes RVS
identifiers. Final privacy disclosures must cover both providers and the owner's
actual account logging/retention configuration; this code is not a privacy-policy
approval. Never log RVS URLs: Amazon puts the merchant secret in the URL path.

## Prepare and test

Requires Node 22+ (CI uses 24). From this directory:

```powershell
npm ci
npm test
npx wrangler deploy --env production --dry-run
npx wrangler deploy --env sandbox --dry-run
```

Tests use an injected fake Amazon transport and do not make live purchases or
prove that Amazon/App Tester configuration works. Android instrumentation also
tests strict response binding and endpoint validation.

## Deploy after the owner creates a free Cloudflare account

1. Use the free Workers plan. Do not enable paid services or billing upgrades.
2. Authenticate Wrangler to that account (`npx wrangler login`). Review its access
   request before granting it. Alternatively the owner can deploy from their own
   trusted terminal/account; do not put login tokens in this repository.
3. Add the Amazon merchant shared secret with `npx wrangler secret put
   AMAZON_SHARED_SECRET --env production`. Enter it only in the secure CLI prompt or Cloudflare
   secret editor, never chat, a source file, command argument or GitHub Pages.
   This is different from the app's public PEM. For sandbox use a separate
   nonempty test secret with `npx wrangler secret put AMAZON_SHARED_SECRET --env
   sandbox`; never copy the production merchant key into sandbox.
4. Deploy production with `npm run deploy`; sandbox with `npm run deploy:sandbox`.
   The configurations deliberately require rate-limit bindings and the secret;
   missing bindings fail closed. Namespaces `68188478871`–`68188478874` must not
   collide with other Workers in this account. Change them if already in use.
5. Record the actual generated HTTPS URLs; do not guess a workers.dev subdomain.
   Set `SCRAP_AMAZON_VERIFY_URL` to the production URL plus `/v1/amazon/verify`.
   For debug-only App Tester builds, set `SCRAP_AMAZON_SANDBOX_URL` to the sandbox
   URL plus that path. Release builds refuse sandbox verification.
6. Rebuild Android with those public environment variables and the final privacy
   URL. Never add `AMAZON_SHARED_SECRET` to Android/Gradle/GitHub Pages.
7. Test real App Tester and Live App Testing: all seven products, valid/canceled
   receipts, restored purchases, pending approval, account changes, offline
   operation and actual rate limits. Confirm production refuses sandbox inputs.
   Inspect logs/settings to verify that sensitive receipt/RVS data is not retained.
8. Finalize privacy and signing/device QA before production submission. Products
   are still drafts with unfinished prices/icons; creating this server does not
   submit the app or make purchases ready for sale.

Sources checked 8 October 2026:

- [Amazon Appstore SDK RVS protocol and statuses](https://developer.amazon.com/docs/in-app-purchasing/iap-rvs-for-android-apps.html)
- [Amazon sandbox](https://developer.amazon.com/docs/in-app-purchasing/rvs-cloud-sandbox.html)
- [Cloudflare rate-limit bindings](https://developers.cloudflare.com/workers/runtime-apis/bindings/rate-limit/)
- [Cloudflare Workers pricing](https://developers.cloudflare.com/workers/platform/pricing/)
