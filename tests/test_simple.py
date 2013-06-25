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


    def test_nsarray(self):
        NSString = autoclass("NSString")
        s = NSString.stringWithUTF8String_('/Users/hello/world')
        print s
        print 'created string:', s
        arr = s.pathComponents()
        print 'components:', arr
