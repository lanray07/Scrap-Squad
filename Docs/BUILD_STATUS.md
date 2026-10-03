# Verification snapshot — 3 October 2026

**Updated:** Xcode compilation and iPhone simulator smoke tests pass on GitHub. Signed version 1.0, build 3 was uploaded through the separate release workflow and attached in App Store Connect. Current local localization tooling has 13 passing tests. See [store preparation status](Store/APP_STORE_CONNECT.md) and [the simulator run and artifacts](GITHUB_BUILD.md). The rows below retain the earlier Windows-host verification context.

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
