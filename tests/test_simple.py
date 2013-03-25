import unittest
from pyobjus import ObjcClass, ObjcMethod, MetaObjcClass, autoclass

class HelloWorldTest(unittest.TestCase):

    def test_autoclass(self):
        NSString = autoclass("NSString")
        s = NSString().initWithUTF8String_('hello world')
        self.assertEqual(s.length(), 11)
