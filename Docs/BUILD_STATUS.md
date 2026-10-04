# Verification snapshot — 4 October 2026

**Updated:** Signed version 1.0 build 15 adds the Signature Collection: three robot skins, Prism Arsenal, live previews and an ownership-aware bundle, retaining the combat excitement, wave and walking fixes. It is processed, selected and available in internal TestFlight. Apple SDK compilation, 49 core tests, 19 tooling tests and all 21 iPhone UI tests passed in the full native run. Three purchase/preview cases each passed on iPhone and iPad Pro 13 in the device-family matrix. See [current evidence](PREMIUM_SHOP.md) and [device acceptance](TESTFLIGHT_QA.md). All 416 English keys resolve; 4,160 free machine drafts in ten languages await human review. Version 1.0 build 15 and all seven purchases were submitted on 4 October 2026 and are WAITING_FOR_REVIEW; no public release has occurred. The table below is historical Windows evidence.

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


Current submission: [version 1.0 build 15 and seven purchases](PremiumShop/submission-status.json), submission `1e6bb3b3-8d9f-4f05-9d24-67aa95a3cc3e`, **Waiting for Review**. [Apple confirmation](Store/app-review-build15-submitted.png). Automatic release after approval remains selected. Physical-device/live Apple sandbox and human translation quality limitations above remain unverified.
