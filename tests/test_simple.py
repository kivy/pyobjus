import unittest
from pyobjus import ObjcClass, ObjcMethod, MetaObjcClass, autoclass

class HelloWorldTest(unittest.TestCase):

    def test_autoclass(self):
        NSString = autoclass("NSString")
        s = NSString.alloc().initWithUTF8String_('hello world')
        self.assertEqual(s.length(), 11)


    def test_autoclass2(self):
        NSString = autoclass("NSString")
        print NSString.stringWithString_
        s = NSString.stringWithUTF8String_('hello world')
        self.assertEqual(s.length(), 11)
