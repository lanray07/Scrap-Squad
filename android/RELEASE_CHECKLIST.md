# Amazon Fire release checklist

Application ID: `com.scrapsquad.fire`. Version: `1.0` / code `1`.
Initial ABI support: ARM64; x86-64 is retained for emulator testing. Minimum Android
API 28, OpenGL ES 2 and touch required. Filter the console device list to compatible
Fire tablets; do not select Fire TV, Vega OS or all historical Fire models.

## Current release status — 11 October 2026

The historical preparation tasks below now have the following updates. See
`VERIFICATION.md` for evidence and limits:

- Signed release CI run `38156810561` at `2bc4f04` passed. The downloaded APK's
  signature, integrity, version, ABIs, non-debuggable flag and configured endpoints
  were verified. Amazon accepted the APK with DRM applied.
- Eight compatible Fire tablet models are selected; no TV/automotive device.
- Six description variants and ten English-default tablet screenshots are complete.
- All seven cosmetic drafts have original product artwork and saved paid GBP prices:
  Founder 2.99, Styles 1.99, Ronin/Bastion/Medic/Prism 2.99 each, Collection 7.99.
- The production privacy policy is deployed; matching user-ID/purchase-history
  disclosures are saved. Target audience is 13+ and rating questions are complete.
- Durable private release signing is backed up outside the repository. GitHub
  release secrets are configured; Apple credentials and iOS files are preserved.
- Physical KFTRWI sandbox purchase, restore, account-change, revocation, failure,
  pending-approval and canceled-dialog checks passed without real-money charges.
- All three Amazon tax interviews show Completed; Canada remains included.
  All seven test-only cosmetic IAPs show Approved. They are not yet Live or
  promoted to the public catalog. A consenting adult tester group is prepared
  for the signed Live App Test. The owner approved export certification and the
  console confirms Test submitted on 11 October 2026. Production purchase
  verification awaits Amazon making the test live; public app submission is pending.
  Broader physical performance/device-matrix checks are not claimed.

## Already available

- Shared original Swift simulation, Kotlin menus and libGDX rendering.
- Debug build and Android instrumentation through `android-fire.yml`.
- Original content, art, audio, localization keys and cosmetic catalog.
- UTF-8 native bridge, deterministic comparison and recovery checks.
- Native screenshot capture and dimension checks; final visual review pending.
- Five localized listing drafts in `store/listings.json`, explicitly disclosing
  the English game interface. Proofread the target locale before upload.
- Amazon SDK purchase adapter; configuration and live validation pending.
- Amazon draft record created on 8 October 2026, Games / Action / Indie,
  English interface, public support `banksmi@mail.com`. App ID:
  `amzn1.devportal.mobileapp.fd2ac6d759cb418ebcb5560a8e7e5bbc`.
- App-specific Amazon public SDK key included. English U.S./U.K., German,
  Spanish, French and Japanese description drafts saved in the console;
  translated listings explicitly disclose the English interface.
- Original 114/512 px icons and the 1024×500 original-art promotional header
  uploaded to the Amazon draft; genuine capture review remains separate.
- All seven original cosmetic IDs registered as entitlement drafts with English
  names/descriptions. Prices/icons and submission are unfinished. The dashboard
  shows USD 0 defaults; do not submit until actual paid prices are configured.

## Required before a production build

1. The service is deployed on the owner's free Cloudflare account, with its
   server-only production secret stored and public URLs configured for CI debug
   builds. Exercise real Amazon purchases, restoration and refunds through the adapter.
   See `backend/amazon-receipts/DEPLOYMENT.md`; never put the merchant secret in this app.
2. Finalize the seven original Amazon ENTITLED drafts, including paid prices and
   icons. Confirm localized
   prices, availability and parental pending-purchase behavior in App Tester and
   Live App Testing. Test restoration, refunds and account changes on real hardware.
3. Verify the included `AppstoreAuthenticationKey.pem` matches this Amazon record;
   no server merchant secret belongs in the APK.
4. Finalize the Android privacy policy using the actual backend practices and set
   `SCRAP_ANDROID_PRIVACY_URL`. Complete matching Amazon data disclosures. Do not
   reuse the Apple-only policy or select “no data collected” for a server that
   receives receipt/account identifiers without evaluating the actual disclosures.
5. Complete the Fire device matrix below and review the final 10 captures. Capture
   the configured store again before publishing; screenshots showing unavailable
   purchases are development evidence, not the final monetization presentation.
6. Export the original icon at 114×114 and 512×512 PNG; optional promo 1024×500,
   title and original art only, with at least 50 px text margins. Keep raw captures
   intact. Amazon accepts 3–10 screenshots at the supported sizes listed below.
7. Supply release signing through `SCRAP_ANDROID_KEYSTORE`,
   `SCRAP_ANDROID_STORE_PASSWORD`, `SCRAP_ANDROID_KEY_ALIAS`,
   `SCRAP_ANDROID_KEY_PASSWORD`. Keep the keystore private and backed up. Never
   substitute the debug key or embed passwords in the repository.
8. Run asset sync, localization/store validation, original Swift tests, both native
   builds and Android instrumentation against the exact release commit. Build with
   `android/gradlew :app:assembleRelease`, then verify the APK's signature using
   Android build-tools `apksigner verify --verbose --print-certs`.

## Physical device QA record

Record device model, Fire OS/API, RAM, ABI, app commit/version and graphics renderer.
Test a low-memory compatible tablet and a capable recent tablet, portrait/landscape,
largest font/display settings, navigation insets, offline startup and accessibility.
Record frame interval p50/p95/p99, memory and sustained battle duration, including
full enemy waves, boss warnings, evolution particles and premium skins. The current
software-emulator sample is not a physical performance result.

Verify audio/music/sound controls, background/resume, actual process termination,
low storage, interrupted reward settlement, long-run replay recovery, fusion,
upgrades, all modes, challenge codes, shared PNG grants and unsupported-language
fallback. Core gameplay must remain available when the network or store is absent.

## Store submission

The Fire tablet draft exists in Amazon Developer Console. Upload the signed APK (or
an AAB if deliberately chosen and validated), confirm package/version/device
filtering, prices/countries, content rating and payment/tax details. Enter accurate
listing text and localized drafts, icons, reviewed screenshots and public support
and privacy links. Submit the app and its IAP items only after the checks above.
Record the submission ID and status. Submission and approval are distinct.
The signed Live App Test was submitted on 11 October 2026. The Amazon-delivered
release passed Founder purchase, server verification, process restart and restore
on KFTRWI on 12 October. Six cosmetic IAPs were promoted to the public catalog;
Star Medic PATCH remains test-only Approved until Amazon makes it Live. The public
app was submitted on 12 October after owner export-certification approval. Amazon
confirms SUBMITTED and App Submission Successful. The owner requested publication
as soon as Amazon approves, replacing the expired schedule. Amazon's estimate is
17 October 2026 at 12:00 Europe/London; approval/publication is not yet confirmed.

Update, 15 October: code 1 was rejected for inert IAP buttons and is Pending Action.
The code 2 correction passes a physical regression test for missing-store-data
tap feedback and signed CI checks (15 instrumentation tests passed, one skipped).
On 16 October the Amazon-delivered code 2 release opened Robot Style Pack checkout;
the app subsequently verified ownership and retained it after process restart
and explicit restore. The public code 2 draft and updated reviewer instructions
were saved. Following owner export-certification approval on 16 October,
Amazon confirmed SUBMITTED and App Submission Successful for the public code 2
release. Publication follows approval. Amazon's new estimate is 21 October 2026
at 12:00 Europe/London, not a confirmed publication date.
Star Medic is now promoted (public Approved); the other
six cosmetics are public Live. The previous publication estimate no longer applies.

Requirements checked on 8 October 2026:
- [Submission](https://developer.amazon.com/docs/app-submission/submitting-apps-to-amazon-appstore.html)
- [Listing text and assets](https://developer.amazon.com/docs/app-submission/appstore-details.html)

Supported screenshot sizes (PNG/JPEG, either orientation): 800×480, 1024×600,
1280×720, 1280×800, 1920×1080, 1920×1200, 2560×1600. Short description maximum
2000 UTF-8 bytes; long description 4000 characters; 3–5 product feature bullets.
