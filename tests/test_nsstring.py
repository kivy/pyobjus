# -*- coding: utf-8 -*-
import unittest
from pyobjus import ObjcClass, ObjcMethod, MetaObjcClass, autoclass

NSString = None
N = lambda x: NSString.alloc().initWithUTF8String_(x)

class NSObject(unittest.TestCase):

    def setUp(self):
        global NSString
        NSString = autoclass('NSString')

    def test_utf8(self):
        s = u'\x09cole'
        text = N(s)
        self.assertTrue(text.cString() == s)

    def test_length(self):
        self.assertEquals(N('hello').length(), 5)

    def test_lengthEncoding(self):
        #s = u'\xe9cole'
        s = u"šome_str"
        # I tested this in native objective c, and methods for this argument and encoding are returning correct             # vales in pyobjus
        self.assertEquals(N(s.encode('utf8')).lengthOfBytesUsingEncoding_(1), 0)
        self.assertEquals(N(s.encode('utf8')).lengthOfBytesUsingEncoding_(4), 9)

    def test_charactersatindex(self):
        text = N('Hello')
        self.assertEquals(text.characterAtIndex_(0), ord('H'))
        self.assertEquals(text.characterAtIndex_(1), ord('e'))

    def test_utf8string(self):
        text = N('Hello')
        self.assertEquals(text.UTF8String(), 'Hello')

    def test_rangeOfString(self):
       text = N('some text')
       text_new = N('text')
       self.assertEquals(text.rangeOfString_(text_new).location, 5)
       self.assertEquals(text.rangeOfString_(text_new).length, 4)
