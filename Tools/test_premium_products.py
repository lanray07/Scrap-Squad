import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
class PremiumProductTests(unittest.TestCase):
    def test_store_products_match_bundled_entitlements_and_prices(self):
        packs = json.loads((ROOT / 'App/Resources/StoreConfiguration.json').read_text(encoding='utf-8'))['packs']
        store = json.loads((ROOT / 'UITests/Cosmetics.storekit').read_text(encoding='utf-8'))['products']
        offers = json.loads((ROOT / 'Docs/Store/IAP/premium-products.json').read_text(encoding='utf-8'))
        ids = {p['id'] for p in packs}
        self.assertEqual(ids, {p['productID'] for p in store})
        self.assertEqual(len(ids), 7)
        for offer in offers:
            product = next(p for p in store if p['productID'] == offer['productID'])
            self.assertEqual(product['type'], 'NonConsumable')
            self.assertEqual(product['displayPrice'], offer['priceGBP'])
            self.assertEqual(len(offer['localizations']), 11)
            for row in offer['localizations'].values():
                self.assertTrue(0 < len(row['name']) <= 35)
                self.assertTrue(0 < len(row['description']) <= 55)
        bundle = next(p for p in packs if p['id'].endswith('.collection'))
        self.assertEqual(set(bundle['includes']), {p['productID'] for p in offers if not p['productID'].endswith('.collection')})
        self.assertFalse(bundle['founderExtras'])
