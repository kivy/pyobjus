import ctypes
import gc
import unittest
from ctypes import POINTER, byref, c_void_p

from pyobjus import autoclass, objc_str

libobjc = ctypes.CDLL("/usr/lib/libobjc.A.dylib")
for _name, _restype, _argtypes in (
        ("objc_autoreleasePoolPush", c_void_p, []),
        ("objc_autoreleasePoolPop", None, [c_void_p]),
        ("objc_initWeak", c_void_p, [POINTER(c_void_p), c_void_p]),
        ("objc_loadWeakRetained", c_void_p, [POINTER(c_void_p)]),
        ("objc_destroyWeak", None, [POINTER(c_void_p)]),
        ("objc_release", None, [c_void_p])):
    getattr(libobjc, _name).restype = _restype
    getattr(libobjc, _name).argtypes = _argtypes

NSObject = autoclass("NSObject")
NSMutableArray = autoclass("NSMutableArray")
NSString = autoclass("NSString")


def two_item_array():
    array = NSMutableArray.array()
    array.addObject_(NSObject.new())
    array.addObject_(NSObject.new())
    return array


class ObjectLifecycleTest(unittest.TestCase):
    """An Objective-C object is deallocated once its Python wrapper is gone,
    however it was created (see #194)."""

    def assertFreed(self, create):
        weak = c_void_p()
        pool = libobjc.objc_autoreleasePoolPush()
        obj = create()
        libobjc.objc_initWeak(byref(weak), obj.get_address())
        del obj
        # The methods of a class hold the most recently wrapped instance, so
        # wrap another one before checking.
        other = create()
        del other
        gc.collect()
        libobjc.objc_autoreleasePoolPop(pool)
        alive = libobjc.objc_loadWeakRetained(byref(weak))
        if alive:
            libobjc.objc_release(alive)
        libobjc.objc_destroyWeak(byref(weak))
        self.assertFalse(alive, "object outlived its Python wrapper")

    def test_returned_object(self):
        self.assertFreed(lambda: NSMutableArray.array())

    @unittest.expectedFailure
    def test_alloc(self):
        self.assertFreed(lambda: NSObject.alloc())

    @unittest.expectedFailure
    def test_alloc_init(self):
        self.assertFreed(lambda: NSObject.alloc().init())

    @unittest.expectedFailure
    def test_new(self):
        self.assertFreed(lambda: NSObject.new())

    @unittest.expectedFailure
    def test_copy(self):
        self.assertFreed(lambda: two_item_array().copy())

    @unittest.expectedFailure
    def test_mutable_copy(self):
        self.assertFreed(lambda: two_item_array().mutableCopy())

    @unittest.expectedFailure
    def test_init_returning_another_object(self):
        # A class cluster: alloc returns a placeholder, init a new string.
        text = objc_str("long enough not to be a tagged pointer string")
        self.assertFreed(lambda: NSString.alloc().initWithString_(text))

    def test_copy_and_init_return_new_objects(self):
        array = two_item_array()
        self.assertNotEqual(array.copy().get_address(), array.get_address())
        placeholder = NSString.alloc()
        text = objc_str("long enough not to be a tagged pointer string")
        string = placeholder.initWithString_(text)
        self.assertNotEqual(string.get_address(), placeholder.get_address())
