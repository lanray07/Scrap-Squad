"""Merge authored replay copy without overwriting existing source or translations."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
path = root / 'App/Resources/Localizable.xcstrings'
catalog = json.loads(path.read_text(encoding='utf-8'))
source = {}
for filename in ["replay_strings.json", "excitement_strings.json"]:
    source.update(json.loads((root / "Tools" / filename).read_text(encoding="utf-8")))
for key, value in source.items():
    entry = catalog['strings'].setdefault(key, {'extractionState': 'manual', 'localizations': {}})
    old = entry['localizations'].get('en', {}).get('stringUnit', {}).get('value')
    if old is not None and old != value:
        for locale, localization in entry['localizations'].items():
            if locale != 'en' and 'stringUnit' in localization:
                localization['stringUnit']['state'] = 'needs_review'
    entry['localizations']['en'] = {'stringUnit': {'state': 'translated', 'value': value}}
path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'Merged {len(source)} replay strings.')
