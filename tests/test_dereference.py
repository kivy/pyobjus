import unittest
from pyobjus import autoclass, dereference, ObjcInt
from pyobjus.dylib_manager import load_dylib
from pyobjus.objc_py_types import NSRange

Car = car = None

class DereferenceTest(unittest.TestCase):

    def setUp(self):
        global Car, car
        load_dylib('usrlib.dylib', usr_path=False)
        Car = autoclass('Car')
        car = Car.alloc().init()

    def test_dereference_basic(self):
        rng_ptr = car.makeRangePtr()
        rng = dereference(rng_ptr)
        self.assertEquals(rng.location, 567)
        self.assertEquals(rng.length, 123)

    def test_dereference_with_type(self):
        int_ptr = car.makeIntVoidPtr()
        int_val = dereference(int_ptr, of_type=ObjcInt)
        self.assertEquals(int_val, 12345)
