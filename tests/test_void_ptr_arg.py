"""Python values passed to a void* argument (issue #107)."""
import base64
import sys
import unittest

import pytest

from pyobjus import autoclass


def nsdata_bytes(data):
    encoded = data.base64EncodedStringWithOptions_(0).UTF8String()
    return base64.b64decode(encoded)


@pytest.mark.skipif(sys.platform != "darwin", reason="Only for macOS, as it needs Foundation")
class VoidPtrArgTest(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.NSData = autoclass("NSData")

    def test_bytes_reach_the_callee(self):
        for sent in (b"\x01\x02\x03", b"12345", b"\x00\xfe\xff\x00"):
            with self.subTest(sent=sent):
                data = self.NSData.dataWithBytes_length_(sent, len(sent))
                self.assertEqual(data.length(), len(sent))
                self.assertEqual(nsdata_bytes(data), sent)

    def test_str_is_passed_as_utf8(self):
        data = self.NSData.dataWithBytes_length_("abc", 3)
        self.assertEqual(nsdata_bytes(data), b"abc")
