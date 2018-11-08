import unittest
from pyobjus import ObjcClass, ObjcMethod, MetaObjcClass, autoclass
import sys

PY2 = sys.version_info.major == 2

NSObject = None
NSString = None

class NSObject(unittest.TestCase):

    def setUp(self):
        global NSObject, NSString
        NSObject = autoclass('NSObject')
        NSString = autoclass('NSString')

    def test_hash(self):
        a = NSObject.alloc().init()
        if PY2:
            self.assertIsInstance(a.hash, long)
        else:
            self.assertIsInstance(a.hash, int)

    def test_isequal(self):
        a = NSObject.alloc().init()
        b = NSObject.alloc().init()
        self.assertTrue(a.isEqual_(a))
        self.assertFalse(a.isEqual_(b))

    def test_self(self):
        a = NSObject.alloc()
        self.assertIs(a, a.self())

    def test_description(self):
        a = NSObject.alloc().init()
        text = a.description
        self.assertIsNotNone(text)

    def test_debugDescription(self):
        a = NSObject.alloc()
        text = a.description
        self.assertIsNotNone(text)
        self.assertIsNotNone(text.cString())
        self.assertTrue(text.cString().startswith(b'<NSObject:'))

    def test_isproxy(self):
        self.assertFalse(NSObject.isProxy())

    def test_inheritance(self):
        a = NSObject
        b = NSString.alloc().init()
        cls = a.oclass()
        self.assertTrue(NSString.isKindOfClass_(cls))
        self.assertTrue(b.isKindOfClass_(cls))
        c = NSString.alloc().init()
        self.assertTrue(b.isKindOfClass_(c.oclass()))
