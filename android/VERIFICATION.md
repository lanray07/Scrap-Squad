# Verification evidence

Original iOS baseline: `6ef4064`. No original `App/`, `Sources/`, package or
Xcode project-definition files have been changed by the Android port.

## Android battle gate — 8 October 2026

GitHub run [37820787181](https://github.com/lanray07/Scrap-Squad/actions/runs/37820787181),
commit `3ce65c3`, Android 11/API 30 x86-64 emulator:

- Original Swift package: 49 tests passed.
- Original-source oracle: 31 deterministic scenarios generated.
- Android instrumentation: 3 tests, 0 failures, 0 errors, 0 skipped.
- Live libGDX battle deployment and injected drag movement passed.
- Original Swift versus Android JNI: 23,808 commands passed across 16 weapons,
  nine biome bosses and seven modes, including upgrades, Dash, ability,
  Overdrive, retreat and duplicate reward claims.
- Simulation comparison took 24,077 ms. This is **not a rendered FPS benchmark**.
- Malformed JSON was rejected.
- ARM64 and x86-64 libraries and both APKs compiled on Ubuntu.

The workflow's final screenshot-copy step failed after the tests passed because
Gradle removed the application files during cleanup. Screenshot retention is
fixed in `ed5439c`; its results must be checked separately. The battle gate's
simulation and touch checks passed; complete visual parity is still in progress.

Downloaded XML and log evidence is kept under ignored
`android/reports/run-37820787181/` and in the GitHub run artifact.

## Native menus — 8 October 2026

GitHub run [37824539781](https://github.com/lanray07/Scrap-Squad/actions/runs/37824539781),
commit `ebdb18f`: **successful**, six Android instrumentation tests passed.
This includes the full battle comparison, live movement, native menu navigation
and fusion, fusion/equipment/upgrade persistence across repository reload, and
English fallback for an unsupported device language. Genuine Android battle
screenshot collection succeeded. The renderer now consumes the original Swift
`RobotStride` results for footprint placement and walking poses.

## Interrupted sessions — 8 October 2026

GitHub run [37825746622](https://github.com/lanray07/Scrap-Squad/actions/runs/37825746622),
commit `ba5a32e`: **successful**, seven Android instrumentation tests passed.
The additional recovery test replays movement and Dash from a durable command log,
ignores an incomplete final command, and verifies a simulated interruption between
reward settlement and profile persistence. Repeated initialization does not grant
the reward twice. This simulates recovery boundaries; physical process-kill and
storage-failure testing remain required.

The software-rendered API 30 emulator reported 19 frames over 1.65 seconds after
warmup: average 11.49 FPS, p50 frame interval 82.92 ms, p95 119.35 ms,
average CPU render time 15.48 ms, Java heap 12.99 MB and native heap 36.07 MB.
This short functional-test sample is not representative of physical Fire tablet
performance and does not establish the 60 FPS target. Raw measurements are in the
run artifact's `reports/render-metrics.log`.

## Release checks still required

GitHub run [37828177419](https://github.com/lanray07/Scrap-Squad/actions/runs/37828177419),
commit `15221bb`: **successful**, eight Android instrumentation tests passed.
Original cosmetic collection grants, overlap restrictions, invalid selection
removal and revocation reconciliation passed through the Swift JNI bridge without
changing progression. This does not constitute an Amazon purchase or backend test.
GitHub run [37829458644](https://github.com/lanray07/Scrap-Squad/actions/runs/37829458644),
commit `c7bb3c5`: **successful**, nine Android instrumentation tests passed.
Nine native menu/preview/run-card captures and the early battle capture were
retained at 2560×1600. Visual review identified stretched city artwork and a
long result headline overlapping the run-card robot; both have been corrected
and compile locally, with final runtime capture verification still pending.
GitHub run [37830639626](https://github.com/lanray07/Scrap-Squad/actions/runs/37830639626),
commit `6fadff7`: **successful**, nine Android instrumentation tests passed.
All ten named native/battle captures and original icon/promo exports passed their
PNG dimension checks. The boss capture visibly shows Void Engine, its health,
three warning circles, the original squad and movement footprints.

The longer software-emulator sample measured 208 frames over 21.22 seconds:
average 9.80 FPS, frame intervals p50 92.91 ms, p95 167.52 ms, p99 184.08 ms,
worst 249.72 ms; average CPU render time 29.09 ms; Java heap 5.87 MB and native
heap 44.11 MB. This confirms the rendered path runs, but **does not meet the
60 FPS target on this software renderer or establish physical Fire performance**.
Physical GPU profiling is a release requirement; no performance claim is made.

GitHub run [37831791305](https://github.com/lanray07/Scrap-Squad/actions/runs/37831791305),
commit `3db6b8b`: **successful**. Original rules, both native builds, Android
instrumentation and all ten capture/three store-art dimension checks passed with
the app-specific Amazon public key, public support email and tablet layout fixes
included. Amazon purchases are still unavailable without the real backend adapter;
an emulator pass is not an Amazon licensing or purchase-flow test.

## Prepared receipt service — 8 October 2026

`backend/amazon-receipts/` adds a Cloudflare Workers Free deployment package.
Eleven local Node tests pass for valid/canceled receipts, repeated requests,
product/user/receipt binding, malformed and oversized data, server errors,
rate limits, mode separation and secret-safe error responses. Wrangler 4.149.0
production and sandbox dry-run bundles pass. These use fake Amazon responses;
no Cloudflare deployment, real RVS request or purchase test has occurred.

GitHub run [37834093930](https://github.com/lanray07/Scrap-Squad/actions/runs/37834093930),
commit `e38dfbf`: **successful**. Thirteen Android instrumentation tests passed,
including the four response/endpoint tests; backend tests and dry-run bundles,
original Swift rules, both native builds, JNI parity and captures also passed.
Blank verification URLs preserve the disabled purchase state.

On 9 October both Cloudflare Workers were deployed on the Free plan with their
rate-limit bindings. Live rejection/configuration smoke checks passed. Production
still has no merchant secret and returns 503; sandbox has a separate test-only
secret. No real receipt or purchase has been verified. See
[`DEPLOYMENT.md`](../backend/amazon-receipts/DEPLOYMENT.md).

Later on 9 October the owner stored the required production secret. Its presence
was checked without displaying its value. A live synthetic invalid receipt now
returns HTTP 200 with `active:false`, and malformed input returns 400. The
transport preserves the fetch receiver and uses manual redirect handling with
all 3xx responses rejected. Twelve backend tests pass. GitHub public URL variables
are connected to the debug-build workflow; runtime verification for that configured
build passed in run 37906781599 at `209ba24`. No valid purchase, restoration or refund has been tested.

## Fire tester UI feedback — 9 October 2026

### Battle-end and fusion dialogs

GitHub run [37973442354](https://github.com/lanray07/Scrap-Squad/actions/runs/37973442354),
commit `a57d55f`: **successful**. Thirteen instrumentation tests and original Swift,
JNI parity, backend, native-build and capture gates passed. The shared native dialog
uses rounded colored cards, gradient headers and full-width action buttons. Battle
results have large stat tiles; fusion reveals have a weapon/rarity/description card.
The robot portrait and pose button are interactive without changing game state.
The capture test checks pose toggling, action identity, one callback and callback
execution before dismissal. Genuine `ui-battle-result` and `ui-fusion-reveal`
captures are retained alongside a dialog interaction preview. Equip, Share, Return,
reward settlement and all localized strings preserve their existing behavior.
UI Review remains a separate test app with paid transactions disabled.

GitHub run [37965203655](https://github.com/lanray07/Scrap-Squad/actions/runs/37965203655),
commit `7293741`: **successful**. Thirteen Android instrumentation tests passed,
with original Swift tests, 31 oracle scenarios / 23,808 JNI commands, backend checks,
both native architectures and genuine capture/artwork dimension validation.

- Enabled crafting controls use gold gradients; unavailable controls use grey.
  The workshop capture includes both affordable and missing-material recipes.
- Battle stats use separate colored cards and a squad-integrity progress bar.
- The production upgrade picker uses rounded, element-colored cards. Its selection
  callback and dismissal are checked, and a separate preview capture is retained.
- Round/event/upgrade announcements use native Android text; damage numbers use
  a one-time high-resolution font atlas generated from the system bold font.
- The separate `uiReview` APK compiled, installed alongside the original package
  and launched without a fatal or native menu initialization error. It has its own
  save namespace and disables paid transactions. This is not a production release.

The preceding UI gate, [37963547894](https://github.com/lanray07/Scrap-Squad/actions/runs/37963547894)
at `e55cea2`, also passed all 13 instrumentation tests. Its workshop, HUD and upgrade
picker captures were visually inspected for text clarity and layout. Original iOS
files, gameplay rules and premium source artwork remain unchanged.

Physical process recovery, complete premium battle rendering, purchase validation and
restoration, Amazon sandbox tests, physical Fire tablet performance and audio,
approved translations, final screenshots, signing and submission remain to be
verified. No Amazon publication or physical-device performance is claimed.

## Categorized blueprint database

Run [38084566219](https://github.com/lanray07/Scrap-Squad/actions/runs/38084566219)
at `a4e3fb2` passed the original Swift, backend, native parity and all 13 Android
instrumentation tests. The production database is grouped by weapon element, with
discovery counts/progress, searchable names/clues, discovery filters and tappable
recipe cards. Unknown weapons remain hidden. Assertions cover discovery filters,
empty/reset/name search and unchanged player progression. The native database
capture was visually inspected; final `efd082c` adds filter-label padding.

The final UI Review APK was built locally with Gradle and its signature verified.
All 62 native libraries exactly match the verified GitHub APK. It retains the
separate test package, independent save and disabled purchases. This is a test
build; the prior CI-signed UI Review must be removed before installation, deleting
only that test app's save. Keep the original Scrap Squad installed.

## Physical Fire purchase checks — 11 October 2026

Test device: KFTRWI, Fire OS / Android API 28, ARM64. The separate accepted
UI Review installation and its save were preserved. A fresh debug installation
of the production package used the official Amazon App Tester in SANDBOX mode
and the deployed sandbox receipt verifier; no real-money purchase was made.

- Found and added the missing DRM response receiver. The release manifest keeps
  Amazon's documented `com.amazon.drm.Permission.NOTIFY` protection.
- This Fire OS installation denies App Tester's DRM broadcasts because the tester
  does not hold that permission. A debug-only manifest uses the existing Amazon
  signature-protected IAP notification permission instead. It is absent from release.
- The opt-in physical test passed: SANDBOX mode and LICENSED callback in 1.751 s.
- All seven entitlement products loaded from the test catalog.
- Founder Pack purchase completed, and the actual server-verified entitlement
  file contained one Founder receipt. Raw user and receipt identifiers were not
  included in this report.
- Renamed the test entitlement cache, restarted the app, and confirmed the Founder
  receipt was recovered from Amazon and verified by the server.
- Changed to Amazon App Tester's second test account and confirmed zero entitlements.
- Corrected Android shop help and empty-restore wording to refer to Amazon.

Further physical checks passed in the same disposable sandbox profile:

- Returned to test account 1 and recovered its one verified Founder entitlement.
- Canceled the fulfilled Founder transaction in App Tester. The app removed access,
  persisted one revoked receipt and displayed the refund/revocation message.
- Forced a FAILED purchase response. No entitlement was granted; the shop showed
  an unavailable message and remained usable.
- Used App Tester's Request Purchase flow. The tester confirmed approval was
  required; no entitlement was granted. Canceling another purchase dialog also
  left the verified entitlement count at zero.
- Restored the default purchase response, disabled the sandbox system property,
  removed the temporary App Tester battery exemption and restored normal sleep.

## Signed release and Amazon listing preparation

Run [38156810561](https://github.com/lanray07/Scrap-Squad/actions/runs/38156810561)
passed at `2bc4f04`, including original Swift tests, native parity, Android
instrumentation and signed release packaging. The downloaded release APK passed
ZIP integrity and APK signature verification; it is not debuggable. Package:
`com.scrapsquad.fire`, version `1.0` / code `1`, minimum API 28, target API 36,
ARM64 and x86_64. The production verifier, privacy URL and Amazon wording are
embedded; the release DRM receiver retains the documented protected permission.

APK SHA-256: `e9aaaaa2fcc61e082657532cd0856c0579e95487e3ee3994943f88bc11751aaa`.
Signing certificate SHA-256:
`623458bf6dbb121de6a2a6219420cd6115a5e0547d40304652c01dd184fe164e`.

Amazon accepted the uploaded APK with DRM applied. Eight compatible Fire tablet
models are selected, including the tested KFTRWI; no Fire TV or automotive device
is selected. All six store descriptions and the English-default ten tablet
screenshots are complete. The 13+ targeting, rating questionnaire and privacy
disclosures are saved, including user IDs and purchase history for functionality
and fraud prevention. Support email: banksmi@mail.com. Core gameplay is free;
seven optional one-time cosmetic products have saved GBP pricing and original art.

All three Amazon tax interviews now show Completed; Canada remains included.
All seven test-only cosmetic products show Approved, but are not yet Live or
promoted to the public catalog. One consenting adult tester was added to the
Fire release test group. The signed Live App Test draft includes that group and
was submitted after the owner's export-certification approval on 11 October 2026.
Amazon's dashboard confirms Test submitted, not yet Live. The same tester group
was also saved for DevTest. Channel: `amzn1.channel.e6a5370f37f24cf5b0cebc40f89d5716`.
Production installation and Founder purchase checks through Amazon subsequently
passed as recorded below. The public app was submitted on 12 October 2026.

### Amazon-delivered LAT installation — 12 October 2026

The first apparent installation retained the previous local debug APK (identical
SHA-256 to the local debug build). Its private test data and APK were backed up
under the ignored device report directory before removing that debug package.
The separate `com.scrapsquad.fire.uireview` app and its player progress were kept.
After a fresh Amazon download, `com.scrapsquad.fire` version 1.0/code 1 is installed
by `com.amazon.venezia`, is not debuggable, and has Amazon's Lanray certificate
SHA-256 `8e35b165d5a1dc14c10820cee25ed2c24e9c543ceb2f059b9f5bc93baa672297`.
App Tester sandbox mode is `none`.

Amazon account/restore callbacks return the expected empty-purchase state.
Founder’s Pack displays the catalog price £2.99 and an enabled purchase button.
Its Amazon checkout opens successfully. The owner approved the free LAT checkout
and acceptance of Amazon's displayed terms; Amazon then requested phone/password
confirmation directly on the Kindle. The owner completed account confirmation.
The app displayed `Purchase verified.` and Founder’s Pack displayed `Owned`,
with Equip and Try in the arena available. A full process force-stop and relaunch
retained ownership. An explicit Restore purchases request completed with
`Purchase verified.` and ownership retained. Scrap, credits and cores remained
350 / 500 / 3: this cosmetic purchase granted no gameplay currency.
This verifies the Amazon-delivered release's Founder LAT purchase, production
receipt-verifier integration, restart persistence and restore path. Other products
were not individually purchased in LAT; sandbox and automated edge-case coverage
are separate evidence. No actual charge was observed or reported.

Six Live test products were promoted to the public catalog on 12 October;
Amazon now lists them without TEST and with Approved status. Star Medic PATCH
remains test-only Approved and cannot yet be promoted because it is not Live.

### Public app submission — 12 October 2026

The owner approved the public export certification. The expired schedule was
cleared at the owner's request so publishing starts after approval. Reviewer
instructions include the completed LAT Founder purchase/restart/restore checks.
Amazon confirms `SUBMITTED` and `App Submission Successful` at 03:47 GMT-7 on
12 October 2026. Release: `amzn1.devportal.apprelease.f82811624c8b4964b45fdeb8464fdc4a`.
Amazon estimates 17 October 2026 at 04:00 PDT (12:00 Europe/London); this is an
estimate, not approval or a guaranteed publication time. Star Medic promotion
remains pending Amazon's Live test status. iOS was not modified.

### Amazon rejection investigation — 15 October 2026

Amazon did not publish version 1.0/code 1. Primary and functionality validation
passed, but the review video shows grey Buy pack buttons without prices. The
catalog/connection prerequisite disabled those controls and prevented tap feedback.
The precise reason the review account lacked store data is not available in the
report; it must not be inferred from the successful Founder LAT test alone.

A dedicated `.iapqa` installation preserves the Amazon release and UI Review saves.
`ShopInteractionTest` reproduced the inactive controls on KFTRWI in 3.832 seconds
(`am instrument -w -e class com.scrapsquad.fire.ShopInteractionTest
com.scrapsquad.fire.iapqa.test/androidx.test.runner.AndroidJUnitRunner`). With the
fix, the same test passes in 4.506 seconds and asserts that a tap opens an actual
explanation/retry dialog. Missing prices now show Check Amazon availability, with
inline explanations and a retry dialog. Available packs keep Buy pack. Store
initialization has a 15-second timeout; empty/failed product responses are surfaced.
DRM, receipt verification, account isolation and cosmetic grant rules are retained.
Shop navigation also retries the store connection, and failed checkout requests
show visible feedback. The final local code 2 QA build passed the same physical
test in 4.058 seconds. It packages the updated English strings.

On 15 October, the six previously promoted IAPs showed public Live status. Star
Medic PATCH was now Live in test and was successfully promoted: it is public
Approved, awaiting Live propagation. No test-only products remain. Version 1.0/code
2 is being prepared; its signed build, Amazon-delivered checkout verification and
resubmission remain pending. The original submission is Pending Action.

Signed code 2 CI run [38769263531](https://github.com/lanray07/Scrap-Squad/actions/runs/38769263531)
at `b63d434` succeeded: 15 Android instrumentation tests passed, including
the shop interaction regression, with one sandbox connection test skipped in CI
(16 total, zero failures/errors), and both Android architectures compiled. The
downloaded release is version 1.0/code 2, non-debuggable, signed with the original
release certificate (`623458bf6dbb121de6a2a6219420cd6115a5e0547d40304652c01dd184fe164e`).
APK SHA-256: `65db09766789b11e2e7d5f64093c41d871d6d05eebd97f5ef13e145c8ed91ffe`.
This confirms build and regression checks, not Amazon-delivered code 2 checkout.

Amazon accepted that APK with DRM in an upcoming Test 1 draft named
`Scrap Squad 1.0 build 2 - responsive Amazon shop`, beta release
`amzn1.devportal.apprelease.2344982a568541da900e4eda54210545`. The original eight
Fire tablet selections and existing consenting tester group are retained.
Submit Test/export certification awaits owner approval; no code 2 test or public
resubmission has been submitted yet.
