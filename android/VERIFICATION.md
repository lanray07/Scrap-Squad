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
