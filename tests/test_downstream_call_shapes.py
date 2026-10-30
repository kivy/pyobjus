"""Call shapes from downstream apps that the rest of the suite does not cover.

* objc_py_types.enum values as NSUInteger arguments, as Ren'Py finds its iOS
  save directory:
  https://github.com/renpy/renpy/blob/HEAD/renpy.py
* None for an NSError** argument:
  https://github.com/kivy/kivy/blob/HEAD/kivy/core/audio_output/audio_avplayer.py
  https://github.com/kivy/plyer/blob/HEAD/plyer/platforms/macosx/wifi.py
* None for a completion block, and {} for an options dictionary:
  https://github.com/kivy/plyer/blob/HEAD/plyer/platforms/ios/filechooser.py
  https://github.com/bitdust-io/p2p-app/blob/HEAD/src/lib/system.py

Results are checked with methods only: whether a getter such as NSURL.path
is a property or a method depends on the runtime class.
"""
import os
import shutil
import sys
import tempfile
import unittest

import pytest

from pyobjus import autoclass
from pyobjus.objc_py_types import enum

NSUTF8StringEncoding = 4


@pytest.mark.skipif(sys.platform != "darwin", reason="Only for macOS, as it needs Foundation")
class DownstreamCallShapesTest(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.manager = autoclass("NSFileManager").defaultManager()
        cls.NSString = autoclass("NSString")
        cls.NSURL = autoclass("NSURL")

    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.dir)
        self.file = os.path.join(self.dir, "a.txt")
        self.missing = os.path.join(self.dir, "missing")
        with open(self.file, "w") as f:
            f.write("hello")

    def test_enum_values_as_nsuinteger_arguments(self):
        NSSearchPathDirectory = enum("NSSearchPathDirectory", NSDocumentDirectory=9)
        NSSearchPathDomainMask = enum("NSSearchPathDomainMask", NSUserDomainMask=1)
        self.assertEqual(NSSearchPathDirectory.NSDocumentDirectory, 9)

        url = self.manager.URLsForDirectory_inDomains_(
            NSSearchPathDirectory.NSDocumentDirectory,
            NSSearchPathDomainMask.NSUserDomainMask).lastObject()
        expected = self.NSURL.fileURLWithPath_isDirectory_(
            os.path.expanduser("~/Documents"), True)
        self.assertTrue(url.isEqual_(expected))

    def test_none_for_an_error_argument(self):
        read = self.NSString.stringWithContentsOfFile_encoding_error_
        self.assertEqual(read(self.file, NSUTF8StringEncoding, None).UTF8String(), b"hello")
        self.assertIsNone(read(self.missing, NSUTF8StringEncoding, None))

        # BOOL-returning methods report the failure as False.
        self.assertFalse(self.manager.removeItemAtPath_error_(self.missing, None))
        self.assertTrue(self.manager.createDirectoryAtPath_withIntermediateDirectories_attributes_error_(
            os.path.join(self.dir, "x", "y"), True, None, None))

        listing = self.manager.contentsOfDirectoryAtPath_error_(self.dir, None)
        self.assertTrue(listing.containsObject_("a.txt"))
        self.assertIsNone(self.manager.contentsOfDirectoryAtPath_error_(self.missing, None))

    def test_none_for_a_block_argument(self):
        os.mkdir(os.path.join(self.dir, "sub"))
        enumerator = self.manager.enumeratorAtURL_includingPropertiesForKeys_options_errorHandler_(
            self.NSURL.fileURLWithPath_(self.dir), None, 0, None)
        found = 0
        while enumerator.nextObject() is not None:
            found += 1
        self.assertEqual(found, 2)

    def test_empty_dict_for_a_dictionary_argument(self):
        path = os.path.join(self.dir, "b.txt")
        self.assertTrue(self.manager.createFileAtPath_contents_attributes_(path, None, {}))
        self.assertTrue(os.path.exists(path))
