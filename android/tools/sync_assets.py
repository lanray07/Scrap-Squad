"""Copy authorized originals and export approved string-catalog entries."""
from pathlib import Path
import hashlib
import json
import shutil
import xml.etree.ElementTree as ET

ANDROID = Path(__file__).resolve().parents[1]
ROOT = ANDROID.parent
DEST = ANDROID / 'app/src/main/assets/generated'
DEST.mkdir(parents=True, exist_ok=True)
for source, name in [(ROOT/'Sources/ScrapCore/Resources/content.json', 'content.json'), (ROOT/'App/Resources/RobotAtlas.png', 'RobotAtlas.png'), (ROOT/'App/Resources/StoreConfiguration.json', 'StoreConfiguration.json')]:
    shutil.copy2(source, DEST/name)
shutil.copytree(ROOT/'App/Resources/Audio', DEST/'Audio', dirs_exist_ok=True)
drawable = ANDROID/'app/src/main/res/drawable'
drawable.mkdir(parents=True, exist_ok=True)
shutil.copy2(ROOT/'Art/AppIcon-source.png', drawable/'app_icon.png')
catalog = json.loads((ROOT/'App/Resources/Localizable.xcstrings').read_text(encoding='utf-8'))
translations = {}
for key, value in catalog['strings'].items():
    for language, localized in value.get('localizations', {}).items():
        unit = localized.get('stringUnit', {})
        if unit.get('state') == 'translated' and isinstance(unit.get('value'), str):
            translations.setdefault(language, {})[key] = unit['value']
assert translations.get('en'), 'English source catalog missing'
android_strings = json.loads((ANDROID/'resources/strings.en.json').read_text(encoding='utf-8'))
assert not (android_strings.keys() & translations['en'].keys()), 'Android keys must not override original translations'
translations['en'].update(android_strings)
(DEST/'localization.json').write_text(json.dumps(translations, ensure_ascii=False, indent=2), encoding='utf-8')
for language, strings in translations.items():
    qualifier = 'values' if language == 'en' else 'values-b+' + language.replace('-', '+')
    folder = ANDROID/'app/src/main/res'/qualifier
    folder.mkdir(parents=True, exist_ok=True)
    resources = ET.Element('resources')
    for key, value in sorted(strings.items()):
        node = ET.SubElement(resources, 'string', {'name': 'sq_' + hashlib.sha256(key.encode()).hexdigest()[:16], 'formatted': 'false'})
        node.text = '"' + value.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'
    ET.indent(resources)
    ET.ElementTree(resources).write(folder/'game_strings.xml', encoding='utf-8', xml_declaration=True)
manifest = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in [ROOT/'Sources/ScrapCore/Resources/content.json', ROOT/'App/Resources/RobotAtlas.png', *sorted((ROOT/'App/Resources/Audio').glob('*.wav'))]}
for source in sorted((ROOT/'Sources/ScrapCore').glob('*.swift')):
    manifest[source.relative_to(ROOT).as_posix()] = hashlib.sha256(source.read_text(encoding='utf-8').replace('\r\n', '\n').encode('utf-8')).hexdigest()
(DEST/'source-hashes.json').write_text(json.dumps(manifest, indent=2))
print(f'Copied original content, robot atlas, {len(list((DEST/"Audio").glob("*.wav")))} audio files; locales: {sorted(translations)}')
