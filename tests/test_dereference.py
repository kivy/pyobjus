import unittest
from pyobjus import autoclass, dereference, ObjcInt, ObjcSelector
from pyobjus.dylib_manager import load_dylib
from pyobjus.objc_py_types import NSRange
import pytest
import sys

Car = car = None

@pytest.mark.skipif(sys.platform != "darwin", reason="Only for MacOS, as it needs test dylib")
class DereferenceTest(unittest.TestCase):

    def setUp(self):
        global Car, car
        load_dylib('testlib.dylib', usr_path=False)
        Car = autoclass('Car')
        car = Car.alloc().init()

    def test_dereference_basic(self):
        rng_ptr = car.makeRangePtr()
        rng = dereference(rng_ptr)
        self.assertEqual(rng.location, 567)
        self.assertEqual(rng.length, 123)

    def test_dereference_with_type(self):
        int_ptr = car.makeIntVoidPtr()
        int_val = dereference(int_ptr, of_type=ObjcInt)
        self.assertEqual(int_val, 12345)

    def test_dereference_selector_void_ptr(self):
        # dereferencing a void* as a selector must produce a usable ObjcSelector
        sel_ptr = car.makeSelectorVoidPtr()
        sel = dereference(sel_ptr, of_type=ObjcSelector)
        self.assertIsInstance(sel, ObjcSelector)
        self.assertTrue(car.respondsToSelector_(sel))

    def test_selector_pointer(self):
        sel = car.makeSelector()
        self.assertIsInstance(sel, ObjcSelector)
        car.useSelector_(sel)

        sel_ptr = car.makeSelectorPtr()
        self.assertIsInstance(dereference(sel_ptr), ObjcSelector)
        car.useSelectorPtr_(sel_ptr)
        # A selector value is accepted where the method wants SEL*.
        car.useSelectorPtr_(sel)
