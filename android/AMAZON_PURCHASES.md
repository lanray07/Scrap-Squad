# Amazon purchasing integration

The port uses the official `com.amazon.device:amazon-appstore-sdk:3.0.9`.
`AmazonPurchases` is a process-wide listener with native catalog pricing,
ENTITLED-only product checks, paged restore, pending approval, account isolation,
receipt binding, cancellation handling and write-before-fulfillment persistence.
The seven original product IDs are preserved as the intended Amazon SKUs.
They must be created as non-consumable entitlements in the developer console.
Apple purchases do not transfer.

## Required deployment configuration

1. The app-specific public `AppstoreAuthenticationKey.pem` was downloaded from
   the Scrap Squad Amazon draft on 8 October 2026 and added to
   `android/app/src/main/assets/`. This is a public authentication key, not the
   merchant shared secret. The SDK does not start when it is absent. Recheck the
   key if moving the app to another Amazon record or developer account.
2. Connect the user's **existing backend**, whose URL, technology and source
   repository have been requested but not supplied. Implement
   `AmazonReceiptVerifier` with that backend's real authenticated protocol, then
   configure the process singleton. There is deliberately no permissive default
   verifier, invented endpoint or embedded merchant credential.
3. The backend must call Amazon Receipt Verification Service using a server-only
   merchant secret, bind app/user/receipt/product, allow only these seven SKUs,
   reject pending/invalid receipts, return cancellation state, and process repeated
   requests idempotently. Keep sandbox/production environments separate and apply
   authentication/rate limiting appropriate to the existing service.
4. Build with the actual app public key, registered SKUs and release signing key.

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
