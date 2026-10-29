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

    def test_char_ptr_rejects_embedded_nul(self):
        for bad in ('a\x00b', b'a\x00b'):
            with self.assertRaisesRegex(ValueError, 'embedded null byte'):
                NSString.stringWithUTF8String_(bad)
