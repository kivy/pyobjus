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

See: https://github.com/kivy/pyobjus/issues/90
"""
import ctypes
import os
import subprocess
import sys
import textwrap
import unittest

import pytest

GUARD_MALLOC = "/usr/lib/libgmalloc.dylib"

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

    @pytest.mark.skipif(not os.path.exists(GUARD_MALLOC),
                        reason="Guard Malloc is not installed")
    def test_rect_arg_does_not_overrun_heap(self):
        env = dict(os.environ, DYLD_INSERT_LIBRARIES=GUARD_MALLOC)
        result = subprocess.run(
            [sys.executable, "-c", ROUND_TRIP],
            env=env, capture_output=True, text=True, timeout=120)
        self.assertEqual(
            result.returncode, 0,
            "exit status {}; stderr:\n{}".format(
                result.returncode, result.stderr[-2000:]))
        self.assertIn("ok", result.stdout)
