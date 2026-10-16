# Scrap Squad for Amazon Fire — privacy policy draft

**Do not publish this draft until the backend's operator, hosting,
retention and deletion practices are confirmed.** The original Apple-only policy
does not describe Amazon receipt validation. Set `SCRAP_ANDROID_PRIVACY_URL` to
the finalized public HTTPS policy when building the release; the Android privacy
link is disabled while it is unset.

Scrap Squad stores game progress, inventory, preferences, run history and cosmetic
selections locally on the device. Core gameplay has no developer advertising or
analytics SDK and does not request contacts, location, microphone or camera access.
Run cards and seeded challenge codes are shared only when the player chooses a
destination in Android's share sheet. Challenge codes contain no player identity.

Amazon handles payment. The app receives an app-specific Amazon user identifier,
product identifiers and receipt identifiers to verify and restore cosmetic
ownership and remove refunded entitlements. The intended receipt backend receives
the user, receipt and product identifiers and queries Amazon Receipt Verification Service.
Merchant credentials remain on the server. Payment-card details are not requested
by this game. No progress or inventory upload is implemented.

Before finalizing this policy, document:

- The backend operator, host and countries of processing. A Cloudflare Workers
  service is prepared but not deployed: no database or application logs, hashed
  edge rate-limit keys, and provider network processing must be disclosed.
- Exactly which request/security logs are retained and their retention periods.
- Receipt/entitlement retention and deletion procedures, including refund/legal
  obligations and support contact for deletion requests.
- The existing backend's authentication requirements and any additional identifiers
  sent by its real protocol.
- Amazon SDK data practices and the developer console's required disclosures,
  including appropriate purchase-history and identifier categories.
- Whether any child-directed distribution or Amazon Kids configuration applies.

Uninstalling removes the app's local data. Amazon retains purchase records under
its policies. The backend's deletion terms must be specified separately; do not
state that uninstalling deletes server-side receipt records.

Contact support privately at **banksmi@mail.com** for purchase or privacy requests.
The public GitHub issues page is also available for non-private bug reports.
Players must not post receipts or private account identifiers in public issues.

Reference: [Amazon Privacy Notice](https://www.amazon.com/privacy).
