# Scrap Squad custom product pages

Prepared 8 October 2026. Three campaigns: **Weapon Fusion**, **Boss Survival**, and **Daily Circuit**. Each has promotional text, keyword themes, three iPhone screenshots, three iPad screenshots and a matching website/social banner in eleven locales: en-GB, es-ES, fr-FR, de-DE, it, pt-PT, pt-BR, ja, ko, zh-Hans and zh-Hant.

## Assets

`Marketing/CustomProductPages/` contains 198 opaque RGB screenshots (1320×2868 iPhone; 2064×2752 iPad), 33 banners (2400×1000), a universal text-free App Store header (5244×2950), and an English campaign overview. The manifest records each export SHA256, original gameplay capture SHA256, and source path. These are genuine app captures, not invented gameplay. Captures predate build 15 and are explicitly marked as such. Translated headline artwork includes a notice that the game interface is English.

The website uses the English Weapon Fusion banner, including social preview metadata. Other banners can be used in their matching language campaigns. No paid translation service or recurring API cost is introduced.

## Draft management

Run the GitHub workflow **Prepare localized custom product page drafts** to save promotional text and screenshot galleries using the repository's existing Apple secrets. The workflow verifies all image checksums, order and completed delivery state. It reuses matching assets and preserves unexpected assets for inspection. It never submits a page or app for review, accepts agreements or changes app pricing.

The new App Store header is uploaded through App Store Connect's header slot. A text-free focal character allows it to serve all storefront languages. All three drafts now have promotional text in eleven locales and all 198 screenshots saved. `status.json` records the successful 8 October 2026 verification of all 66 galleries. The main version and each campaign have an English primary header; other locales inherit the same text-free artwork.

## Release limits

These are drafts while the app's 4.3 / 4.2.6 rejection remains unresolved. Creating marketing material does not resolve that rejection. Do not promote a custom-page URL as live until Apple approves the page and the app is available.

Keyword themes are editorial candidates, not validated search-volume results. Apple only allows selecting CPP keywords from the latest approved app version, so no keyword assignment is claimed before the app's first approval. Before assigning a term, make sure it is available in that locale's approved version; each selected term can point to only one custom page. Existing default-version keywords are not overwritten by this workflow.

Translations are editorial drafts and have not been reviewed by native speakers. They localize the storefront artwork and copy, not the app interface. Native review is recommended before publishing. No claim of guaranteed conversion, ranking or virality is made.

## Regeneration

Use Node.js with `sharp` installed: `node Tools/custom_product_pages.cjs`. Copy and keyword themes are in this directory. Rendered files are committed so uploads use the exact reviewed Windows font output instead of differing Linux fonts. GitHub only uploads these checked exports.

## Apple references

- https://developer.apple.com/help/app-store-connect/create-custom-product-pages/configure-multiple-product-page-versions
- https://developer.apple.com/app-store/asset-best-practices/
- https://developer.apple.com/documentation/appstoreconnectapi/post-v1-appcustomproductpages

Image transfers and Apple image processing are checked separately. Apple occasionally takes longer than three minutes to process an accepted image. The uploader records reservation/checksum receipts, completes the batch, then polls delivery for up to thirty minutes. A receipt permits recognizing a pending image created by this uploader; it does not count as proof of completed delivery. Final success requires Apple to return matching checksums and COMPLETE states for every image.
