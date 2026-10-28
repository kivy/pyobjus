"""Round-trip each encoding pyobjus claims to support.

One row sends a Python value through testlib (or CArrayTestlib for arrays)
and checks the value that comes back. One failure row sits next to the
successes: too few arguments.
"""
import ctypes
import sys
import unittest

import pytest

from pyobjus import (
    CArray, ObjcException, autoclass, dereference, selector)
from pyobjus.dylib_manager import load_dylib
from pyobjus.objc_py_types import NSPoint, NSRange, NSRect, NSSize


class Bar(ctypes.Structure):
    """struct foo (typedef'd as bar) in CArrayTestlib.h."""
    _fields_ = [("a", ctypes.c_int), ("b", ctypes.c_float)]


# (method, value sent, value expected). Floats are compared approximately.
SCALAR_ECHO = [
    ("echoChar_", "Z", "Z"),
    ("echoInt_", -42, -42),
    ("echoShort_", -300, -300),
    ("echoLong_", 2 ** 31 + 3, 2 ** 31 + 3),
    ("echoLongLong_", 2 ** 40 + 7, 2 ** 40 + 7),
    ("echoUChar_", 200, 200),
    ("echoUInt_", 4000000000, 4000000000),
    ("echoUShort_", 60000, 60000),
    ("echoULong_", 2 ** 33 + 1, 2 ** 33 + 1),
    ("echoULongLong_", 2 ** 40 + 9, 2 ** 40 + 9),
    ("echoFloat_", 1.25, 1.25),
    ("echoDouble_", -2.5, -2.5),
    ("echoBOOL_", True, True),
    ("echoBOOL_", False, False),
    ("echoCharPtr_", b"bridge", b"bridge"),
    ("echoCharPtr_", "bridge", b"bridge"),
]


@pytest.mark.skipif(sys.platform != "darwin", reason="Only for macOS, as it needs test dylib")
class TypeRoundTripTest(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        load_dylib("testlib.dylib", usr_path=False)
        load_dylib("CArrayTestlib.dylib", usr_path=False)
        cls.car = autoclass("Car").alloc().init()
        cls.arrays = autoclass("CArrayTestlib").alloc()

    def assert_echo(self, got, expected):
        if isinstance(expected, float):
            self.assertAlmostEqual(got, expected, places=5)
        else:
            self.assertEqual(got, expected)

    def test_scalar_and_char_ptr_echo(self):
        for method, sent, expected in SCALAR_ECHO:
            with self.subTest(method=method, sent=sent):
                self.assert_echo(getattr(self.car, method)(sent), expected)

    def test_object_selector_and_class(self):
        text = autoclass("NSString").stringWithUTF8String_("round trip")
        self.assertEqual(self.car.echoObject_(text).UTF8String(), b"round trip")
        self.assertIsNone(self.car.echoObject_(None))

        self.assertTrue(self.car.respondsToSelector_(
            self.car.echoSelector_(selector("print"))))
        self.assertFalse(self.car.respondsToSelector_(
            self.car.echoSelector_(selector("notARealMethod"))))

        # +class returns Class. classNameOf: reads that Class back out.
        self.assertEqual(self.car.classNameOf_(autoclass("NSString").oclass()), b"NSString")
        self.assertEqual(self.car.classNameOf_(autoclass("NSArray").oclass()), b"NSArray")

    def test_pointers_including_nil(self):
        self.assertEqual(self.car.readIntPtr_(42), 42)
        # None is a nil object or struct pointer.
        self.assertIsNone(self.car.echoObject_(None))
        self.assertEqual(self.car.readRangePtr_(None), -1)
        self.assertEqual(self.car.readRangePtr_(NSRange(12, 34)), 12)

    def test_struct_large_enough_for_stret(self):
        sent = NSRect(NSPoint(1.5, 2.5), NSSize(320.0, 480.0))
        got = self.car.echoRect_(sent)
        self.assertEqual(
            (got.origin.x, got.origin.y, got.size.width, got.size.height),
            (1.5, 2.5, 320.0, 480.0))

    def test_unregistered_struct_name(self):
        # {pyobjus_size=ii} is not a registered name. make_type builds it.
        sent = type(self.car.makeSize())()
        names = [name for name, _typ in sent._fields_]
        for name, value in zip(names, (8, 9)):
            setattr(sent, name, value)
        got = self.car.echoSize_(sent)
        self.assertEqual(
            [getattr(got, name) for name in names],
            [8, 9])

    def test_arrays(self):
        ints = [0, 2, 1, 5, 4, 3, 6, 7, 8, 9]
        self.arrays.setIntValues_(ints)
        self.assertEqual(
            dereference(self.arrays.getIntValues(), of_type=CArray, return_count=10),
            ints)

        chars = [b"abc%d" % i for i in range(10)]
        self.arrays.setCharPtrValues_(chars)
        self.assertEqual(
            dereference(self.arrays.getCharPtrValues(), of_type=CArray, return_count=10),
            chars)

        structs = [Bar(i, i + 0.5) for i in range(10)]
        self.arrays.setFooBarValues_(structs)
        got = dereference(
            self.arrays.getFooBarValues(), of_type=CArray, return_count=10)
        self.assertEqual([item.a for item in got], [item.a for item in structs])
        for item, sent in zip(got, structs):
            self.assertAlmostEqual(item.b, sent.b, places=5)

    def test_not_enough_arguments(self):
        with self.assertRaisesRegex(ObjcException, "Not enough parameters"):
            self.car.echoInt_()
