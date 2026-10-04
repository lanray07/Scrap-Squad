# Verification snapshot — 4 October 2026

**Updated:** Signed version 1.0 build 14 adds three evolutions, Dash/perfect dodges and three wave events, retaining the wave fix and walking/footprints. It is processed, selected and available in internal TestFlight. Apple SDK compilation, 47 core tests and 18 tooling tests passed. The full native run passed 17/18 iPhone UI cases; its sole failure was the event-wait timeout. The corrected targeted rerun passed the remaining case, giving eighteen unique passing iPhone UI cases across the two runs. All four new combat cases passed on iPad Pro 13 and on iPhone across the matrix and targeted rerun. See [combat excitement evidence](COMBAT_EXCITEMENT.md) and [device acceptance](TESTFLIGHT_QA.md). All 394 English keys resolve; 3,940 free machine drafts in ten languages await human review. No App Review submission or public release occurred. The table below is historical Windows evidence.

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
