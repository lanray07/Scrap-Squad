import unittest
import tempfile
from pathlib import Path
import localize

class LocalizationTests(unittest.TestCase):
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
