"""Argos Translate: source-only draft translation, no paid API or app secrets."""
import os
import re
from pathlib import Path
import localize

TARGETS={'es':'es','fr':'fr','de':'de','it':'it','pt':'pt','pt-BR':'pb','ja':'ja','ko':'ko','zh-Hans':'zh','zh-Hant':'zt'}

def translate_preserving_tokens(text, translator):
    protected,tokens=localize.protect(text)
    parts=re.split(r'(__KEEP_\d+__)',protected)
    translated=[]
    for part in parts:
        if re.fullmatch(r'__KEEP_\d+__',part) or not part.strip(): translated.append(part)
        else:
            leading=part[:len(part)-len(part.lstrip())]; trailing=part[len(part.rstrip()):]
            translated.append(leading+translator(part.strip())+trailing)
    return localize.unprotect(''.join(translated),tokens)

def main():
    import argostranslate.package
    import argostranslate.translate
    choice=os.environ.get('TRANSLATION_LOCALE','all')
    if choice!='all' and choice not in TARGETS: raise ValueError('unsupported locale')
    argostranslate.package.update_package_index()
    available=argostranslate.package.get_available_packages()
    directory=localize.ROOT/'.build/localization-drafts'; directory.mkdir(parents=True,exist_ok=True)
    report={}
    for locale in TARGETS if choice=='all' else [choice]:
        target=TARGETS[locale]
        installed=argostranslate.package.get_installed_packages()
        if not any(p.from_code=='en' and p.to_code==target for p in installed):
            package=next((p for p in available if p.from_code=='en' and p.to_code==target),None)
            if package is None: raise ValueError('no direct English model for '+locale)
            argostranslate.package.install_from_path(package.download())
        package=next(p for p in argostranslate.package.get_installed_packages() if p.from_code=='en' and p.to_code==target)
        languages=argostranslate.translate.get_installed_languages()
        origin=next(x for x in languages if x.code=='en'); language=next(x for x in languages if x.code==target)
        engine=origin.get_translation(language)
        source=directory/f'{locale}-source.json'; localize.export(locale,source); batch=localize.read(source)
        cache_path=localize.ROOT/'.build/translation-cache'/f'argos-{locale}.json'
        cache=localize.read(cache_path) if cache_path.exists() else {}
        warnings=0
        for index,item in enumerate(batch['translations']):
            cache_key=localize.digest(str(package.package_version)+'|'+locale+'|'+item['source'])
            if cache_key not in cache:
                cache[cache_key]=translate_preserving_tokens(item['source'],engine.translate)
            item['translation']=cache[cache_key]
            item['warnings']=localize.issues(item['source'],item['translation'])
            if locale=='pt': item['warnings'].append('European Portuguese terminology review required')
            item['approved']=False; warnings+=bool(item['warnings'])
            if index%25==0: localize.write(cache_path,cache)
        localize.write(cache_path,cache)
        batch['provider']={'name':'Argos Translate','version':'1.11.0','target':target,'modelVersion':str(package.package_version),'apiFees':0}
        localize.write(directory/f'{locale}-draft.json',batch)
        report[locale]={'strings':len(batch['translations']),'stringsWithWarnings':warnings,'approved':0,'providerTarget':target}
        localize.write(directory/'report.json',report)
        print(f'{locale}: {len(batch["translations"])} translated drafts, {warnings} with review warnings.',flush=True)
    print('Offline translation complete. Production String Catalog was not modified.',flush=True)

if __name__=='__main__':
    try: main()
    except (ValueError,KeyError,OSError) as error: raise SystemExit('Offline localization failed: '+str(error))
