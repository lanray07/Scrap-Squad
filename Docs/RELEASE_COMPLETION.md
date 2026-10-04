# Release preparation — 4 October 2026

**Current build: 14.** The [combat excitement update](COMBAT_EXCITEMENT.md) adds three evolutions, Dash/perfect dodges and three wave events, retaining the [wave fix](WAVE_FIX.md) and [walking/footprints](MOVEMENT_UPDATE.md). It is available in the existing TestFlight group. The evidence below records the earlier build 10 preparation.

Version 1.0 **build 10** was uploaded, processed and attached to App Store Connect (build resource `2914e126-c2a0-4756-acb9-2c20a829900c`). [Signed Xcode archive and upload](https://github.com/lanray07/Scrap-Squad/actions/runs/37175398830) and [Apple record attachment](https://github.com/lanray07/Scrap-Squad/actions/runs/37175900722) succeeded. No App Review submission or public release has been performed.

The app includes distinct weapon attacks, nine boss patterns, Overdrive, daily replay codes, mastery, voluntary result-card sharing and optional one-time cosmetics. This release also fixes background simulation pausing and expanding onboarding text. These features have automated coverage; virality, retention and human difficulty have not been measured.

## Recorded verification

- [Native iPhone validation](https://github.com/lanray07/Scrap-Squad/actions/runs/37175000200): Apple SDK compilation, 30 core tests, 16 tooling tests and eleven UI cases passed. App source is `f47c6c0fd0595e00ce7618d86256b84ea20ec206`; signed build 10 has the same App/Core/project/package files.
- [Full iPad validation](https://github.com/lanray07/Scrap-Squad/actions/runs/37175002314/attempts/2): eleven cases passed in 468.509 seconds. The first attempt failed two local StoreKit tests at ownership delivery; these passed in the supplemental run and the fresh full rerun without changing App/Core code. The initial failure is retained as a test-consistency limitation rather than erased.
- [Release checks](https://github.com/lanray07/Scrap-Squad/actions/runs/37175000720): background pause and explicit resume, largest-text Settings/journal reachability, and Apple's automated onboarding/Settings audit passed on both iPhone and iPad. Audit categories cover element descriptions, hit regions, clipped text and contrast. Manual VoiceOver is still pending.
- [Compact device matrix](https://github.com/lanray07/Scrap-Squad/actions/runs/37175189424): two replay/rotation cases each passed on iPhone SE and iPad Pro.
- [Supplemental commerce tests](https://github.com/lanray07/Scrap-Squad/actions/runs/37175351391): four local StoreKitTest cases per device cover purchase/equip/persistence/restore/refund, style selection, pending approval/decline and interrupted delivery. All four passed on each family. Two cases overlap the native suite, giving thirteen unique passing UI cases on each device family.
- The native run also exercised 144 weapon/biome combinations with level-30 robot fixtures, rectangular movement and real upgrade choices. Sampled peaks were 80 enemies, five travelling missiles and eleven warnings. Sampled state stayed finite and bounded; host simulation elapsed time was 23.033 seconds. This does not measure physical rendering, FPS, temperature or battery.

## Store and TestFlight preparation

Both ten-frame campaigns use current unaltered simulator UI in editable marketing frames. iPhone PNGs are opaque RGB at 1320 × 2868; iPad PNGs are 2064 × 2752. Source/export hashes and workflow provenance are saved in the manifests. All twenty frames were visually inspected. Captures show actual boss combat, fusion, eight robots, twelve blueprints, city progression, Daily Circuit, earned Overdrive, mastery and sharing.

[Current gallery and TestFlight preparation](https://github.com/lanray07/Scrap-Squad/actions/runs/37176024736) verifies Apple's processing, exact checksums and order, eleven localized descriptions/keywords/support URLs, eleven names/subtitles/privacy URLs, reviewer notes/contact presence, internal availability and saved testing notes. The saved report excludes reviewer contact data and credentials. All twenty assets are fully processed, with exact manifest checksums and saved order. All eleven version and app-info locales passed field-presence checks; reviewer details are saved. Build 10 is `READY_FOR_BETA_TESTING`, present in Scrap Squad QA, and its testing notes were read back exactly. Reports are saved in [ReleaseQA](ReleaseQA/gallery-upload.json).

The active player-facing app remains English. Free Argos localization tooling and 3,750 draft translations in ten languages pass source-coverage and protected-token checks; human language quality is unapproved and those drafts are not shipped.

## Remaining completion gates

Physical-device access is unavailable in this Windows workspace. No iPhone/iPad is connected, and no physical result is marked passed. The internal **Scrap Squad QA** group has zero testers; no account was added and no invitation was sent. A team administrator must select their own account and install build 10 through TestFlight, following [device and live Apple sandbox acceptance](TESTFLIGHT_QA.md). Touch, sound, VoiceOver, battery/thermal/frame performance, cross-device restore and live Apple service behavior need real-device evidence.

The separate [master-prompt backlog](RELEASE.md) remains future product work, including real 3D assets, expanded recipes, research/rank systems and online community infrastructure. This report does not certify those unimplemented features or promise viral success.
