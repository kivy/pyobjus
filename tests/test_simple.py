import unittest
from pyobjus import ObjcClass, ObjcMethod, MetaObjcClass

class HelloWorldTest(unittest.TestCase):

    def test_helloworld(self):

        class NSString(ObjcClass):
            __objcclass__ = 'NSString'
            __metaclass__ = MetaObjcClass

            custom = ObjcMethod('v8:0')

        a = NSString('hello world')
        self.assertEquals(a.substring(6), 'world')

