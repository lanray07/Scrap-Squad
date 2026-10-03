# Store campaign

Eleven editorial storefront drafts are saved here: English (UK), Spanish, French, German, Italian, Portuguese (Portugal), Portuguese (Brazil), Japanese, Korean, Simplified Chinese and Traditional Chinese. Each `*-draft.json` contains App Store name, subtitle, keywords, promotional text and description, plus separate web SEO fields. Each `*-description.txt` is ready to copy for review. Length checks run with `python Tools/store_campaign.py`.

The English screenshot story is ordered as combat → workshop → robot squad → weapon reveal → blueprints → city → loadout → roulette → onboarding → pause. The first three prioritize the game's main loop. Keyword-led copy uses actual implemented features and counts. Search demand and conversion have not been measured.

## Reproduce the ten exports

The native GitHub workflow builds the app, runs `testStoreScreenshotTour`, exports XCTest attachments and renders the store pack. It uploads raw captures and final exports as `store-screenshots-<run number>`.

```sh
python Tools/collect_store_captures.py <xcresult-attachment-directory> Docs/Store/Captures
python Tools/store_campaign.py
npm install --prefix .build/screenshot-tools --no-save sharp
NODE_PATH="$PWD/.build/screenshot-tools/node_modules" node Tools/render_store_screenshots.cjs Docs/Store/Captures
```

On Windows, set `NODE_PATH` to the installed sharp module directory, then run the same Node script. PNG exports are 1320 × 2868 RGB with no alpha, accepted in Apple's 6.9-inch iPhone screenshot slot. SVG files retain editable copy and vector framing. The manifest includes raw/export SHA-256 hashes and the source capture for each frame.

Storefront copy and screenshots are drafts for review and reflect the current development build. No App Store Connect upload is performed. English screenshots do not prove localized UI; the automatic localization workflow produces separately reviewed String Catalog drafts. See [the localization workflow](../AUTO_LOCALIZATION.md).
