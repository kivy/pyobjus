"""
Regression tests for passing a struct larger than 16 bytes by value.

ObjcMethod.__call__ sized each argument buffer from the argument's ffi_type,
but a struct ffi_type has size 0 until ffi_prep_cif lays it out. The struct
was copied into malloc(0), which Apple's allocator rounds up to 16 bytes, so a
32-byte CGRect overran the heap block. Its origin survived and its size could
be overwritten by the next allocation: a frame that arrived as (x, y, 0, 0) on
some runs and intact on others, and a corrupted heap either way.

The normal allocator usually hides the overrun, so the second test runs the
call under Guard Malloc, which places each block against an unmapped page and
turns the overrun into a crash.

Structs other than CGRect, CGPoint, CGSize and NSRange were also copied as a
single pointer-sized word, so only their first 8 bytes reached Objective-C.
The NSEdgeInsets test covers that path.

The testlib tests cover structs that contain other structs.

See: https://github.com/kivy/pyobjus/issues/90
"""
import ctypes
import sys
import textwrap
import unittest

import pytest

from guard_malloc import assert_ran_ok, requires_guard_malloc, run_script

ROUND_TRIP = textwrap.dedent("""
    from pyobjus import autoclass
    from pyobjus.objc_py_types import NSPoint, NSRect, NSSize

    NSValue = autoclass("NSValue")
    for i in range(50):
        want = (1.5 + i, 2.5, 320.0 + i, 480.0)
        rect = NSRect(NSPoint(want[0], want[1]), NSSize(want[2], want[3]))
        got = NSValue.valueWithRect_(rect).rectValue()
        got = (got.origin.x, got.origin.y, got.size.width, got.size.height)
        assert got == want, (want, got)
    print("ok")
""")


def leaves(struct):
    ''' Yield (parent, field name) for every non-struct field, depth first. '''
    for name, _ in struct._fields_:
        value = getattr(struct, name)
        if isinstance(value, ctypes.Structure):
            yield from leaves(value)
        else:
            yield struct, name


@pytest.mark.skipif(sys.platform != "darwin", reason="Only for macOS")
class TestStructArgByValue(unittest.TestCase):

    def test_rect_round_trips(self):
        from pyobjus import autoclass
        from pyobjus.objc_py_types import NSPoint, NSRect, NSSize

        NSValue = autoclass("NSValue")
        for i in range(1000):
            want = (1.5 + i, 2.5, 320.0 + i, 480.0)
            rect = NSRect(NSPoint(want[0], want[1]), NSSize(want[2], want[3]))
            got = NSValue.valueWithRect_(rect).rectValue()
            got = (got.origin.x, got.origin.y, got.size.width, got.size.height)
            self.assertEqual(got, want)

    def test_unregistered_struct_round_trips(self):
        from pyobjus import autoclass
        from pyobjus.dylib_manager import load_framework, INCLUDE

        class NSEdgeInsets(ctypes.Structure):
            _fields_ = [("top", ctypes.c_double), ("left", ctypes.c_double),
                        ("bottom", ctypes.c_double), ("right", ctypes.c_double)]

        load_framework(INCLUDE.AppKit)
        NSValue = autoclass("NSValue")
        for i in range(100):
            want = (1.5 + i, 2.5, 3.5 + i, 4.5)
            got = NSValue.valueWithEdgeInsets_(NSEdgeInsets(*want)).edgeInsetsValue()
            got = tuple(getattr(got, name) for name, _ in got._fields_)
            self.assertEqual(got, want)

    def test_nested_unregistered_struct_round_trips(self):
        from pyobjus import autoclass
        from pyobjus.dylib_manager import load_dylib

        load_dylib('testlib.dylib', usr_path=False)
        car = autoclass('Car').alloc().init()
        # {?=ii{CGRect=...}{?=fi{CGRect=...}}}: 80 bytes, anonymous structs
        # nested two deep around a registered one.
        sent = type(car.makeUnknownStr())()
        fields = list(leaves(sent))
        for value, (parent, name) in enumerate(fields, start=1):
            setattr(parent, name, value)
        got = car.echoUnknownStr_(sent)
        self.assertEqual(
            [getattr(parent, name) for parent, name in leaves(got)],
            list(range(1, len(fields) + 1)))

    def test_nested_struct_in_float_registers(self):
        from pyobjus import autoclass
        from pyobjus.dylib_manager import load_dylib
        from pyobjus.objc_py_types import NSPoint

        class PointAndZ(ctypes.Structure):
            _fields_ = [("point", NSPoint), ("z", ctypes.c_double)]

        load_dylib('testlib.dylib', usr_path=False)
        car = autoclass('Car').alloc().init()
        # Three doubles, so arm64 passes it in floating-point registers, which
        # libffi only does if the nested CGPoint is described correctly.
        for i in range(100):
            arg = PointAndZ(NSPoint(1.5 + i, 2.5), 4.0 + i)
            self.assertEqual(car.sumPointAndZ_(arg), 8.0 + 2 * i)

    @requires_guard_malloc
    def test_rect_arg_does_not_overrun_heap(self):
        assert_ran_ok(self, run_script(ROUND_TRIP, guard_malloc=True))

    def test_bit_field_struct_arg_raises_clear_error(self):
        from pyobjus import autoclass, ObjcException
        from pyobjus.dylib_manager import load_dylib

        load_dylib('testlib.dylib', usr_path=False)
        car = autoclass('Car').alloc().init()
        # The retry reuses the signature the first call failed to prepare.
        for _ in range(2):
            with self.assertRaisesRegex(ObjcException, "Bit fields aren't supported"):
                car.useBitField_(None)
