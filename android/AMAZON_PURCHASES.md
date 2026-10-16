# Amazon purchasing integration

The port uses the official `com.amazon.device:amazon-appstore-sdk:3.0.9`.
`AmazonPurchases` is a process-wide listener with native catalog pricing,
ENTITLED-only product checks, paged restore, pending approval, account isolation,
receipt binding, cancellation handling and write-before-fulfillment persistence.
The seven original product IDs are preserved as the intended Amazon SKUs.
All seven were registered as non-consumable entitlement drafts in the developer
console on 8 October 2026, with their original IDs, names and cosmetic descriptions.
On 11 October 2026 all seven test-only products show Approved, with original
product icons and paid GBP pricing: Founder 2.99, Styles 1.99,
Ronin/Bastion/Medic/Prism 2.99 each, Collection 7.99. Public promotion is pending.
Apple purchases do not transfer.

## Required deployment configuration

1. The app-specific public `AppstoreAuthenticationKey.pem` was downloaded from
   the Scrap Squad Amazon draft on 8 October 2026 and added to
   `android/app/src/main/assets/`. This is a public authentication key, not the
   merchant shared secret. The SDK does not start when it is absent. Recheck the
   key if moving the app to another Amazon record or developer account.
2. The Cloudflare Workers service in `backend/amazon-receipts/` was deployed on
   9 October 2026. Production has its server-only Amazon merchant secret stored;
   see its `DEPLOYMENT.md` for actual URLs and live smoke checks. A free LAT
   Founder purchase was verified through the production Worker on 12 October;
   sandbox receipts were verified through the separate sandbox Worker. The live synthetic invalid
   receipt check rejects ownership. Android's strict `HttpAmazonReceiptVerifier` is configured by public
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

SDK adapter compilation and physical Amazon App Tester checks passed on KFTRWI.
The separate sandbox backend verified a purchase and restore; account switching,
revocation, failure, pending approval and cancellation checks also passed. All
seven test IAPs were Approved in Amazon's console. The signed Live App Test is
in progress. The Amazon-delivered non-debuggable release passed Founder purchase,
server verification, process restart and explicit restore on KFTRWI on 12 October
2026. The other six products have not been individually purchased in LAT.
See `VERIFICATION.md` for evidence and limitations. Before release test all seven products,
approved/declined/pending purchases, rotation/backgrounding during purchase,
duplicate callbacks, interrupted persistence, paged restoration, account changes,
refunds, offline cached ownership and invalid/mismatched receipt responses.
Verify the backend secret never appears in the APK, CI output or client config.

The signed Live App Test was submitted on 11 October 2026 after owner approval
of export certification. Test 1 subsequently became available and the production
Founder purchase/restore path passed. Six products were promoted to the public
catalog; Star Medic PATCH still awaits Live test status before promotion.
The public app was submitted on 12 October 2026 after owner export-certification
approval. Amazon confirms SUBMITTED; public app approval is still pending.

Amazon subsequently rejected code 1 for unresponsive Buy pack controls. On
15 October, `ShopInteractionTest` reproduced disabled controls when store data was
unavailable, then passed after adding per-pack explanations and an actionable
availability/retry dialog. The exact upstream failure on Amazon's review account
is unknown. Six public products are Live; Star Medic was promoted on 15 October
and is public Approved. Code 2 still needs signed-release and Amazon-delivered
checkout validation before resubmission. See the dated record in VERIFICATION.md.

Official references:
- [SDK integration](https://developer.amazon.com/docs/appstore-sdk/integrate-appstore-sdk.html)
- [Amazon IAP implementation](https://developer.amazon.com/docs/in-app-purchasing/iap-implement-iap.html)
- [Receipt verification environments](https://developer.amazon.com/docs/in-app-purchasing/rvs-cloud-sandbox.html)
