import sys
import unittest

import pytest

from pyobjus import autoclass, convert_py_to_nsobject

pytestmark = pytest.mark.skipif(
    sys.platform != 'darwin', reason='macOS + pyobjus only')


NSJSONWritingSortedKeys = 2


def as_json(value):
    NSJSONSerialization = autoclass('NSJSONSerialization')
    data = NSJSONSerialization.dataWithJSONObject_options_error_(
        convert_py_to_nsobject(value), NSJSONWritingSortedKeys, None)
    text = autoclass('NSString').alloc().initWithData_encoding_(data, 4)
    result = text.UTF8String()
    return result.decode('utf-8') if isinstance(result, bytes) else result


class PythonToNSNumberTest(unittest.TestCase):
    """Python numbers converted to NSNumber keep their kind and value."""

    def test_only_bools_become_booleans(self):
        self.assertEqual(
            as_json([0, 1, 2, True, False, 0.5, 1.0, 0.0]),
            '[0,1,2,true,false,0.5,1,0]')
        self.assertEqual(as_json({'n': 1, 'b': True}), '{"b":true,"n":1}')
        for value in (0, 1, 0.0, 1.0):
            with self.subTest(value=value):
                self.assertNotEqual(
                    type(convert_py_to_nsobject(value)).__name__,
                    '__NSCFBoolean')

    def test_floats_keep_double_precision(self):
        number = convert_py_to_nsobject(0.1)
        self.assertEqual(number.objCType(), b'd')
        self.assertEqual(number.doubleValue(), 0.1)

    def test_ints_across_the_64_bit_range(self):
        for value in (-2 ** 63, -1, 0, 2 ** 63 - 1):
            with self.subTest(value=value):
                number = convert_py_to_nsobject(value)
                self.assertEqual(number.objCType(), b'q')
                self.assertEqual(number.longLongValue(), value)
        for value in (2 ** 63, 2 ** 64 - 1):
            with self.subTest(value=value):
                number = convert_py_to_nsobject(value)
                self.assertEqual(number.objCType(), b'Q')
                self.assertEqual(number.unsignedLongLongValue(), value)

    def test_ints_beyond_64_bits_raise(self):
        for value in (2 ** 64, -2 ** 63 - 1):
            with self.subTest(value=value):
                with self.assertRaises(OverflowError):
                    convert_py_to_nsobject(value)

    def test_numbers_inside_an_array_argument(self):
        array = autoclass('NSArray').arrayWithObjects_(1, 0.1, True, None)
        self.assertEqual(array.objectAtIndex_(0).objCType(), b'q')
        self.assertEqual(array.objectAtIndex_(1).doubleValue(), 0.1)
        self.assertEqual(array.objectAtIndex_(2).objCType(), b'c')
