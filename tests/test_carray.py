import unittest
from pyobjus import autoclass, dereference, CArray
from pyobjus.objc_py_types import NSRect, NSPoint, NSSize
from pyobjus.dylib_manager import load_dylib
import ctypes
import pytest

num_list = [0, 2, 1, 5, 4, 3, 6, 7, 8, 9]
char_list = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"]
short_array = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
long_array = [100, -200, 300, -400, 500, -600, 700, -800, 900, -1000]
float_array = [1.0, 2.1, 3.2, 4.3, 5.4, 6.5, 7.6, 8.7, 9.8, 10.9]
ulong_array = [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000,10000]
bool_array = [True, False, True, True, False, True, False, False, True, True]
twoD_array = [
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    [11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
    [21, 22, 23, 24, 25, 26, 27, 28, 29, 30],
    [31, 32, 33, 34, 35, 36, 37, 38, 39, 40],
    [41, 42, 43, 44, 45, 46, 47, 48, 49, 50],
    [51, 52, 53, 54, 55, 56, 57, 58, 59, 60],
    [61, 62, 63, 64, 65, 66, 67, 68, 69, 70],
    [71, 72, 73, 74, 75, 76, 77, 78, 79, 80],
    [81, 82, 83, 84, 85, 86, 87, 88, 89, 90],
    [91, 92, 93, 94, 95, 96, 97, 98, 99, 100]
]

_instance = None

class CArrayTest(unittest.TestCase):

    def setUp(self):
        global _instance
        load_dylib('CArrayTestlib.dylib', usr_path=False)
        CArrayTestlib = autoclass("CArrayTestlib")
        _instance = CArrayTestlib.alloc()

    def test_carray_int(self):
        count = ctypes.c_uint32(0)
        _instance.setIntValues_(num_list)
        returned_PyList = dereference(
            _instance.getIntValues(),
            of_type=CArray, return_count=10)
        returned_PyList_withCount = dereference(
            _instance.getIntValuesWithCount_(count),
            of_type=CArray, return_count=count)
        self.assertEqual(returned_PyList, num_list)
        self.assertEqual(returned_PyList_withCount, num_list)

    def test_carray_char(self):
        count = ctypes.c_uint32(0)
        _instance.setCharValues_(char_list)
        chars = _instance.getCharValues()
        chars_WithCount = _instance.getCharValuesWithCount_(count)
        self.assertEqual(chars_WithCount, chars)

    def test_carray_short(self):
        count = ctypes.c_uint32(0)
        _instance.setShortValues_(short_array)
        returned_shorts = dereference(
            _instance.getShortValues(),
            of_type=CArray, return_count=10)
        returned_shorts_WithCount = dereference(
            _instance.getShortValuesWithCount_(count),
            of_type=CArray, return_count=count)
        self.assertEqual(returned_shorts, short_array)
        self.assertEqual(returned_shorts_WithCount, short_array)

    def test_carray_long(self):
        count = ctypes.c_uint32(0)
        _instance.setLongValues_(long_array)
        returned_longs = dereference(
            _instance.getLongValues(),
            of_type=CArray, return_count=10)
        returned_longs_WithCount = dereference(
            _instance.getLongValuesWithCount_(count),
            of_type=CArray, return_count=count)
        self.assertEqual(returned_longs, long_array)
        self.assertEqual(returned_longs_WithCount, long_array)

    def test_carray_longlong(self):
        count = ctypes.c_uint32(0)
        _instance.setLongLongValues_(long_array)
        returned_longlongs = dereference(
            _instance.getLongLongValues(),
            of_type=CArray, return_count=10)
        returned_longlongs_WithCount = dereference(
            _instance.getLongLongValuesWithCount_(count),
            of_type=CArray, return_count=count)
        self.assertEqual(returned_longlongs, long_array)
        self.assertEqual(returned_longlongs_WithCount, long_array)

    # @unittest.skip("error with floating, need to implement almost")
    def test_carray_float(self):
        count = ctypes.c_uint32(0)
        _instance.setFloatValues_(float_array)
        returned_floats = dereference(
            _instance.getFloatValues(),
            of_type=CArray, return_count=10)
        returned_floats_WithCount = dereference(
            _instance.getFloatValuesWithCount_(count),
            of_type=CArray, return_count=count)
        for x in range(10):
            self.assertTrue(returned_floats[x], pytest.approx(
                float_array[x]))
            self.assertAlmostEqual(
                returned_floats_WithCount[x], pytest.approx(
                float_array[x]))

    def test_carray_double(self):
        count = ctypes.c_uint32(0)
        _instance.setDoubleValues_(float_array)
        returned_doubles = dereference(
            _instance.getDoubleValues(),
            of_type=CArray, return_count=10)
        returned_doubles_WithCount = dereference(
            _instance.getDoubleValuesWithCount_(count),
            of_type=CArray, return_count=count)
        self.assertEqual(returned_doubles, float_array)
        self.assertEqual(returned_doubles_WithCount, float_array)

    def test_carray_uint(self):
        count = ctypes.c_uint32(0)
        uint_array = num_list
        _instance.setUIntValues_(uint_array)
        returned_uints = dereference(
            _instance.getUIntValues(),
            of_type=CArray, return_count=10)
        returned_uints_WithCount = dereference(
            _instance.getUIntValuesWithCount_(count),
            of_type=CArray, return_count=count)
        self.assertEqual(returned_uints, uint_array)
        self.assertEqual(returned_uints_WithCount, uint_array)

    def test_carray_ushort(self):
        count = ctypes.c_uint32(0)
        ushort_array = short_array
        _instance.setUShortValues_(ushort_array)
        returned_ushorts = dereference(
            _instance.getUShortValues(),
            of_type=CArray, return_count=10)
        returned_ushorts_WithCount = dereference(
            _instance.getUShortValuesWithCount_(count),
            of_type=CArray, return_count=count)
        self.assertEqual(returned_ushorts, ushort_array)
        self.assertEqual(returned_ushorts_WithCount, ushort_array)

    def test_carray_ulong(self):
        count = ctypes.c_uint32(0)
        _instance.setULongValues_(ulong_array)
        returned_ulongs = dereference(
            _instance.getULongValues(),
            of_type=CArray, return_count=10)
        returned_ulongs_WithCount = dereference(
            _instance.getULongValuesWithCount_(count),
            of_type=CArray, return_count=count)
        self.assertEqual(returned_ulongs, ulong_array)
        self.assertEqual(returned_ulongs_WithCount, ulong_array)

    def test_carray_ulonglong(self):
        count = ctypes.c_uint32(0)
        ulonglong_array = ulong_array
        _instance.setULongLongValues_(ulonglong_array)
        returned_ulonglongs = dereference(
            _instance.getULongLongValues(),
            of_type=CArray, return_count=10)
        returned_ulonglongs_WithCount = dereference(
            _instance.getULongLongValuesWithCount_(count),
            of_type=CArray, return_count=count)
        self.assertEqual(returned_ulonglongs, ulonglong_array)
        self.assertEqual(returned_ulonglongs_WithCount, ulonglong_array)

    def test_carray_uchar(self):
        count = ctypes.c_uint32(0)
        uchar_array = char_list
        _instance.setUCharValues_(uchar_array)
        returned_uchars = _instance.getUCharValues()
        returned_uchars_WithCount = _instance.getUCharValuesWithCount_(count)
        self.assertEqual(returned_uchars.decode("utf8"), "".join(uchar_array))
        self.assertEqual(returned_uchars_WithCount.decode("utf8"), "".join(uchar_array))

    def test_carray_bool(self):
        count = ctypes.c_uint32(0)
        _instance.setBoolValues_(bool_array)
        returned_bools = dereference(
            _instance.getBoolValues(),
            of_type=CArray, return_count=10)
        returned_bools_WithCount = dereference(
            _instance.getBoolValuesWithCount_(count),
            of_type=CArray, return_count=count)
        self.assertEqual(returned_bools, bool_array)
        self.assertEqual(returned_bools_WithCount, bool_array)

    def test_carray_object(self):
        count = ctypes.c_uint32(0)
        NSNumber = autoclass("NSNumber")
        ns_number_array = list()
        for i in range(0, 10):
            ns_number_array.append(NSNumber.alloc().initWithInt_(i))
        py_ints = [i for i in range(0,10)]
        _instance.setNSNumberValues_(ns_number_array)
        nsnumber_ptr_array = _instance.getNSNumberValues()
        returned_nsnumbers = dereference(
            nsnumber_ptr_array, of_type=CArray, return_count=10)
        returned_ints = list()
        for i in range(len(returned_nsnumbers)):
            returned_ints.append(returned_nsnumbers[i].intValue())
        returned_nsnumbers_WithCount = dereference(
            _instance.getNSNumberValuesWithCount_(count),
            of_type=CArray, return_count=count)
        returned_ints_WithCount = list()
        for i in range(len(returned_nsnumbers_WithCount)):
            returned_ints_WithCount.append(returned_nsnumbers_WithCount[i].intValue())
        self.assertEqual(returned_ints, py_ints)
        self.assertEqual(returned_ints_WithCount, py_ints)

    def test_carray_class(self):
        count = ctypes.c_uint32(0)
        NSNumber = autoclass("NSNumber")
        nsnumber_class = NSNumber.oclass()
        nsnumber_class_array = [nsnumber_class for i in range(0, 10)]
        _instance.setClassValues_(nsnumber_class_array)
        returned_classes = dereference(
            _instance.getClassValues(),
            of_type=CArray, return_count=10)
        returned_classes_WithCount = dereference(
            _instance.getClassValuesWithCount_(count),
            of_type=CArray, return_count=count)
        flag = True
        for i in range(len(returned_classes_WithCount)):
            if NSNumber.isKindOfClass_(returned_classes_WithCount[i]) == False:
                flag = False
        self.assertEqual(flag, True)

    def test_carray_multidimensional(self):
        _instance.set2DIntValues_(twoD_array)
        returned_2d_list = dereference(_instance.get2DIntValues(), of_type=CArray, partition=[10,10])
        self.assertEqual(returned_2d_list, twoD_array)

    @unittest.skip("issue with signature that looks invalid, therefore it crash")
    def test_carray_struct(self):
        struct_array = [NSRect(NSPoint(300 + i, 500 + i), NSSize(320, 480)) for i in range(1, 11)]
        _instance.setNSRectValues_(struct_array)
        returned_struct_array = dereference(_instance.getNSRectValues(), of_type=CArray, return_count=10)
        vals = [(300 + i , 500 + i) for i in range(1, 11)]
        ret_vals = list()
        for item in returned_struct_array:
            ret_vals.append((item.origin.x, item.origin.y))
        self.assertEqual(ret_vals, vals)
