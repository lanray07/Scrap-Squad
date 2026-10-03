"""Review-gated String Catalog pipeline. App source only; no player content input."""
import argparse
import hashlib
import json
import os
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'App/Resources/Localizable.xcstrings'
LOCALES = ['es','fr','de','it','pt','pt-BR','ja','ko','zh-Hans','zh-Hant']
PLACEHOLDER = re.compile(r'%([0-9]+\$)?[-+0-9.]*[a-zA-Z@]|\{[^{}]+\}|__KEEP_\d+__')
PROTECTED = ['Scrap Squad', 'Scrap City', 'BOLT', 'TANK', 'ZIP', 'PATCH', 'NOVA', 'BOOMER', 'GLITCH', 'MAGNET']

def read(path):
    return json.loads(Path(path).read_text(encoding='utf-8'))
def write(path, value):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def source(entry):
    return entry['localizations']['en']['stringUnit']['value']
def digest(value):
    return hashlib.sha256(value.encode()).hexdigest()
def issues(original, translated):
    result=[]
    if sorted(m.group(0) for m in PLACEHOLDER.finditer(original)) != sorted(m.group(0) for m in PLACEHOLDER.finditer(translated)):
        result.append('placeholder mismatch')
    for name in PROTECTED:
        if original.count(name) != translated.count(name): result.append('protected name changed: '+name)
    if len(translated) > max(20, len(original)*1.65): result.append('long translation: layout review required')
    if original == translated and not any(name == original for name in PROTECTED): result.append('unchanged translation: review required')
    if not translated.strip(): result.append('empty translation')
    return result
def protect(value):
    tokens=[]
    pattern = re.compile(PLACEHOLDER.pattern+'|'+ '|'.join(re.escape(x) for x in PROTECTED))
    def replace(match):
        tokens.append(match.group(0)); return f'__KEEP_{len(tokens)-1}__'
    return pattern.sub(replace,value),tokens
def unprotect(value, tokens):
    expected=[f'__KEEP_{i}__' for i in range(len(tokens))]
    if sorted(re.findall(r'__KEEP_\d+__',value)) != sorted(expected):
        raise ValueError('provider changed protected placeholders')
    for index,token in enumerate(tokens): value=value.replace(f'__KEEP_{index}__',token)
    return value
def export(locale, out):
    catalog=read(CATALOG); pending=[]
    for key,entry in sorted(catalog['strings'].items()):
        unit=entry.get('localizations',{}).get(locale,{}).get('stringUnit',{})
        if unit.get('state') != 'translated':
            original=source(entry)
            pending.append(dict(key=key,source=original,sourceHash=digest(original),translation=unit.get('value',''),approved=False,allowWarnings=False))
    write(out,dict(locale=locale,sourceLanguage='en',translations=pending))
    print(f'Exported {len(pending)} strings for {locale}.')
def translate(path, endpoint, out):
    if not endpoint.startswith('https://'): raise ValueError('translation endpoint must use HTTPS')
    key=os.environ.get('TRANSLATION_API_KEY')
    if not key: raise ValueError('set TRANSLATION_API_KEY locally; do not paste it into chat')
    batch=read(path)
    # Reject arbitrary documents: every item must match the checked-in application catalog.
    catalog=read(CATALOG)['strings']
    lookup={}; items=[]
    for item in batch['translations']:
        if item['key'] not in catalog or item['source'] != source(catalog[item['key']]):
            raise ValueError('input is not current application localization content')
        value,tokens=protect(item['source']); lookup[item['key']]=tokens
        items.append(dict(key=item['key'],text=value))
    payload=dict(sourceLanguage='en',targetLanguage=batch['locale'],
        instruction='Translate game UI. Preserve __KEEP_N__ tokens exactly. Return JSON translations array with key and text.',strings=items)
    request=urllib.request.Request(endpoint,data=json.dumps(payload).encode(),headers={'Content-Type':'application/json','Authorization':'Bearer '+key})
    # Configurable provider adapter contract, not a hard-coded vendor model/API.
    with urllib.request.urlopen(request,timeout=90) as response: result=json.load(response)
    translated={item['key']:item['text'] for item in result['translations']}
    if set(translated) != set(lookup): raise ValueError('provider returned missing or unexpected keys')
    for item in batch['translations']:
        item['translation']=unprotect(translated[item['key']],lookup[item['key']])
        item['warnings']=issues(item['source'],item['translation'])
        item['approved']=False
    write(out,batch)
    print('Draft translations saved. Human approval is required before import.')
def import_approved(path):
    batch=read(path); locale=batch['locale']
    if locale not in LOCALES: raise ValueError('unsupported production locale')
    catalog=read(CATALOG)
    # Validate the entire batch before changing any catalog entry.
    for item in batch['translations']:
        if not item.get('approved'): raise ValueError('every imported string must have approved=true')
        entry=catalog['strings'].get(item['key'])
        if entry is None or digest(source(entry)) != item['sourceHash']: raise ValueError('source changed since export; re-export and review')
        warnings=issues(source(entry),item['translation'])
        fatal=[x for x in warnings if 'mismatch' in x or 'changed' in x or 'empty' in x]
        if fatal or (warnings and not item.get('allowWarnings')): raise ValueError(f"{item['key']}: {warnings}")
    for item in batch['translations']:
        catalog['strings'][item['key']]['localizations'][locale]={'stringUnit':{'state':'translated','value':item['translation']}}
    write(CATALOG,catalog)
    print(f"Imported {len(batch['translations'])} reviewed translations.")
def pseudo(out):
    catalog=read(CATALOG)
    table=str.maketrans('aeiouAEIOU','áëïöüÁËÏÖÜ')
    translated={}
    for key,entry in catalog['strings'].items():
        value,tokens=protect(source(entry))
        expanded=value.translate(table)+' ~'*max(1,len(value)//5)
        translated[key]='['+unprotect(expanded,tokens)+']'
    # Development .strings file can be copied into a test-only qps-ploc.lproj bundle.
    Path(out).write_text('\n'.join(json.dumps(k)+' = '+json.dumps(v,ensure_ascii=False)+';' for k,v in translated.items())+'\n',encoding='utf-8')
    print('Pseudolocalized resource generated; not added to production languages.')
def audit():
    catalog=read(CATALOG)
    failures=[]
    for path in (ROOT/'App').rglob('*.swift'):
        body=path.read_text(encoding='utf-8')
        for key in re.findall(r'(?:LText|LocalizationManager\.string)\("([a-zA-Z][\w.]+)"\)',body):
            if key not in catalog['strings']: failures.append(f'{path.name}: missing key {key}')
    content=read(ROOT/'Sources/ScrapCore/Resources/content.json')
    def walk(value):
        if isinstance(value,dict):
            for key,item in value.items():
                if key.endswith('Key') and item not in catalog['strings']: failures.append('content missing '+item)
                walk(item)
        elif isinstance(value,list):
            for item in value: walk(item)
    walk(content)
    for locale in LOCALES:
        missing=sum(1 for entry in catalog['strings'].values() if entry.get('localizations',{}).get(locale,{}).get('stringUnit',{}).get('state') != 'translated')
        print(f'{locale}: {missing} awaiting translation/review')
    if failures: raise ValueError('\n'.join(failures))
    print(f"Catalog audit passed: {len(catalog['strings'])} English source keys; all content references resolve.")
def extract(out):
    catalog=read(CATALOG)['strings']; keys=set()
    for path in (ROOT/'App').rglob('*.swift'):
        keys.update(re.findall(r'(?:LText|LocalizationManager\.string)\("([a-zA-Z][\w.]+)"\)',path.read_text(encoding='utf-8')))
    def walk(value):
        if isinstance(value,dict):
            for key,item in value.items():
                if key.endswith('Key'): keys.add(item)
                walk(item)
        elif isinstance(value,list):
            for item in value: walk(item)
    walk(read(ROOT/'Sources/ScrapCore/Resources/content.json'))
    write(out,dict(newSourceKeys=[dict(key=key,source='',state='needs_English_source') for key in sorted(keys-set(catalog))],
        instruction='Add reviewed English source text to Tools/author_content.py, then regenerate the catalog before exporting translations.'))
    print(f'Extracted {len(keys-set(catalog))} missing source keys.')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    sub=parser.add_subparsers(dest='command',required=True)
    sub.add_parser('audit')
    p=sub.add_parser('extract'); p.add_argument('out')
    p=sub.add_parser('export'); p.add_argument('locale',choices=LOCALES); p.add_argument('out')
    p=sub.add_parser('translate'); p.add_argument('input'); p.add_argument('--endpoint',required=True); p.add_argument('--out',required=True)
    p=sub.add_parser('import-approved'); p.add_argument('input')
    p=sub.add_parser('pseudo'); p.add_argument('out')
    args=parser.parse_args()
    if args.command=='audit': audit()
    elif args.command=='extract': extract(args.out)
    elif args.command=='export': export(args.locale,args.out)
    elif args.command=='translate': translate(args.input,args.endpoint,args.out)
    elif args.command=='import-approved': import_approved(args.input)
    elif args.command=='pseudo': pseudo(args.out)
if __name__=='__main__':
    try: main()
    except (ValueError,KeyError,OSError) as error:
        print('Localization error: '+str(error),file=sys.stderr); sys.exit(1)
