# Response draft — guidelines 4.3 and 4.2.6

Prepared 6 October 2026 for submission `1e6bb3b3-8d9f-4f05-9d24-67aa95a3cc3e`, version 1.0, build 15.

**Sent to Apple App Review on 6 October 2026 in three numbered messages.** Owner answered “mine” to ownership and “no” to the combined question about other apps, shared code/artwork and additional testers. This draft interprets those answers as no other apps, no shared components and no additional human testers. This interpretation was stated back to the owner. This document describes submitted build 15, not proposed future functionality. No new binary has been submitted in response to the notice.

---

Hello App Review,

Thank you for identifying your concerns. Scrap Squad is my game. I would like to provide the following explanation of the submitted version 1.0, build 15, and clarify its implementation and development history.

**1. What does the app do, and what primary problem does it solve?**

Scrap Squad is a native, single-player robot action and crafting game for iPhone and iPad. Players move their squad through an arena while its weapons fire automatically. They avoid visible boss warnings, choose temporary upgrades, collect salvage and then use that salvage outside the run to craft equipment and develop their squad and city. The lasting progression and individual combat runs use separate state: temporary run upgrades do not become permanent purchases or permanent power.

The workshop has twelve defined recipes. For example, Basic Blaster and Fire Core combine into Flame Blaster, which the player can equip for a later run. During combat, complementary upgrade choices can produce Fire Vortex, Storm Cage or Siege Barrage. Robot affinities, equipment, squad development and dodge timing affect the player's choices. Endless Survival/Arena and the three-boss Boss Rush have distinct completion rules.

The entertainment need is a playable cycle of experimentation and action: the player can turn resources earned in a run into a different loadout and directly test the result. The core game runs locally without a developer account, advertisements or a developer-operated server. Optional purchases are fixed, one-time appearance changes; they do not sell combat power, robot unlocks or paid random rewards.

**2. Who is the intended user?**

The intended audience is players who enjoy mobile survivor-style combat, equipment experimentation and persistent collection/progression, particularly those who prefer a single-player experience without advertising interruptions or compulsory online social participation. Automatic weapon firing lets the player concentrate on movement and upgrade choices. The workshop gives players who enjoy crafting a reason to return with a different combination rather than relying only on repeated identical runs.

The game supports iPhone and iPad, portrait and landscape layouts. Its fictional robot combat includes weapons and fantasy violence; it is not represented as a children's educational app. The submitted player-facing interface is English. Translated store metadata does not imply that unreviewed in-app translations are shipped.

**3. What need or gap does it address?**

The intended distinction is the connected relationship between permanent recipe-based equipment crafting, robot squad development and temporary combat evolution in a locally playable game. These are not separate menu demonstrations: a workshop result becomes equipped combat equipment, and the next run offers temporary choices that can change the attack pattern again. Fire Vortex creates rotating attack areas, Storm Cage creates a ring attack, and Siege Barrage uses artillery effects. Drone, missile, beam and lightning weapons have different attack behavior.

Daily Circuit also supplies a repeatable challenge code with a generated loadout. A player can share the code and a locally generated result card voluntarily, without an account or a live leaderboard. Cosmetic ownership does not enter that challenge loadout. This is intended to support replay comparison without building the core experience around network accounts or paid power.

I do not claim these individual genre mechanics have never appeared in another game, or that no competing game combines them. I have not completed a comprehensive market comparison. The basis for requesting reconsideration is the submitted game's own connected implementation, authored robot identities and recipe content, distinct attack behaviors, and local replay system. I understand that originality of source alone does not establish a meaningfully different user experience.

**4. What beta testing was conducted, and what feedback changed the production build?**

Before submission I tested the game on an iPad and reported that the robots appeared static as gameplay progressed. This feedback resulted in distance-driven robot walking and alternating ground footprints. The steps stop when movement stops or combat pauses. Reduced Motion retains ground trails without bobbing or leaning. Those changes were included before submitted build 15.

I also requested a review of wave progression. The resulting engineering checks found that Survival/Arena stopped advancing beyond wave six and that Boss Rush could finish on a timer before three bosses were defeated. These rules were corrected before submission. This second example is an engineering review and regression fix, not a claim of feedback from an additional human tester.

Build 15 was made available in an internal TestFlight group with one recorded tester. Group membership alone is not evidence of installation or a completed playtest. I did not conduct a broader human beta programme or receive feedback from additional testers before submission. The physical-user feedback described above came from my own iPad testing. I understand that this limits the user-validation evidence available for the initial submission.

Separately, automated pre-submission verification passed 49 gameplay-core tests, 19 tooling tests and 21 iPhone simulator UI tests. Three additional premium preview/purchase cases each passed on iPhone and iPad Pro 13 simulators. Local StoreKit tests exercised ownership, restore, pending transactions and revocation. These are automated engineering results, not human beta feedback or proof of live Apple sandbox purchases. Broader physical-device performance and cross-device live purchase restoration were not recorded as completed.

**5. Is this a standalone product or part of a suite?**

Functionally, Scrap Squad is a self-contained game. It has its own local progression and does not need another installed app or a companion account to run.

It is a standalone product, not part of a suite of related apps. I have no other apps under this developer account.

**6. Could its functionality be consolidated into another app on the account?**

Scrap Squad contains an integrated combat/crafting/progression loop rather than an isolated cosmetic pack or a catalog of content. Its seven appearance purchases are already consolidated into this game's binary, rather than being submitted as separate apps.

There is no other app on my developer account into which this functionality could be consolidated. The full game is provided in one app, with optional cosmetics within that same product.

**7. Does the binary share significant code, frameworks or assets with another app on the account?**

This project's native app links a local Swift package called ScrapCore. ScrapCore implements its gameplay state, combat, recipes, progression, challenge codes and cosmetic entitlement model. It is code bundled from this game's repository, not a purchased external game engine. The application uses Apple frameworks including SwiftUI, SpriteKit, UIKit, Foundation, AVFoundation and StoreKit; GameKit integration code exists, but Game Center is disabled for release 1.0. StoreKitTest is used by the test target.

No significant code or assets are shared with another app under my developer account; I have no other apps on that account.

**8. Does it share a codebase, SDK or content library with a third-party app?**

The inspected Package.swift and XcodeGen project declare the local ScrapCore package and Apple system frameworks; they do not declare an external game template, third-party gameplay SDK or commercial content library. Its custom Swift/SpriteKit implementation, content definitions, vector cosmetic rendering and procedural music synthesis are in the repository at https://github.com/lanray07/Scrap-Squad.

Development used AI-assisted coding. The base robot atlas and app icon were generated for this project using AI image generation; their generation prompts are recorded in Docs/ART.md. The signature skins are drawn by this project's vector renderer. Music and sound cues are synthesized by Tools/compose_audio.py rather than downloaded sample packs. I am not representing the project as entirely hand-coded or all artwork as hand-drawn. The repository records no imported third-party game template or competitor imagery. This describes the inspected project's dependencies and provenance; it is not a claim to have audited every third-party app's source code.

**9. Was it created for a client, partner or other third-party content provider?**

No. Scrap Squad is my own game and branding, submitted directly under my developer account. It was not created for a separate client or submitted by me as a template-service provider on another content provider's behalf. AI development tools assisted with implementation and project-specific artwork; they are not a separate client whose game I am publishing.

To inspect the connected gameplay in the submitted binary: complete onboarding, open City > Open Workshop, fuse Basic Blaster + Fire Core, equip Flame Blaster, then open Battle and deploy the squad. Move to dodge warnings and use the run's upgrade choices. Daily Circuit shows the repeatable-code experience. Shop > Signature collection > Try in the arena previews the cosmetic content without granting ownership or saving gameplay rewards.

Please let me know which specific content, functionality or template similarity remains a concern after considering these details so that I can address it directly. I have not submitted an unchanged new binary in response to this notice.

---

## Evidence for finalizing this response

- Ownership: owner's “mine” answer on 6 October 2026; subsequent “no” to other apps/shared components/additional testers, interpreted explicitly in chat.
- Physical feedback: owner's iPad report of static robots in this chat. Implementation: Docs/MOVEMENT_UPDATE.md and Sources/ScrapCore/RobotStride.swift. Do not claim the owner retested the fix without confirmation.
- Wave engineering findings: Docs/WAVE_FIX.md and Tests/ScrapCoreTests/WaveTests.swift.
- Submitted-source verification: Docs/PremiumShop/verification.json, native-results.log and purchase-results.log; source 2a0916aebce19b5693f6f37eb0d7f186c4921603.
- TestFlight: Docs/PremiumShop/testflight-status.json. One tester recorded; installation/feedback is not established by the report.
- Dependencies: Package.swift, project.yml and imports in App/ and Sources/ScrapCore/.
- Art/audio provenance: Docs/ART.md, App/Views/SignatureRobotArt.swift, Tools/compose_audio.py.
- Apple rules: https://developer.apple.com/app-store/review/guidelines/#spam and https://developer.apple.com/app-store/review/guidelines/#minimum-functionality.

The portal was read on 6 October: submission Unresolved Issues, app version Rejected under 4.3.0, all seven purchases Ready for Review. Messages (4) contains Apple's rejection and three posted owner replies. No binary was resubmitted. Attachment upload failed/stalled; the complete response was sent in three messages instead. The PDF remains a local copy, not a delivered attachment.
