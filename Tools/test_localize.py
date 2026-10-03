import unittest
import tempfile
from pathlib import Path
import localize
import offline_localize
from unittest.mock import patch

class LocalizationTests(unittest.TestCase):
    def test_offline_translator_preserves_product_names_and_placeholders(self):
        translated=offline_localize.translate_preserving_tokens('BOLT found %d in Scrap City.',lambda value:value.replace('found','trouve').replace('in','dans'))
        self.assertEqual(translated,'BOLT trouve %d dans Scrap City.')
        self.assertNotIn('placeholder mismatch',localize.issues('BOLT found %d in Scrap City.',translated))
    def test_duplicate_provider_keys_rejected(self):
        with self.assertRaises(ValueError):
            localize.validate_response({'translations':[{'key':'a','text':'A'},{'key':'a','text':'B'}]},['a'])
    def test_batched_translation_cache_and_review_gate(self):
        with tempfile.TemporaryDirectory() as directory:
            directory=Path(directory); catalog=directory/'catalog.json'; batch=directory/'source.json'; output=directory/'out.json'; cache=directory/'cache.json'
            localize.write(catalog,{'strings':{key:{'localizations':{'en':{'stringUnit':{'value':text,'state':'translated'}}}} for key,text in [('a','Start'),('b','BOLT wins %d')]}})
            original=localize.CATALOG; localize.CATALOG=catalog
            def reply(endpoint,payload,key,provider):
                return {'translations':[{'key':row['key'],'text':row['text'].replace('Start','Démarrer').replace('wins','gagne')} for row in payload['strings']]}
            try:
                localize.export('fr',batch)
                with patch.dict('os.environ',{'TRANSLATION_API_KEY':'test-only'}), patch.object(localize,'request_translation',side_effect=reply) as provider:
                    localize.translate(batch,'https://example.test/translate',output,batch_size=1,cache=cache)
                    self.assertEqual(provider.call_count,2)
                    localize.translate(batch,'https://example.test/translate',output,batch_size=1,cache=cache)
                    self.assertEqual(provider.call_count,2)
                result=localize.read(output)
                self.assertEqual(result['translations'][1]['translation'],'BOLT gagne %d')
                self.assertFalse(any(row['approved'] for row in result['translations']))
                self.assertNotIn('test-only',cache.read_text())
                with self.assertRaises(ValueError): localize.import_approved(output)
            finally: localize.CATALOG=original

    def test_placeholders_and_names_roundtrip(self):
        text='Scrap Squad: BOLT found %1$d cores for {commander}.'
        protected,tokens=localize.protect(text)
        self.assertEqual(localize.unprotect(protected,tokens),text)
        self.assertNotIn('BOLT',protected)
    def test_provider_cannot_drop_tokens(self):
        with self.assertRaises(ValueError): localize.unprotect('Bonjour', ['BOLT'])
    def test_provider_cannot_duplicate_tokens(self):
        with self.assertRaises(ValueError): localize.unprotect('__KEEP_0__ __KEEP_0__',['BOLT'])
    def test_changed_placeholders_are_flagged(self):
        self.assertIn('placeholder mismatch',localize.issues('Found %d','Trouvé %@'))
    def test_product_names_are_protected(self):
        self.assertTrue(any('protected name changed' in x for x in localize.issues('Scrap City','Ville de ferraille')))
    def test_expansion_is_flagged(self):
        self.assertTrue(any('long translation' in x for x in localize.issues('Start','Begin the amazing adventure now')))
    def test_unreviewed_import_does_not_change_catalog(self):
        with tempfile.TemporaryDirectory() as directory:
            catalog=Path(directory)/'catalog.json'; batch=Path(directory)/'batch.json'
            localize.write(catalog,{'strings':{'start':{'localizations':{'en':{'stringUnit':{'value':'Start','state':'translated'}}}}}})
            localize.write(batch,{'locale':'fr','translations':[{'key':'start','translation':'Démarrer','sourceHash':localize.digest('Start'),'approved':False}]})
            before=catalog.read_bytes(); original=localize.CATALOG; localize.CATALOG=catalog
            try:
                with self.assertRaises(ValueError): localize.import_approved(batch)
                self.assertEqual(catalog.read_bytes(),before)
            finally: localize.CATALOG=original
    def test_stale_source_import_does_not_change_catalog(self):
        with tempfile.TemporaryDirectory() as directory:
            catalog=Path(directory)/'catalog.json'; batch=Path(directory)/'batch.json'
            localize.write(catalog,{'strings':{'start':{'localizations':{'en':{'stringUnit':{'value':'New source','state':'translated'}}}}}})
            localize.write(batch,{'locale':'fr','translations':[{'key':'start','translation':'Démarrer','sourceHash':localize.digest('Start'),'approved':True}]})
            before=catalog.read_bytes(); original=localize.CATALOG; localize.CATALOG=catalog
            try:
                with self.assertRaises(ValueError): localize.import_approved(batch)
                self.assertEqual(catalog.read_bytes(),before)
            finally: localize.CATALOG=original

if __name__=='__main__': unittest.main()
