# App Store Connect metadata status

Updated and verified in App Store Connect on 3 October 2026 for app 6818847887, iOS version 1.0 (Prepare for Submission).

## Saved storefront copy

Descriptions, promotional text, keywords and subtitles were saved for all eleven locales: English (U.K.), Spanish (Spain), French, German, Italian, Portuguese (Portugal), Portuguese (Brazil), Japanese, Korean, Chinese (Simplified) and Chinese (Traditional). The app name remains **Scrap Squad: Merge & Survive** in every locale. The localized name suggestions in the draft JSON files were not applied.

English subtitle: **Robot battles & weapon fusion**.

The descriptions and promotional text use the corresponding `*-draft.json` files in this directory. They describe the implemented robot roster, weapon fusion, battles, facilities and modes without promises about future production features. Keyword research volumes and ranking gains have not been measured.

Support URL: https://github.com/lanray07/Scrap-Squad/issues

Marketing URL (all eleven locales): https://lanray07.github.io/Scrap-Squad/

Copyright: **2026 Scrap Squad**.

The category is **Games**, with **Action** and **Roleplaying** subcategories. Review notes include the onboarding, workshop fusion and battle walkthrough, local saving, and the Expedition Dock's eight-hour offline salvage cap. Existing review contact details were preserved.

Save controls showed that the changes had been saved. The English version form was reopened and its stored values verified. `app-store-connect-saved.jpg` shows the stored English copy and URLs.

## Distribution preparation completed

- Privacy policy published at https://lanray07.github.io/Scrap-Squad/privacy.html and saved as the privacy-policy URL for all eleven locales. The Data Not Collected response was published after the user explicitly confirmed Apple's publication agreement. Source review found local-only saves and no advertising/analytics SDK. The policy now explains optional Apple StoreKit purchases with on-device signed transaction verification; no transaction data is sent to a developer backend. Game Center remains disabled, including automatic authentication and score reporting. The app includes Settings and Shop links to the policy.
- Age questionnaire saved: frequent cartoon/fantasy violence and frequent weapons; no realistic violence, mature/sexual/medical content, ads, chat, user-content distribution, paid loot boxes or real-money gambling. Free randomized fusion is crafting with earned ingredients, without a wagering or paid-container feature. Apple calculated 13+ in 172 regions, 16+ in Vietnam and 12+ in Korea; earlier OS versions show 12+ with regional exceptions. No override was selected.
- Content rights saved as no third-party content. The game's character art, UI, content and gameplay are original; no external content feed is integrated.
- Starting price saved as $0.00, with equivalent free prices in other currencies. Availability saved for 173 current regions, excluding mainland China and Vietnam until the relevant game licensing information is supplied. Automatic expansion to future regions is disabled.
- Ten English iPhone screenshots uploaded to the 6.9-inch slot, in campaign order 01–10. Apple reuses this set for the 6.5-inch slot and other localizations.
- Repository and App Store Connect bundle ID aligned to `com.ScrapSquad.app`. Marketing version is 1.0 and the workflow assigns its run number as the build number. All four orientations required for iPad multitasking are declared.
- [Initial release workflow run 3](https://github.com/lanray07/Scrap-Squad/actions/runs/37152648395) uploaded build 3. It has now been superseded on the version record by processed build 5, described below.
- [Native validation on the release source](https://github.com/lanray07/Scrap-Squad/actions/runs/37152647325) passed the Swift core, localization tooling, Apple SDK build, iPhone UI smoke tests and screenshot export pipeline.
- The existing `ITSAppUsesNonExemptEncryption=NO` declaration is included in the uploaded app; no custom cryptography is implemented. No separate encryption-document upload was needed to select this build.

Proof captures are stored in `app-store-connect-build.jpg`, `app-store-connect-privacy.jpg`, `app-store-connect-age-rating.jpg`, `app-store-connect-pricing.jpg` and `app-store-connect-screenshots.jpg`.

## Final asset pass

Ten actual 13-inch iPad captures were produced by [the iPad workflow](https://github.com/lanray07/Scrap-Squad/actions/runs/37152881408), which passed all three UI tests at commit `31dc875`. The app source matches the uploaded release; the later change adapts UI-test tab queries for iPad. Raw captures and attachment provenance are in `iPad-Captures/`. The ten premium frames in `Screenshots/iPad-en-GB/` are opaque RGB PNGs at 2064 × 2752, with editable SVGs and source/export SHA-256 hashes in their manifest.

All ten were uploaded to the required 13-inch iPad slot and sorted in campaign order 01–10. Reloading the version form confirmed the stored order and **10 of 10 Screenshots**. Apple reuses this primary-language set for other iPad sizes and localizations. `app-store-connect-ipad-screenshots.jpg` records the saved gallery. The app UI remains English; storefront translations do not announce additional in-app language support.

The version has not been submitted for review or released. The existing standard Apple license agreement and existing business/review contact information were preserved. Optional subscriptions, server notification URLs, App Clips, iMessage and unrelated marketing campaign forms were not populated with invented products or services. Broader device, performance and gameplay polish checks are recorded in `../RELEASE.md`.

## Cosmetic product update

The following records describe the initial cosmetic build. The current version record uses build 7, described in the replay update below.

On the user's instruction, Founder’s Pack (`com.ScrapSquad.app.founder`, Apple ID `6818880427`) and Robot Style Pack (`com.ScrapSquad.app.styles`, Apple ID `6818884131`) were implemented and configured as non-consumables at £2.99 and £1.99 UK base prices. Apple supplies regional prices to the app. Both have eleven localized names/descriptions, review walkthroughs, genuine shop review screenshots and availability in the same 173 regions. Tax category is inherited from the parent app. No recurring subscription was created. The existing Paid Apps agreement was checked and is Active; no agreement or financial details were changed.

[Release run 5](https://github.com/lanray07/Scrap-Squad/actions/runs/37155902457) uploaded the app with cosmetic purchase flows and the app-only UserDefaults reason `CA92.1`. [Native validation](https://github.com/lanray07/Scrap-Squad/actions/runs/37156023763) passed all 16 core, 13 tooling and five UI tests. StoreKit tests covered buying, selecting/removing finishes, ownership and selection persistence, restore and refund removal on iOS 26.2; actual App Store sandbox/device validation remains in the release checklist.

[Apple API completion](https://github.com/lanray07/Scrap-Squad/actions/runs/37156627354) verified product configuration, uploaded both review screenshots and attached processed version 1.0 **build 5**, resource ID `076b9fa6-c6d6-4453-99c6-8b2c9ef34be6`. The initial status report is in `IAP/complete-status.json`. Product records, captures and provenance are recorded in `IAP/README.md`. App Store review and release have not been requested or submitted.

## Replay update: current build 7

[Signed release 7](https://github.com/lanray07/Scrap-Squad/actions/runs/37158256194) uploaded the replay/sharing update for tested source `ddb294db90e44a7b426d14f332134e89f5042d34`. [Final native validation](https://github.com/lanray07/Scrap-Squad/actions/runs/37158254127) passed 22 core, 13 tooling and six iPhone UI tests. [Apple API verification](https://github.com/lanray07/Scrap-Squad/actions/runs/37158993311) confirmed processed build **7** is attached to version 1.0, build resource `b96d37ee-18c5-4532-9860-3091624e86e2`.

The new run history and challenge codes stay on-device. Card sharing is voluntary through Apple's share sheet, explained in the live privacy policy. No new analytics, advertising, account service or data collection was introduced. The app and both purchases remain in preparation, not submitted or released. See [replay details](../PREMIUM_LOOP.md) and [current status report](../Replay/app-store-status.json).
