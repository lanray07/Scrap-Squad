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

The Android HTTP adapter and four new response/endpoint instrumentation tests
compile locally. Their runtime pass is pending in the next Android workflow.
Blank verification URLs preserve the disabled purchase state.

Physical process recovery, complete premium battle rendering, purchase validation and
restoration, Amazon sandbox tests, physical Fire tablet performance and audio,
approved translations, final screenshots, signing and submission remain to be
verified. No Amazon publication or physical-device performance is claimed.
