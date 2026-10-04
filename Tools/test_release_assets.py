"""Offline checks for gallery preservation, integrity and idempotent retries."""
import hashlib
import json
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import patch
import release_assets


class FakeApple:
    def __init__(self, assets):
        self.assets = assets.copy()
        self.events = []

    def all(self, path):
        if "appScreenshotSets?" in path:
            return [{"id": "set", "attributes": {"screenshotDisplayType": "APP_IPHONE_67"}}]
        return self.assets.copy()

    def call(self, method, path, body=None):
        self.events.append(method)
        if method == "GET":
            return {"data": next(a for a in self.assets if path.endswith("/" + a["id"]))}
        if method == "DELETE":
            self.assets = [a for a in self.assets if not path.endswith("/" + a["id"])]
        if method == "PATCH":
            order = [a["id"] for a in body["data"]]
            self.assets.sort(key=lambda a: order.index(a["id"]))
        return {}


def asset(identifier, checksum):
    return {"id": identifier, "attributes": {"sourceFileChecksum": checksum, "assetDeliveryState": {"state": "COMPLETE"}}}


class GalleryTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.path = Path(self.directory.name)
        self.shots = []
        self.assets = []
        for index in range(10):
            # Transport fixtures only; these are never published as screenshots.
            content = b'\x89PNG\r\n\x1a\n' + b'\0' * 8 + struct.pack('>II', 1320, 2868) + bytes([8, 2, index])
            name = f"{index + 1:02}-fixture.png"
            (self.path / name).write_bytes(content)
            self.shots.append({"order": index + 1, "file": name, "exportSHA256": hashlib.sha256(content).hexdigest()})
            self.assets.append(asset(str(index), hashlib.md5(content).hexdigest()))
        (self.path / "manifest.json").write_text(json.dumps({"screenshots": self.shots}))

    def tearDown(self):
        self.directory.cleanup()

    def test_matching_complete_gallery_is_preserved_and_order_verified(self):
        api = FakeApple(list(reversed(self.assets)))
        with patch.object(release_assets, "upload", side_effect=AssertionError("must not upload")):
            result = release_assets.refresh(api, "locale", "APP_IPHONE_67", self.path)
        self.assertTrue(result["checksumsVerified"])
        self.assertNotIn("DELETE", api.events)
        self.assertEqual([a["id"] for a in api.assets], [str(i) for i in range(10)])

    def test_corrupted_local_export_stops_before_any_apple_mutation(self):
        (self.path / self.shots[0]["file"]).write_bytes(b"corrupted")
        api = FakeApple(self.assets)
        with self.assertRaises(AssertionError):
            release_assets.refresh(api, "locale", "APP_IPHONE_67", self.path)
        self.assertEqual(api.events, [])

    def test_full_gallery_replaces_only_one_obsolete_slot_per_upload(self):
        api = FakeApple([asset(f"old{i}", f"obsolete{i}") for i in range(10)])
        def upload(fake, set_id, file):
            self.assertEqual(len(fake.assets), 9)
            fake.events.append("UPLOAD")
            result = asset(file.stem, hashlib.md5(file.read_bytes()).hexdigest())
            fake.assets.append(result)
            return result
        with patch.object(release_assets, "upload", side_effect=upload):
            result = release_assets.refresh(api, "locale", "APP_IPHONE_67", self.path)
        self.assertEqual(api.events[:-1], ["DELETE", "UPLOAD"] * 10)
        self.assertEqual(result["count"], 10)


if __name__ == "__main__":
    unittest.main()
