# Store draft and capture plan

`Tools/store_metadata.py` creates `Docs/Store/en-GB-draft.json`. It validates name/subtitle/keyword/promotional-text/description lengths and calculates blueprint counts from the content pack. This is a copy draft; it should not be uploaded until its behavior claims pass device QA.

Apple’s product-page guidance specifies 30-character subtitles and a 100-character keyword field. App names have a 30-character limit. Screenshots must accurately show the app experience. Primary sources checked 3 October 2026:

- [App information reference](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
- [Creating your product page](https://developer.apple.com/app-store/product-page/)
- [App Review Guidelines, accurate metadata](https://developer.apple.com/app-store/review/guidelines/)
- [Asset best practices](https://developer.apple.com/app-store/asset-best-practices/)

The title and subtitle fit these limits. Keyword candidates describe the implemented genre; demand, competitiveness, trademark availability and conversion are not established. Localized metadata remains a separate market-research task, not a blind keyword translation.

The six screenshot briefs tell the battle → fusion → discovery → squad → boss → city story. They deliberately use **12** blueprints and the actual squad capacity. Capture on device/simulator after the UI is built and verified. No generated screenshots or fictitious gameplay capture are included. Resolve screenshot dimensions against current App Store Connect device slots at capture time.
