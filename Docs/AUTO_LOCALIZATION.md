# Automatic localization drafts

The app uses a String Catalog with 308 English source strings and supports ten target languages: Spanish, French, German, Italian, European Portuguese, Brazilian Portuguese, Japanese, Korean, Simplified Chinese and Traditional Chinese. Locale matching now preserves script and regional tags, and missing translated keys fall back to English text.

`Generate localization drafts` runs automatically when the English String Catalog or its authoring source changes on main, and can also be dispatched manually. Its default **Argos** provider runs open-source translation models on the Linux runner with no translation API key, subscription or per-character fee. Only checked-in app source is translated; player content is never submitted. Results are uploaded as artifacts, with `approved: false`. The workflow cannot modify the production catalog.

The Argos path needs no translation credential and never reuses Apple signing secrets. GitHub runner billing depends on repository visibility and the account's included minutes; this is not a guarantee of free compute. Model downloads and translations are cached for later runs.

## Providers

**Argos** is the lowest-cost default. `Tools/offline_localize.py` installs direct English models for all ten targets, including Brazilian Portuguese (`pb`) and Traditional Chinese (`zt`). No Chinese script conversion or regional substitution is performed. Protected names and placeholders are excluded from model input, then restored exactly. European Portuguese terminology is flagged for review. Machine output can still be awkward or wrong and remains a draft. [Argos Translate's official repository](https://github.com/argosopentech/argos-translate).

```powershell
python -m pip install -r Tools/requirements-translation.txt
$env:TRANSLATION_LOCALE = 'all'
python Tools/offline_localize.py
```

Optional API adapters translate in batches of 25, retry temporary HTTP failures and cache successful responses. They require repository secret `TRANSLATION_API_KEY` and repository variable `TRANSLATION_ENDPOINT` for an authorized service.

The **custom** adapter supports all ten app locales. It sends HTTPS JSON:

```json
{"sourceLanguage":"en","targetLanguage":"fr","instruction":"Translate game UI. Preserve __KEEP_N__ tokens exactly. Return JSON translations array with key and text.","strings":[{"key":"nav.city","text":"City"}]}
```

The service must respond with `{"translations":[{"key":"nav.city","text":"Ville"}]}` and accept a bearer token. The pipeline rejects duplicate, missing or unexpected keys. Reserved placeholders and original robot/product names are restored and validated.

The **libretranslate** adapter implements `/translate` using a text array, `source`, `target`, `format` and `api_key`. Run one locale at a time. Provider language availability depends on its installation. Brazilian Portuguese and Chinese script variants require an explicit provider target and regional review; the workflow never silently substitutes Portuguese or converts Chinese scripts. [LibreTranslate API documentation](https://docs.libretranslate.com/api/operations/translate/).

```powershell
python Tools/localize.py export fr .build/fr-source.json
python Tools/localize.py translate .build/fr-source.json --endpoint https://your-service.example/translate --provider libretranslate --cache .build/fr-cache.json --out .build/fr-draft.json
```

Keep credentials in the environment or GitHub secret store. Review translation quality, terminology, expansion, CJK line breaks and the actual UI before marking individual strings approved. Layout/unchanged warnings require explicit `allowWarnings: true`; missing placeholders, empty text or changed protected names cannot be waived. Stale source hashes block import. Import is atomic after complete validation:

```powershell
python Tools/localize.py import-approved .build/fr-reviewed.json
python Tools/localize.py audit
python -m unittest discover -s Tools -p test_localize.py
```

The reviewed catalog compiles into localized resources in the next Xcode build. Only bundled languages appear in the settings picker. Machine translation does not happen on a player's device and no translation service key is embedded in the app.

## Storefront copy

`python Tools/store_campaign.py` generates separate editorial description, title, subtitle, keyword and web SEO drafts for eleven storefront locales. These drafts are not imported into the app catalog and do not prove that the app UI is localized. They require native-language review and market keyword validation. Screenshot exports currently use English copy and English UI.
