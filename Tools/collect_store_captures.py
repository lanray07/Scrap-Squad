"""Select named, successful XCTest attachments without substituting screenshots."""
import json
import re
import shutil
import sys
from pathlib import Path

def main():
    source=Path(sys.argv[1]); destination=Path(sys.argv[2]); destination.mkdir(parents=True,exist_ok=True)
    manifest=json.loads((source/'manifest.json').read_text(encoding='utf-8'))
    captures={}
    additional = {
        'Combat-01-boss-encounter': 'Store-11-boss',
        'Premium-02-daily-circuit': 'Store-12-daily',
        'Premium-06-overdrive': 'Store-13-overdrive',
        'Premium-01-mastery': 'Store-14-mastery',
        'Premium-04-share-card': 'Store-15-share',
    }
    for test in manifest:
        identifier=test.get('testIdentifier','')
        if not any(name in identifier for name in ['testStoreScreenshotTour','CombatShowcaseUITests','PremiumReplayUITests']): continue
        for attachment in test['attachments']:
            name=re.match(r'^(Store-\d{2}-[a-z]+)_',attachment.get('suggestedHumanReadableName',''))
            if name and not attachment.get('isAssociatedWithFailure'):
                captures[name[1]]=attachment
            for original,destination_name in additional.items():
                if attachment.get('suggestedHumanReadableName','').startswith(original+'_') and not attachment.get('isAssociatedWithFailure'):
                    captures[destination_name]=attachment
    if len(captures)!=15: raise SystemExit(f'Expected fifteen actual source captures for the ten-frame campaign; found {len(captures)}. No replacements were made.')
    for name,attachment in captures.items():
        shutil.copyfile(source/attachment['exportedFileName'],destination/(name+'.png'))
    (destination/'capture-provenance.json').write_text(json.dumps(captures,indent=2)+'\n',encoding='utf-8')
    print('Collected fifteen named simulator sources for the ten-frame campaign.')
if __name__=='__main__': main()
