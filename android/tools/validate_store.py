"""Validate Amazon listing text and optional genuine capture dimensions."""
import argparse
import json
from pathlib import Path
import struct

android = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--screenshots', type=Path)
parser.add_argument('--assets', type=Path)
args = parser.parse_args()
store = json.loads((android / 'store/listings.json').read_text(encoding='utf-8'))
for locale, listing in store['locales'].items():
    assert len(listing['shortDescription'].encode('utf-8')) <= 2000, locale
    assert len(listing['longDescription']) <= 4000, locale
    assert 3 <= len(listing['features']) <= 5, locale
    assert '<' not in listing['longDescription'] and '>' not in listing['longDescription'], locale
    assert ',' in listing['keywords'], locale
    print(f'{locale}: short {len(listing["shortDescription"].encode("utf-8"))}/2000 bytes; long {len(listing["longDescription"])}/4000 characters')
if args.screenshots:
    sizes = {(800, 480), (1024, 600), (1280, 720), (1280, 800), (1920, 1080), (1920, 1200), (2560, 1600)}
    for name in store['screenshotCaptions']:
        path = args.screenshots / name
        header = path.read_bytes()[:24]
        assert header[:8] == b'\x89PNG\r\n\x1a\n', f'Not a PNG: {path}'
        dimensions = struct.unpack('>II', header[16:24])
        assert dimensions in sizes or dimensions[::-1] in sizes, f'Unsupported size: {path} {dimensions}'
    print('All 10 genuine screenshot dimensions passed.')
if args.assets:
    for name, expected in [('icon-114', (114, 114)), ('icon-512', (512, 512)), ('promo', (1024, 500))]:
        path = args.assets / f'scrap-squad-{name}.png'
        header = path.read_bytes()[:24]
        assert header[:8] == b'\x89PNG\r\n\x1a\n', f'Not a PNG: {path}'
        assert struct.unpack('>II', header[16:24]) == expected, f'Wrong artwork size: {path}'
    print('Original icon and promotional-art exports passed.')
