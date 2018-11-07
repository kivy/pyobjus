import unittest
from pyobjus import autoclass, dereference
from pyobjus.dylib_manager import load_dylib

Car = None

class ObjcPropertyTest(unittest.TestCase):

    def setUp(self):
        global Car, car
        load_dylib('testlib.dylib', usr_path=False)
        Car = autoclass('Car')
        car = Car.alloc().init()

    def test_basic_properties(self):
        car.propInt = 12345
        self.assertEqual(car.propInt, 12345)

        car.propDouble = 3456.2345
        self.assertEqual(car.propDouble, 3456.2345)

        # car.prop_double_ptr = 333.444
        # self.assertEqual(dereference(car.prop_double_ptr), 333.444)

        car.propNSString = autoclass('NSString').stringWithUTF8String_('string for test')
        self.assertEqual(car.propNSString.UTF8String(), 'string for test')

    def test_dynamic_properties(self):
        car.setProp()
        self.assertEqual(car.propNsstringDyn.UTF8String(), 'from objective c')
        car.propNsstringDyn = autoclass('NSString').stringWithUTF8String_('from python')
        self.assertEqual(car.propNsstringDyn.UTF8String(), 'from python')

    def test_custom_setter_properties(self):
        car.propIntCst = 67890
        self.assertEqual(car.propIntCst, 67890)

    def test_custom_getter_properties(self):
        car.propIntCst = 5678
        self.assertEqual(car.propIntCst, 5678)

        # this is int*
        # car.propCstInt = 3456
        # self.assertEqual(dereference(car.propCstInt), 3456)

    def test_readonly_properties(self):
        self.assertRaises(Exception, car.propIntRO)
