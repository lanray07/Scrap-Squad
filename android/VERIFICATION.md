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

## Release checks still required

Native menu flows, process recovery, premium rendering, purchase validation and
restoration, Amazon sandbox tests, physical Fire tablet performance and audio,
approved translations, final screenshots, signing and submission remain to be
verified. No Amazon publication or physical-device performance is claimed.
