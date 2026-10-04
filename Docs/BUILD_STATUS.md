# Verification snapshot — 4 October 2026

**Updated:** Signed version 1.0 build 12 fixes the three wave defects and includes walking/footprints. It is processed, selected and available in internal TestFlight. Apple SDK compilation, 39 core tests, 18 tooling tests and all 14 iPhone simulator UI tests passed in the full native run. See [wave fix evidence](WAVE_FIX.md), [historical movement evidence](MOVEMENT_UPDATE.md) and [device acceptance](TESTFLIGHT_QA.md). All 375 English keys resolve; ten draft languages await human review. No App Review submission or public release occurred. The table below is historical Windows evidence.

| Check | Result |
| --- | --- |
| Swift 6.3.1 gameplay package build on Windows | Passed |
| Swift Testing core tests | 14 passed, 0 failed |
| Python localization tests | 8 passed, 0 failed |
| Localization content references | All 308 English keys resolve |
| Approved non-English locales | None; ten locales require translation/review |
| App source syntax parse | Passed; not Apple SDK type checking |
| Store draft field limits | Passed |
| Generated screenshot briefs | Six, using twelve actual recipes |
| Sprite atlas PNG | 1774×887, RGBA; inspected and integrated |
| Icon source PNG | 1254×1254, RGB; Mac build resizes to 1024×1024 |
| iOS simulator/device build | Not available on this host |
| UI/device/performance verification | Pending on Mac |
| StoreKit/Game Center sandbox verification | Pending service configuration and Mac/device testing |
| Release readiness | Not ready; see RELEASE.md |

Historical test invocation: `swift test --scratch-path C:\Users\User\ScrapSquadBuild`. SwiftPM prints an optional convenience-symlink warning on Windows; the compiled tests still execute and pass. App source was initially checked using `swiftc -frontend -parse`; the subsequent GitHub workflows compiled it against the Apple SDK and uploaded the signed release.
