# Amazon Fire release checklist

Application ID: `com.scrapsquad.fire`. Version: `1.0` / code `1`.
Initial ABI support: ARM64; x86-64 is retained for emulator testing. Minimum Android
API 28, OpenGL ES 2 and touch required. Filter the console device list to compatible
Fire tablets; do not select Fire TV, Vega OS or all historical Fire models.

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

1. The service is deployed on the owner's free Cloudflare account. Configure its
   server-only Amazon merchant shared secret on the production Worker.
   Set the Android public verification URLs and exercise the real adapter.
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
Record the submission ID and status. Submission and approval are distinct; neither
has occurred for this port.

Requirements checked on 8 October 2026:
- [Submission](https://developer.amazon.com/docs/app-submission/submitting-apps-to-amazon-appstore.html)
- [Listing text and assets](https://developer.amazon.com/docs/app-submission/appstore-details.html)

Supported screenshot sizes (PNG/JPEG, either orientation): 800×480, 1024×600,
1280×720, 1280×800, 1920×1080, 1920×1200, 2560×1600. Short description maximum
2000 UTF-8 bytes; long description 4000 characters; 3–5 product feature bullets.
