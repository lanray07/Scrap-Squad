# Verification snapshot — 4 October 2026

**Updated:** Signed version 1.0 build 10 is uploaded, processed and attached in App Store Connect. [Native validation](https://github.com/lanray07/Scrap-Squad/actions/runs/37175000200) passed Apple SDK compilation, 30 core, 16 tooling and eleven iPhone UI cases. Independent release tests passed background pause/resume, enlarged text and automated accessibility audit on iPhone and iPad. Compact iPhone SE/iPad rotation checks passed. See [current release evidence](RELEASE_COMPLETION.md) for supplemental commerce tests and the full iPad result. All 375 English source keys resolve; ten languages have 3,750 integrity-checked drafts awaiting human language review. The app and products have not been submitted for review or released. The rows below are historical Windows-host evidence.

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
