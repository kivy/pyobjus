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

See: https://github.com/kivy/pyobjus/issues/90
"""
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
