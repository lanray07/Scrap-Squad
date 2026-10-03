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
    for test in manifest:
        if 'testStoreScreenshotTour' not in test.get('testIdentifier',''): continue
        for attachment in test['attachments']:
            name=re.match(r'^(Store-\d{2}-[a-z]+)_',attachment.get('suggestedHumanReadableName',''))
            if name and not attachment.get('isAssociatedWithFailure'):
                captures[name[1]]=attachment
    if len(captures)!=10: raise SystemExit(f'Expected ten actual store captures; found {len(captures)}. No replacements were made.')
    for name,attachment in captures.items():
        shutil.copyfile(source/attachment['exportedFileName'],destination/(name+'.png'))
    (destination/'capture-provenance.json').write_text(json.dumps(captures,indent=2)+'\n',encoding='utf-8')
    print('Collected ten named simulator captures.')
if __name__=='__main__': main()
