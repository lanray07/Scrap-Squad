"""Keep genuine successful native test captures with traceable source hashes."""
import hashlib
import json
import re
import shutil
import struct
import sys
from pathlib import Path

def png_geometry(data):
    """Read display geometry without modifying Apple's original PNG bytes."""
    assert data[:8] == b'\x89PNG\r\n\x1a\n', 'A genuine PNG capture is required.'
    width, height = struct.unpack('>II', data[16:24])
    orientation = 1
    offset = 8
    while offset + 12 <= len(data):
        length = struct.unpack('>I', data[offset:offset + 4])[0]
        if data[offset + 4:offset + 8] == b'eXIf':
            exif = data[offset + 8:offset + 8 + length]
            if exif.startswith(b'Exif\x00\x00'): exif = exif[6:]
            endian = '<' if exif[:2] == b'II' else '>'
            directory = struct.unpack(endian + 'I', exif[4:8])[0]
            count = struct.unpack(endian + 'H', exif[directory:directory + 2])[0]
            for index in range(count):
                entry = directory + 2 + index * 12
                tag, kind, amount = struct.unpack(endian + 'HHI', exif[entry:entry + 8])
                if tag == 274 and kind == 3 and amount == 1:
                    orientation = struct.unpack(endian + 'H', exif[entry + 8:entry + 10])[0]
        offset += length + 12
    if orientation in (5, 6, 7, 8): width, height = height, width
    return width, height, orientation

source, destination = map(Path, sys.argv[1:3])
run, commit = sys.argv[3:5]
required = {
    'Premium-01-mastery', 'Premium-02-daily-circuit', 'Premium-03-results',
    'Premium-04-share-card', 'Premium-05-saved-records', 'Premium-06-overdrive'
}
if '--layouts' in sys.argv[5:]:
    required.update({
        'Layout-01-landscape-mastery', 'Layout-02-landscape-combat',
        'Layout-03-landscape-pause', 'Layout-04-rotated-results'
    })
if '--boss' in sys.argv[5:]:
    required.add('Combat-01-boss-encounter')
manifest = json.loads((source / 'manifest.json').read_text(encoding='utf-8'))
captures = {}
for test in manifest:
    identifier = test.get('testIdentifier', '')
    if 'PremiumReplayUITests' not in identifier and not ('--boss' in sys.argv[5:] and 'CombatShowcaseUITests' in identifier):
        continue
    for attachment in test['attachments']:
        match = re.match(r'^((?:Premium|Layout|Combat)-\d{2}-[a-z-]+)_', attachment.get('suggestedHumanReadableName', ''))
        if match and match[1] in required and not attachment.get('isAssociatedWithFailure'):
            captures[match[1]] = (test['testIdentifier'], attachment)
assert set(captures) == required, f'{len(required)} successful native captures are required; no substitutions made.'
destination.mkdir(parents=True, exist_ok=True)
report = {'workflowRun': run, 'commit': commit, 'runtime': 'iOS 26.2', 'screenshots': []}
for name, (test, attachment) in sorted(captures.items()):
    original = source / attachment['exportedFileName']
    data = original.read_bytes()
    width, height, orientation = png_geometry(data)
    if name.startswith('Layout-') and 'landscape' in name:
        assert width > height, f'{name} is not a complete landscape capture.'
    filename = name + '.png'
    shutil.copyfile(original, destination / filename)
    report['screenshots'].append({
        'file': filename, 'test': test, 'device': attachment['deviceName'],
        'source': attachment['exportedFileName'], 'width': width, 'height': height,
        'exifOrientation': orientation,
        'sha256': hashlib.sha256(data).hexdigest()
    })
(destination / 'capture-provenance.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(f'Saved {len(required)} genuine native captures with hashes and provenance.')
