import unittest
from pyobjus import ObjcClass, ObjcMethod, MetaObjcClass, autoclass

class HelloWorldTest(unittest.TestCase):

    def test_autoclass(self):
        NSString = autoclass("NSString")
        s = NSString().initWithUTF8String_('hello world')
        self.assertEqual(s.length(), 11)


    def test_autoclass2(self):
        NSString = autoclass("NSString")
        s = NSString.stringWithString_('hello world')
        self.assertEqual(s.length(), 11)


    def test_classmathod(self):
        NSString = autoclass("NSString")
        NSString.classMethod()

