import unittest
from pyobjus import ObjcClass, ObjcMethod, MetaObjcClass, autoclass

NSString = None

class HelloWorldTest(unittest.TestCase):

    def setUp(self):
        global NSString
        NSString = autoclass('NSString')

    def test_autoclass(self):
        s = NSString.alloc().initWithUTF8String_('hello world')
        self.assertEqual(s.length(), 11)


    def test_autoclass2(self):
        s = NSString.stringWithUTF8String_('hello world')
        self.assertEqual(s.length(), 11)
