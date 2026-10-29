"""
Regression tests for a method that is called again while its arguments are
being converted.

ObjcMethod keeps its prepared libffi call (f_cif, f_arg_types) on the method
object. Converting a Python list argument calls NSArray's initWithObjects: for
it, so passing [[1, 2]] calls the same initWithObjects: again from inside the
outer call's argument loop. The inner call has a different number of variadic
arguments and re-prepared the shared call, and the outer call then ran with
the inner call's argument count, reading past the end of its own f_args.

The normal allocator usually hides the overread, so a run crashed roughly half
the time. The second test runs the conversions under Guard Malloc, which places
each block against an unmapped page and turns the overread into a crash.
"""
import sys
import textwrap
import unittest

import pytest

from guard_malloc import assert_ran_ok, requires_guard_malloc, run_script

NESTED_LISTS = textwrap.dedent("""
    from pyobjus import convert_py_to_nsobject

    # Inner call has more arguments than the outer one.
    outer = convert_py_to_nsobject([[1, 2]])
    assert outer.count() == 1
    assert outer.objectAtIndex_(0).count() == 2

    # Inner call has fewer arguments than the outer one.
    outer = convert_py_to_nsobject([[1], 2, 3])
    assert outer.count() == 3
    assert outer.objectAtIndex_(0).count() == 1
    assert outer.objectAtIndex_(2).intValue() == 3
    print("ok")
""")


@pytest.mark.skipif(sys.platform != 'darwin', reason='macOS + pyobjus only')
class ReentrantCallTest(unittest.TestCase):

    def test_nested_lists_convert(self):
        assert_ran_ok(self, run_script(NESTED_LISTS))

    @requires_guard_malloc
    def test_nested_lists_stay_in_bounds(self):
        assert_ran_ok(self, run_script(NESTED_LISTS, guard_malloc=True))
