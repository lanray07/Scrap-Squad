# Verification snapshot — 4 October 2026

**Updated:** Signed version 1.0, build 8 with distinct weapon attacks and nine boss patterns is uploaded, processed and attached in App Store Connect. [Final native validation](https://github.com/lanray07/Scrap-Squad/actions/runs/37172499986) passed Apple SDK compilation, 29 core tests, 13 tooling tests and eight iPhone UI tests, including boss combat, purchases/restore/refunds, Overdrive, sharing, retry and saved mastery. Two replay/rotation cases each also passed on iPhone SE and iPad Pro. See [combat verification and 31 genuine captures](COMBAT_UPDATE.md) and [Apple status](Combat/app-store-status.json). All 375 English source keys resolve. Ten languages have 3,750 integrity-checked drafts; language quality remains unapproved. The app and products have not been submitted for review or released. The rows below retain the earlier Windows-host verification context.

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
