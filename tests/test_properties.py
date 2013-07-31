import unittest
import os
import ctypes
from pyobjus import autoclass, dereference, load_usr_lib

Car = None

class ObjcPropertyTest(unittest.TestCase):

    def setUp(self):
        global Car, car
        load_usr_lib('usrlib.dylib', usr_path=False)
        Car = autoclass('Car')
        car = Car.alloc().init()

    def test_basic_properties(self):
        car.propInt = 12345
        self.assertEquals(car.propInt, 12345)

        car.propDouble = 3456.2345
        self.assertEquals(car.propDouble, 3456.2345)

        car.prop_double_ptr = 333.444
        self.assertEquals(dereference(car.prop_double_ptr), 333.444)

        car.propNSString = autoclass('NSString').stringWithUTF8String_('string for test')
        self.assertEquals(car.propNSString.UTF8String(), 'string for test')

    def test_dynamic_properties(self):
        car.setProp()
        self.assertEquals(car.propNsstringDyn.UTF8String(), 'from objective c')
        car.propNsstringDyn = autoclass('NSString').stringWithUTF8String_('from python')
        self.assertEquals(car.propNsstringDyn.UTF8String(), 'from python')

    def test_custom_setter_properties(self):
        car.propIntCst = 67890
        self.assertEquals(car.propIntCst, 67890)

    def test_custom_getter_properties(self):
        car.propIntCst = 5678
        self.assertEquals(car.propIntCst, 5678)

        # this is int*
        car.propCstInt = 3456
        self.assertEquals(dereference(car.propCstInt), 3456)

    def test_readonly_properties(self):
        self.assertRaises(Exception, car.propIntRO)
