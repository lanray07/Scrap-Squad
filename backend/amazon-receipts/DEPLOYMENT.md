# Cloudflare deployment — 9 October 2026

Both Workers are deployed under the owner's lanraybanks account on the Free plan.
No billing upgrade or paid service was enabled. Both have separate required IP
and user rate-limit bindings, fixed Amazon modes, disabled preview URLs and
disabled Worker observability/application logs.

| Mode | Receipt endpoint | Status |
| --- | --- | --- |
| Production | https://scrap-squad-receipts.lanraybanks.workers.dev/v1/amazon/verify | Secret stored under required name; live synthetic invalid receipt rejected; real purchases unverified |
| Sandbox | https://scrap-squad-receipts-sandbox.lanraybanks.workers.dev/v1/amazon/verify | Deployed with separate generated test-only secret; real App Tester validation pending |

Production initial version: `b82d0a27-2428-47b9-b9aa-8b39e5a37311`.
Sandbox initial version: `125bfafa-d0bf-47c3-a8cc-dcceba92fdc6`; adding its
test-only secret created a subsequent deployment. No production key was used.

Live HTTPS smoke checks passed: production JSON POST returns 503
`not_configured`, sandbox malformed input and production-mode input return 400,
production GET returns 405, and an unknown route returns 404. These checks do not
prove a valid Amazon receipt, purchase, refund or restoration flow.

The owner added `AMAZON_SHARED_SECRET` securely through Wrangler. Presence was
verified without displaying its value. The live malformed-input check now
returns 400. A synthetic, nonexistent user/receipt request reaches Amazon and
returns HTTP 200 with `active:false`; no purchase or entitlement was granted.
This does not prove a valid receipt or all credential/account combinations.
One incorrectly named extra secret entry remains from the initial attempt;
it is unused by this service. Its name and value must not be copied into reports.

The deployed transport uses `redirect:manual` and rejects all 3xx responses;
it never follows redirects or exposes the upstream Location/URL. The default
fetch wrapper preserves the runtime's receiver. Fixed error codes distinguish
merchant configuration, invalid Amazon users and transport failures, without
returning secrets or upstream response bodies. Twelve backend tests pass.
Production current version: `3dd05ed3-0cfe-430c-962e-f40b3d850b27`.

The public URLs are configured as GitHub repository variables consumed by the
debug verification workflow: `SCRAP_AMAZON_VERIFY_URL` and
`SCRAP_AMAZON_SANDBOX_URL`. No merchant key is in GitHub or the APK.
Release builds still refuse sandbox verification. Final privacy disclosure,
all seven product purchase/restore/refund tests, physical Fire QA, prices,
signing and submission remain required.
