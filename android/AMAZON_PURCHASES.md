# Amazon purchasing integration

The port uses the official `com.amazon.device:amazon-appstore-sdk:3.0.9`.
`AmazonPurchases` is a process-wide listener with native catalog pricing,
ENTITLED-only product checks, paged restore, pending approval, account isolation,
receipt binding, cancellation handling and write-before-fulfillment persistence.
The seven original product IDs are preserved as the intended Amazon SKUs.
All seven were registered as non-consumable entitlement drafts in the developer
console on 8 October 2026, with their original IDs, names and cosmetic descriptions.
They have not been submitted. Pricing and product icons are unfinished; the list
currently displays USD 0 defaults, which must not be submitted as final pricing.
Apple purchases do not transfer.

## Required deployment configuration

1. The app-specific public `AppstoreAuthenticationKey.pem` was downloaded from
   the Scrap Squad Amazon draft on 8 October 2026 and added to
   `android/app/src/main/assets/`. This is a public authentication key, not the
   merchant shared secret. The SDK does not start when it is absent. Recheck the
   key if moving the app to another Amazon record or developer account.
2. The user confirmed no hosting account and requested preparation first. A small
   Cloudflare Workers service is now in `backend/amazon-receipts/`; it is not
   deployed. Follow its README to provision the server-only secret and real HTTPS
   endpoints. Android's strict `HttpAmazonReceiptVerifier` is configured by public
   `SCRAP_AMAZON_VERIFY_URL` and debug-only `SCRAP_AMAZON_SANDBOX_URL` build
   environment variables. Blank or invalid configuration leaves purchases disabled.
3. The backend must call Amazon Receipt Verification Service using a server-only
   merchant secret, bind app/user/receipt/product, allow only these seven SKUs,
   reject pending/invalid receipts, return cancellation state, and process repeated
   requests idempotently. Keep sandbox/production environments separate and apply
   rate limiting. This service has no player login: the private user/receipt pair
   is verified with Amazon. It does not authenticate a person or authorize player
   data; see the backend README for this trust boundary and abuse limitations.
4. Finalize the seven draft product prices/icons, test their configuration, and
   build with the actual app public key, registered SKUs and release signing key.

Without a configured verifier, the UI cannot initiate purchases or grant
entitlements. Product metadata alone does not authorize a grant. Network failure
retains previously verified offline ownership for the same identified Amazon
account. Trusted cancellation callbacks remove access immediately. Backend
validation rechecks cached receipts on refresh for later refunds.

The local verified-receipt cache is an app-private AtomicFile; it is not a backend
authority and does not protect against a rooted device modifying its private
storage. Cosmetic selections are separately scoped to a hash of the Amazon user
ID. The original Swift `CosmeticCatalog` and `CosmeticSelection` reconcile grants,
bundle overlap and revoked selections; cosmetics never enter gameplay balance.

## Verification still required

SDK adapter compilation has passed. Amazon App Tester/Live App Testing and the
actual backend have **not** been exercised. Before release test all seven products,
approved/declined/pending purchases, rotation/backgrounding during purchase,
duplicate callbacks, interrupted persistence, paged restoration, account changes,
refunds, offline cached ownership and invalid/mismatched receipt responses.
Verify the backend secret never appears in the APK, CI output or client config.

Official references:
- [SDK integration](https://developer.amazon.com/docs/appstore-sdk/integrate-appstore-sdk.html)
- [Amazon IAP implementation](https://developer.amazon.com/docs/in-app-purchasing/iap-implement-iap.html)
- [Receipt verification environments](https://developer.amazon.com/docs/in-app-purchasing/rvs-cloud-sandbox.html)
