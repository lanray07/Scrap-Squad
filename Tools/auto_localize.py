"""CI orchestration. Exports app strings, invokes a provider, never approves drafts."""
import os
from pathlib import Path
import localize

def main():
    endpoint=os.environ.get('TRANSLATION_ENDPOINT','')
    if not endpoint or not os.environ.get('TRANSLATION_API_KEY'):
        raise SystemExit('Configure repository variable TRANSLATION_ENDPOINT and secret TRANSLATION_API_KEY. Apple signing secrets cannot translate text.')
    locale=os.environ.get('TRANSLATION_LOCALE','all')
    if locale != 'all' and locale not in localize.LOCALES: raise SystemExit('Unsupported locale')
    provider=os.environ.get('TRANSLATION_PROVIDER','custom')
    if provider not in ('custom','libretranslate'): raise SystemExit('Unsupported provider')
    if provider=='libretranslate' and locale=='all': raise SystemExit('Select one locale for LibreTranslate so regional targets can be reviewed explicitly')
    directory=localize.ROOT/'.build/localization-drafts'; directory.mkdir(parents=True,exist_ok=True)
    for language in localize.LOCALES if locale=='all' else [locale]:
        source=directory/f'{language}-source.json'; output=directory/f'{language}-draft.json'
        localize.export(language,source)
        localize.translate(source,endpoint,output,provider=provider,cache=localize.ROOT/'.build/translation-cache'/f'{language}.json',target=os.environ.get('TRANSLATION_TARGET') or None)
    print('Translation drafts generated. No production catalog was modified.')

if __name__=='__main__':
    try: main()
    except (ValueError,KeyError,OSError) as error:
        raise SystemExit('Draft generation failed: '+str(error))
