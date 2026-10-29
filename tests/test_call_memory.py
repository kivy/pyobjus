import gc
import sys
import unittest

import pytest
from malloc_stats import malloc_bytes_in_use
from pyobjus import autoclass, objc_str, selector
from pyobjus.dylib_manager import load_dylib

CALLS = 5000


def leaked_bytes_per_call(func, calls=CALLS):
    """malloc bytes still in use per call of func() (after a warm up)."""
    for _ in range(100):
        func()
    gc.collect()
    before = malloc_bytes_in_use()
    for _ in range(calls):
        func()
    gc.collect()
    return (malloc_bytes_in_use() - before) / calls


@pytest.mark.skipif(sys.platform != "darwin", reason="Only for MacOS, as it needs malloc statistics")
class CallMemoryTest(unittest.TestCase):
    """The memory allocated to pass arguments to a method must be freed
    whichever way the call ends."""

    def test_call_raising_during_argument_conversion_does_not_leak(self):
        load_dylib('CArrayTestlib.dylib', usr_path=False)
        instance = autoclass("CArrayTestlib").alloc()
        bad = ["ok"] * 9 + [1]  # an int is not a valid char* element

        def call():
            try:
                instance.setCharPtrValues_(bad)
            except TypeError:
                pass

        self.assertLess(leaked_bytes_per_call(call), 8)

    def test_call_returning_its_receiver_does_not_leak(self):
        # -performSelector: returns the receiver here, which takes a
        # different return path than a method returning anything else.
        obj = autoclass("NSObject").alloc().init()
        self_sel = selector("self")

        def returns_receiver():
            obj.performSelector_(self_sel)

        def returns_other():
            obj.isEqual_(obj)

        # both leak the same (unrelated) return buffer; compare them so that
        # only the argument memory of the receiver-returning path remains
        extra = leaked_bytes_per_call(returns_receiver) - leaked_bytes_per_call(returns_other)
        self.assertLess(extra, 8)

    def test_by_reference_args_without_a_value_buffer_do_not_leak(self):
        # A by-reference union, or None for an object pointer (the usual
        # error:None), is passed without the value buffer that by-reference
        # scalars need, so none may be allocated for it.
        load_dylib('testlib.dylib', usr_path=False)
        car = autoclass("Car").alloc().init()
        union = car.makeUnion()
        scanner = autoclass("NSScanner").scannerWithString_(objc_str("hello"))
        word = objc_str("absent")

        def no_reference_arg():
            car.getSumOf_and_(1, 2)

        baseline = leaked_bytes_per_call(no_reference_arg)
        union_extra = leaked_bytes_per_call(
            lambda: car.useUnionPtr_(union)) - baseline
        none_extra = leaked_bytes_per_call(
            lambda: scanner.scanString_intoString_(word, None)) - baseline
        self.assertLess(union_extra, 8)
        self.assertLess(none_extra, 8)


if __name__ == '__main__':
    unittest.main()
