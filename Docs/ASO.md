# Store draft and capture plan

`Tools/store_campaign.py` creates eleven storefront metadata drafts and description text files under `Docs/Store`. It validates name/subtitle/keyword/promotional-text/description lengths and calculates blueprint counts from the content pack. These drafts need native-language review, market keyword validation and device QA before publication.

Apple’s product-page guidance specifies 30-character subtitles and a 100-character keyword field. App names have a 30-character limit. Screenshots must accurately show the app experience. Primary sources checked 3 October 2026:

- [App information reference](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
- [Creating your product page](https://developer.apple.com/app-store/product-page/)
- [App Review Guidelines, accurate metadata](https://developer.apple.com/app-store/review/guidelines/)
- [Asset best practices](https://developer.apple.com/app-store/asset-best-practices/)

The titles and subtitles fit these limits. Keyword candidates describe the implemented genre; demand, competitiveness, trademark availability and conversion are not established. App Store descriptions emphasize player benefits, without keyword stuffing. Each locale also has a separate `webSEO` title, H1 and concise meta description for a future website. No website or store metadata is published by these tools.

The ten-screen story covers battle, workshop, squad, weapon reveal, blueprint discovery, city, loadouts, fusion roulette, onboarding and pausing. It uses **12** blueprints and **8** collectible robots. All gameplay pixels come from the real simulator app; vector marketing copy surrounds the captured UI. The campaign never depicts invented terrain, huge armies or unimplemented features.

`Tools/render_store_screenshots.cjs` creates ten opaque RGB PNG exports at **1320 × 2868**, editable SVG layouts, a contact sheet and a SHA-256 provenance manifest. This size is accepted for Apple's 6.9-inch iPhone slot. Source captures remain separate. [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications), checked 3 October 2026. iPad exports and localized screenshot packs are separate production work.

The screenshot order prioritizes combat, fusion and the robot squad in the first three images, which Apple can show in search results. This is a design hypothesis to test, not a demonstrated conversion improvement.
