import unittest
from pyobjus import autoclass, dereference, objc_py_types as opy, ObjcException
from pyobjus.dylib_manager import load_dylib
import pytest
import sys

Car = None

@pytest.mark.skipif(sys.platform != "darwin", reason="Only for MacOS, as it needs test dylib")
class Union(unittest.TestCase):

    def setUp(self):
        load_dylib('testlib.dylib', usr_path=False)
        global Car
        Car = autoclass('Car')

    def test_dereference(self):
        car = Car.alloc().init()
        union_ptr = car.makeUnionPtr()
        union = dereference(union_ptr)
        self.assertEqual(union.rect.origin.x, 10)
        self.assertEqual(union.rect.origin.y, 30)

    def test_returning_values(self):
        car = Car.alloc().init()
        union_ptr = car.makeUnionPtr()
        union = dereference(union_ptr)
        self.assertEqual(union.rect.origin.x, 10)
        self.assertEqual(union.rect.origin.y, 30)

        union = car.makeUnion()
        self.assertEqual(union.rect.origin.x, 20)
        self.assertEqual(union.rect.origin.y, 40)

    def test_passing_values(self):
        car = Car.alloc().init()
        union_arg = opy.test_un_()
        rect = opy.NSRect(opy.NSPoint(20, 40), opy.NSSize(200, 400))
        union_arg.rect = rect
        self.assertTrue(car.useUnionPtrTest_(union_arg))

    def test_passing_union_by_value_raises(self):
        car = Car.alloc().init()
        # The retry reuses the signature the first call failed to prepare.
        for _ in range(2):
            with self.assertRaisesRegex(ObjcException, "unions as arguments by value"):
                car.useUnion_(car.makeUnion())
