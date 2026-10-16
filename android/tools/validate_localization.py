"""Fail CI on missing source/catalog keys or unapproved exported translations."""
from pathlib import Path
import json
import re

android = Path(__file__).resolve().parents[1]
root = android.parent
source = json.loads((root / 'App/Resources/Localizable.xcstrings').read_text(encoding='utf-8'))['strings']
exported = json.loads((android / 'app/src/main/assets/generated/localization.json').read_text(encoding='utf-8'))
extra = json.loads((android / 'resources/strings.en.json').read_text(encoding='utf-8'))
english = exported['en']
required = set()

def visit(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if key.endswith('Key') and isinstance(child, str):
                required.add(child)
            visit(child)
    elif isinstance(value, list):
        for child in value:
            visit(child)

for name in ('content.json', 'StoreConfiguration.json'):
    visit(json.loads((android / 'app/src/main/assets/generated' / name).read_text(encoding='utf-8')))
prefixes = {key.split('.')[0] for key in english}
for path in (android / 'app/src/main/java').rglob('*.kt'):
    # Dynamic keys are checked through content and the runtime instrumentation.
    for literal in re.findall(r'"([^"\n$]+)"', path.read_text(encoding='utf-8')):
        if '.' in literal and literal.split('.')[0] in prefixes and re.fullmatch(r'[A-Za-z][A-Za-z0-9.]+', literal):
            required.add(literal)
missing = required - english.keys()
assert not missing, f'Missing English UI/content keys: {sorted(missing)}'
for locale, values in exported.items():
    for key, value in values.items():
        assert isinstance(value, str) and value.strip(), f'Empty translation: {locale}/{key}'
        if locale == 'en' and key in extra:
            assert value == extra[key]
            continue
        approved = source.get(key, {}).get('localizations', {}).get(locale, {}).get('stringUnit', {})
        assert approved.get('state') == 'translated' and approved.get('value') == value, f'Unapproved translation: {locale}/{key}'
print(f'Validated {len(required)} static/content keys; {len(english)} English strings; approved locales: {sorted(exported)}')
