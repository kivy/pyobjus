import unittest
from pyobjus import autoclass, objc_py_types as opy, dereference

NSValue = None

class NSValueTest(unittest.TestCase):

    def setUp(self):
        global NSValue
        NSValue = autoclass("NSValue")

    def test_valueWithPoint(self):
        point = opy.NSPoint(10, 20)
        value_point = NSValue.valueWithPoint_(point)
        ret_point = value_point.pointValue()
        self.assertEqual(ret_point.x, 10)
        self.assertEqual(ret_point.y, 20)
        self.assertNotEqual(ret_point.x, 100)

    def test_valueWithSize(self):
        size = opy.NSSize(320, 480)
        value_size = NSValue.valueWithSize_(size)
        ret_size = value_size.sizeValue()
        self.assertEqual(ret_size.width, 320)
        self.assertEqual(ret_size.height, 480)

    def test_valueWithRange(self):
        range = opy.NSRange(5, 10)
        value_range = NSValue.valueWithRange_(range)
        ret_range = value_range.rangeValue()
        self.assertEqual(ret_range.location, 5)
        self.assertEqual(ret_range.length, 10)

    @unittest.skip("Segfault since a long time")
    def test_valueWithRect(self):
        rect = opy.NSRect(opy.NSPoint(3, 5), opy.NSSize(320, 480))
        value_rect = NSValue.valueWithRect_(rect)
        ret_rect = value_rect.rectValue()
        self.assertEqual(ret_rect.origin.x, 3)
        self.assertEqual(ret_rect.origin.y, 5)
        self.assertEqual(ret_rect.size.width, 320)
        self.assertEqual(ret_rect.size.height, 480)

    @unittest.skip("Segfault since a long time")
    def test_objCType(self):
        rect = opy.NSRect(opy.NSPoint(3, 5), opy.NSSize(320, 480))
        value_rect = NSValue.valueWithRect_(rect)
        self.assertEqual(value_rect.objCType(), b"{CGRect={CGPoint=dd}{CGSize=dd}}")

        range = opy.NSRange(5, 10)
        value_range = NSValue.valueWithRange_(range)
        self.assertEqual(value_range.objCType(), b"{_NSRange=QQ}")

    def test_valueWithRangePointer(self):
       range = opy.NSRange(10, 20)
       range_ptr = NSValue.valueWithPointer_(range)
       range_val_ptr = range_ptr.pointerValue()
       range_deref = dereference(range_val_ptr, of_type=opy.NSRange)
       self.assertEqual(range_deref.location, 10)
       self.assertEqual(range_deref.length, 20)

    def test_valueWithRectPointer(self):
        rect = opy.NSRect(opy.NSPoint(3, 5), opy.NSSize(320, 480))
        rct_ptr = NSValue.valueWithPointer_(rect)
        rect_val_ptr = rct_ptr.pointerValue()
        rect_deref = dereference(rect_val_ptr, of_type=opy.NSRect)
        self.assertEqual(rect_deref.origin.x, 3)
        self.assertEqual(rect_deref.origin.y, 5)
        self.assertEqual(rect_deref.size.width, 320)
        self.assertEqual(rect_deref.size.height, 480)
