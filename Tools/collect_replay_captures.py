"""Keep genuine successful native test captures with traceable source hashes."""
import hashlib
import json
import re
import shutil
import sys
from pathlib import Path

source, destination = map(Path, sys.argv[1:3])
run, commit = sys.argv[3:5]
required = {
    'Premium-01-mastery', 'Premium-02-daily-circuit', 'Premium-03-results',
    'Premium-04-share-card', 'Premium-05-saved-records', 'Premium-06-overdrive'
}
manifest = json.loads((source / 'manifest.json').read_text(encoding='utf-8'))
captures = {}
for test in manifest:
    if 'PremiumReplayUITests' not in test.get('testIdentifier', ''):
        continue
    for attachment in test['attachments']:
        match = re.match(r'^(Premium-\d{2}-[a-z-]+)_', attachment.get('suggestedHumanReadableName', ''))
        if match and not attachment.get('isAssociatedWithFailure'):
            captures[match[1]] = (test['testIdentifier'], attachment)
assert set(captures) == required, 'Six successful native captures are required; no substitutions made.'
destination.mkdir(parents=True, exist_ok=True)
report = {'workflowRun': run, 'commit': commit, 'runtime': 'iOS 26.2', 'screenshots': []}
for name, (test, attachment) in sorted(captures.items()):
    original = source / attachment['exportedFileName']
    filename = name + '.png'
    shutil.copyfile(original, destination / filename)
    report['screenshots'].append({
        'file': filename, 'test': test, 'device': attachment['deviceName'],
        'source': attachment['exportedFileName'], 'sha256': hashlib.sha256(original.read_bytes()).hexdigest()
    })
(destination / 'capture-provenance.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print('Saved six genuine native captures with hashes and provenance.')
