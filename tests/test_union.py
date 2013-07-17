import unittest
import os
import ctypes
from pyobjus import autoclass, dereference, objc_py_types as opy

Car = None

class Union(unittest.TestCase):

    def setUp(self):
        # LOADING USER DEFINED CLASS (dylib) FROM /objc_usr_classes/ DIR #
        root_pyobjus = os.path.abspath("../")
        usrlib_dir = root_pyobjus + '/objc_usr_classes/usrlib.dylib'
        ctypes.CDLL(usrlib_dir)
        # -------------------------------------------------------------- #

        global Car
        Car = autoclass('Car')

    def test_dereference(self):
        car = Car.alloc().init()
        union_ptr = car.makeUnionPtr()
        union = dereference(union_ptr)
        self.assertEquals(union.rect.origin.x, 10)
        self.assertEquals(union.rect.origin.y, 30)

    def test_returning_values(self):
        car = Car.alloc().init()
        union_ptr = car.makeUnionPtr()
        union = dereference(union_ptr)
        self.assertEquals(union.rect.origin.x, 10)
        self.assertEquals(union.rect.origin.y, 30)

        union = car.makeUnion()
        self.assertEquals(union.rect.origin.x, 20)
        self.assertEquals(union.rect.origin.y, 40)

    def test_passing_values(self):
        car = Car.alloc().init()
        union_arg = opy.test_un_()
        rect = opy.NSRect(opy.NSPoint(20, 40), opy.NSSize(200, 400))
        union_arg.rect = rect
        self.assertTrue(car.useUnionPtrTest_(union_arg))
