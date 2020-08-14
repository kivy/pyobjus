# -*- coding: utf-8 -*-
import unittest
from pyobjus import autoclass, objc_py_types as opy

NSString = autoclass('NSString')
N = lambda x: NSString.alloc().initWithUTF8String_(x)

class NSObject(unittest.TestCase):

    def test_utf8(self):
        s = u'\x09cole'
        text = N(s)
        self.assertTrue(text.UTF8String() == s.encode('utf8'))
        self.assertTrue(text.cString().decode('utf8') == s)

    def test_length(self):
        self.assertEqual(N('hello').length(), 5)

    def test_lengthEncoding(self):
        #s = u'\xe9cole'
        s = u"šome_str"
        # I tested this in native objective c, and methods for this argument and
        # encoding are returning correct vales in pyobjus
        self.assertEqual(N(s.encode('utf8')).lengthOfBytesUsingEncoding_(1), 0)
        self.assertEqual(N(s.encode('utf8')).lengthOfBytesUsingEncoding_(4), 9)

    def test_charactersatindex(self):
        text = N('Hello')
        self.assertEqual(text.characterAtIndex_(0), ord('H'))
        self.assertEqual(text.characterAtIndex_(1), ord('e'))

    def test_utf8string(self):
        text = N('Hello')
        self.assertEqual(text.UTF8String(), b'Hello')

    def test_rangeOfString(self):
       text = N('some text')
       text_new = N('text')
       self.assertEqual(text.rangeOfString_(text_new).location, 5)
       self.assertEqual(text.rangeOfString_(text_new).length, 4)

    def test_lineRangeForRange(self):
        text = N("some text")
        range = opy.NSRange(0, 0)
        self.assertEqual(text.lineRangeForRange_(range).location, 0)
        self.assertEqual(text.lineRangeForRange_(range).length, 9)

    def test_substringWithRange(self):
        text = N("some text")
        range = opy.NSRange(1, 3)
        self.assertEqual(text.substringWithRange_(range).UTF8String(), b"ome")

    def test_compare(self):
        text = N("some text")
        text_to_compare = N("some text")
        self.assertEqual(text.compare_(text_to_compare), opy.NSComparisonResult.NSOrderedSame)
        text_to_compare = N("text")
        self.assertEqual(text.compare_(text_to_compare), opy.NSComparisonResult.NSOrderedAscending)

    def test_hasPrefix(self):
        text = N("_some text")
        prefix = N("_")
        self.assertTrue(text.hasPrefix_(prefix))
        prefix = N("-")
        self.assertFalse(text.hasPrefix_(prefix))

    def test_hasSuffix(self):
        text = N('some text_')
        suffix = N('_')
        self.assertTrue(text.hasSuffix_(suffix))

    def test_hash(self):
        text = N("some text")
        self.assertEqual(text.hash(), 8096103966134034082)

    def test_isAbsolutePath(self):
        text = N("/Users/")  # must be a path that exists
        self.assertTrue(text.isAbsolutePath())
        text = N('./gsoc/pyobjus')
        self.assertFalse(text.isAbsolutePath())

    def test_fastestEncoding(self):
        text = N("šome text")
        self.assertEqual(text.fastestEncoding(), opy.NSStringEncoding.NSUnicodeStringEncoding)

    def test_capitalizedString(self):
        text = N("some text")
        self.assertEqual(text.capitalizedString().UTF8String(), "Some Text")

    def text_capitalizedStringWithLocale(self):
        NSLocale = autoclass("NSLocale")
        locale = NSLocale.currentLocale()
        text = N("some text")
        self.assertEqual(text.capitalizedStringWithLocale_(locale).UTF8String(), "Some Text")
