import unittest
from pyobjus import ObjcClass, ObjcMethod

class HelloWorldTest(unittest.TestCase):

    def test_helloworld(self):

        class HelloWorld(ObjcClass):
            __objcclass__ = 'NSString'
            custom = ObjcMethod('v8:0')

        a = HelloWorld()
        a.custom()
