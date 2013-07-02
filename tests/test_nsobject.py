import unittest
from pyobjus import ObjcClass, ObjcMethod, MetaObjcClass, autoclass

NSObject = None
NSString = None

class NSObject(unittest.TestCase):

    def setUp(self):
        global NSObject, NSString
        NSObject = autoclass('NSObject')
        NSString = autoclass('NSString')

    def test_hash(self):
        self.assertIsInstance(NSObject.hash(), long)

    def test_isequal(self):
        a = NSObject.alloc().init()
        b = NSObject.alloc().init()
        self.assertTrue(a.isEqual_(a))
        self.assertFalse(a.isEqual_(b))

    def test_self(self):
        a = NSObject.alloc()
        self.assertIs(a, a.self())

    def test_description(self):
        a = NSObject()
        text = a.description()
        self.assertIsNotNone(text)

    def test_debugDescription(self):
        a = NSObject.alloc()
        text = a.debugDescription()
        text = a.description()
        self.assertIsNotNone(text)
        self.assertIsNotNone(text.cString())
        self.assertTrue(text.cString().startswith('<NSObject:'))

    def test_isproxy(self):
        self.assertFalse(NSObject.isProxy())

    def test_inheritance(self):
        a = NSObject()
        b = NSString()
        self.assertTrue(b.isKindOfClass_(a))
