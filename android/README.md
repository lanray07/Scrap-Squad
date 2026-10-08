# Scrap Squad — Amazon Fire OS port

Separate Kotlin/libGDX application. The original iOS source, Xcode project definition,
artwork and content are unchanged. This is an implementation in progress; it is not
an Amazon-approved release.

## Architecture

The Android app compiles the existing eight `Sources/ScrapCore/*.swift` files to
native Android libraries. A JSON/UTF-8 JNI boundary exposes commands and immutable
render snapshots. Kotlin owns Android screens, lifecycle, local atomic saves and
libGDX rendering. No engine objects cross JNI.

`build_native.py` generates an Android-only copy of `Battle.swift`, replacing its
`@MainActor` class annotation with mutex confinement. Every JNI call is serialized
in C++; game rules, constants and calculations are unchanged. Other core files are
compiled directly from their original paths. The oracle compiles the original
actor-isolated source, with no transformation. The bridge uses Swift 5 language
mode on a Swift 6 toolchain; the original iOS compiler settings are unchanged.

## Build

Requirements: Java 17, Android SDK 36, NDK 28.2.13676358, Swift 6.4.0 or a matching
official Swift Android SDK/toolchain. Gradle wrapper is pinned to 9.4.1.

```powershell
python android/tools/sync_assets.py
python android/tools/build_native.py --oracle
python android/tools/generate_parity.py
python android/tools/build_native.py --abi arm64-v8a
python android/tools/build_native.py --abi x86_64
.\android\gradlew.bat -p android :app:assembleDebug :app:connectedDebugAndroidTest
```

Set `SWIFTC`, `SWIFT_ANDROID_SDK`, `ANDROID_NDK_HOME` when installed outside the
documented Windows defaults. Set `sdk.dir` in ignored `android/local.properties`
or supply `ANDROID_HOME`. The GitHub `Verify Amazon Fire port` workflow provides
an independent Ubuntu/Android-emulator verification environment.

Minimum SDK is Android 9/API 28 (Fire OS 7+), initially ARM64 tablets. x86-64 is
included for emulator verification. Older/32-bit-only tablets are not supported
by this initial ABI selection. No Google Play Services dependency is introduced.

## Verification gate

Do not call the vertical slice verified until Android instrumentation passes
against the original Swift oracle. Fixtures cover all 16 weapons, nine biome
bosses, seven modes, seeded movement/actions, upgrades and duplicate run claims.
Some fixtures deliberately use level-50 robots to reach bosses; production
defaults and balance are unchanged. Floating comparison tolerance is 1e-6 plus
1e-8 relative. This is deterministic input-trace comparison, not bitwise or
rendered-FPS equivalence.

## Remaining release work

The slice and initial native menus have passed Android runtime verification; see
`VERIFICATION.md` for exact commits and evidence. City, squad, workshop, blueprint,
challenge, journal and settings flows call the original Swift rules. Seven shop
packs and premium previews are present. The official Amazon SDK adapter and
original Swift cosmetic reconciliation are implemented; purchasing remains
unavailable until the prepared Cloudflare receipt service is deployed and console
products are configured. The app-specific Amazon public key is included.
See `AMAZON_PURCHASES.md` for the exact remaining integration.

Still required: complete visual parity and device lifecycle verification, connect
and validate the prepared receipt backend and Amazon configuration,
sandbox and physical Fire-device QA, final Android screenshots, approved localized
metadata, release signing and submission verification.

## Interrupted battles

Android records the starting profile/content, original seed, actions and exact
frame inputs in private app storage. Recovery replays those inputs through the
same Swift engine on a worker thread. It never runs the simulation on the UI
thread. The last incomplete append is discarded after an abrupt termination;
active input is synced at least once per second and on backgrounding. A durable
reward settlement is written before replacing the profile, allowing a restart
to finish that transaction without duplicating rewards.

Recovery checks the original rules/content signature. An incompatible future
rules update must provide a migration; it preserves the pending record instead
of silently playing it under changed balance. Replay storage grows with run
duration, and unusually long runs take longer to recover. Validate physical
device lifecycle and storage behavior before release.

Existing Apple purchases do not grant Amazon entitlements. Never include merchant
secrets or signing keys in the APK. Production signing is configured only through
`SCRAP_ANDROID_KEYSTORE`, `SCRAP_ANDROID_STORE_PASSWORD`, `SCRAP_ANDROID_KEY_ALIAS`
and `SCRAP_ANDROID_KEY_PASSWORD` environment variables. Do not distribute an
unsigned or debug build as a production release.
