# Cloudflare deployment — 9 October 2026

Both Workers are deployed under the owner's lanraybanks account on the Free plan.
No billing upgrade or paid service was enabled. Both have separate required IP
and user rate-limit bindings, fixed Amazon modes, disabled preview URLs and
disabled Worker observability/application logs.

| Mode | Receipt endpoint | Status |
| --- | --- | --- |
| Production | https://scrap-squad-receipts.lanraybanks.workers.dev/v1/amazon/verify | Deployed; missing merchant secret; fails closed |
| Sandbox | https://scrap-squad-receipts-sandbox.lanraybanks.workers.dev/v1/amazon/verify | Deployed with separate generated test-only secret; real App Tester validation pending |

Production initial version: `b82d0a27-2428-47b9-b9aa-8b39e5a37311`.
Sandbox initial version: `125bfafa-d0bf-47c3-a8cc-dcceba92fdc6`; adding its
test-only secret created a subsequent deployment. No production key was used.

Live HTTPS smoke checks passed: production JSON POST returns 503
`not_configured`, sandbox malformed input and production-mode input return 400,
production GET returns 405, and an unknown route returns 404. These checks do not
prove a valid Amazon receipt, purchase, refund or restoration flow.

The owner must add `AMAZON_SHARED_SECRET` as a **Secret** on the production
Worker in Cloudflare Settings → Variables and Secrets. Enter it only in the
secure editor; never chat, source files, Android configuration or logs.
Then verify real Amazon receipts before enabling production purchasing.

The Android endpoint configuration remains blank until that step is complete.
The public URLs above can subsequently be supplied as `SCRAP_AMAZON_VERIFY_URL`
and debug-only `SCRAP_AMAZON_SANDBOX_URL` at build time. Final privacy disclosure,
all seven product purchase/restore/refund tests, physical Fire QA, prices,
signing and submission remain required.
