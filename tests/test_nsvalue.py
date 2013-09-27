import unittest
from pyobjus import autoclass, objc_py_types as opy, dereference

NSValue = None

class NSString(unittest.TestCase):

    def setUp(self):
        global NSValue
        NSValue = autoclass("NSValue")

    def test_valueWithPoint(self):
        point = opy.NSPoint(10, 20)
        value_point = NSValue.valueWithPoint_(point)
        ret_point = value_point.pointValue()
        self.assertEquals(ret_point.x, 10)
        self.assertEquals(ret_point.y, 20)
        self.assertNotEquals(ret_point.x, 100)

    def test_valueWithSize(self):
        size = opy.NSSize(320, 480)
        value_size = NSValue.valueWithSize_(size)
        ret_size = value_size.sizeValue()
        self.assertEquals(ret_size.width, 320)
        self.assertEquals(ret_size.height, 480)

    def test_valueWithRange(self):
        range = opy.NSRange(5, 10)
        value_range = NSValue.valueWithRange_(range)
        ret_range = value_range.rangeValue()
        self.assertEquals(ret_range.location, 5)
        self.assertEquals(ret_range.length, 10)

    def test_valueWithRect(self):
        rect = opy.NSRect(opy.NSPoint(3, 5), opy.NSSize(320, 480))
        value_rect = NSValue.valueWithRect_(rect)
        ret_rect = value_rect.rectValue()
        self.assertEquals(ret_rect.origin.x, 3)
        self.assertEquals(ret_rect.origin.y, 5)
        self.assertEquals(ret_rect.size.width, 320)
        self.assertEquals(ret_rect.size.height, 480)

    def test_objCType(self):
        rect = opy.NSRect(opy.NSPoint(3, 5), opy.NSSize(320, 480))
        value_rect = NSValue.valueWithRect_(rect)
        self.assertEquals(value_rect.objCType(), "{CGRect={CGPoint=dd}{CGSize=dd}}")

        range = opy.NSRange(5, 10)
        value_range = NSValue.valueWithRange_(range)
        self.assertEquals(value_range.objCType(), "{_NSRange=QQ}")

    def test_valueWithRangePointer(self):
       range = opy.NSRange(10, 20)
       range_ptr = NSValue.valueWithPointer_(range)
       range_val_ptr = range_ptr.pointerValue()
       range_deref = dereference(range_val_ptr, of_type=opy.NSRange)
       self.assertEquals(range_deref.location, 10)
       self.assertEquals(range_deref.length, 20)

    def test_valueWithRectPointer(self):
        rect = opy.NSRect(opy.NSPoint(3, 5), opy.NSSize(320, 480))
        rct_ptr = NSValue.valueWithPointer_(rect)
        rect_val_ptr = rct_ptr.pointerValue()
        rect_deref = dereference(rect_val_ptr, of_type=opy.NSRect)
        self.assertEquals(rect_deref.origin.x, 3)
        self.assertEquals(rect_deref.origin.y, 5)
        self.assertEquals(rect_deref.size.width, 320)
        self.assertEquals(rect_deref.size.height, 480)
