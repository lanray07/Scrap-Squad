"""Verify draft completeness/integrity; this is not language-quality approval."""
import sys
from pathlib import Path
import localize

def main():
    directory=Path(sys.argv[1] if len(sys.argv)>1 else localize.ROOT/'Localization/Drafts')
    catalog=localize.read(localize.CATALOG)['strings']; total=0; failures=[]
    for locale in localize.LOCALES:
        batch=localize.read(directory/f'{locale}-draft.json')
        rows=batch['translations']; keys=[row['key'] for row in rows]
        if batch['locale']!=locale or len(keys)!=len(set(keys)) or set(keys)!=set(catalog): failures.append(locale+': catalog coverage mismatch')
        for row in rows:
            entry=catalog.get(row['key'])
            if not entry or row['source']!=localize.source(entry) or row['sourceHash']!=localize.digest(localize.source(entry)): failures.append(locale+': stale source '+row['key'])
            problems=localize.issues(row['source'],row['translation'])
            if any(x in ('placeholder mismatch','empty translation') or x.startswith('protected name changed:') for x in problems): failures.append(locale+': integrity error '+row['key'])
            if row.get('approved'): failures.append(locale+': unexpected approval '+row['key'])
            total+=1
    if failures: raise SystemExit('\n'.join(failures))
    print(f'{len(localize.LOCALES)} locales, {total} drafts: complete source coverage, intact placeholders/product names, no empty strings. Language quality remains unapproved.')
if __name__=='__main__': main()
