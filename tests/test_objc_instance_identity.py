import unittest
from pyobjus import autoclass

NSObject = NSString = NSNumber = NSMutableArray = None


class ObjcInstanceIdentityTest(unittest.TestCase):
    """hash() and ==/!= on ObjcClassInstance.

    Small NSString/NSNumber values are tagged pointers. On arm64 their
    "address" has the high bit set, which does not fit in a Python hash
    (Py_ssize_t).
    """

    def setUp(self):
        global NSObject, NSString, NSNumber, NSMutableArray
        NSObject = autoclass('NSObject')
        NSString = autoclass('NSString')
        NSNumber = autoclass('NSNumber')
        NSMutableArray = autoclass('NSMutableArray')

    def test_objects_as_dict_keys(self):
        key = NSString.stringWithUTF8String_("someKey")
        other = NSString.stringWithUTF8String_("someOtherKey")
        number = NSNumber.numberWithInt_(1)
        plain = NSObject.alloc().init()
        d = {key: 1, other: 2, number: 3, plain: 4}
        self.assertEqual(d[key], 1)
        self.assertEqual(d[other], 2)
        self.assertEqual(d[number], 3)
        self.assertEqual(d[plain], 4)

    def test_same_object_through_two_wrappers(self):
        # objectAtIndex_ returns a new Python wrapper each time for the
        # same underlying Objective-C object
        objects = {"plain": NSObject.alloc().init(),
                   "tagged": NSNumber.numberWithInt_(1)}
        for kind, obj in objects.items():
            with self.subTest(kind):
                array = NSMutableArray.alloc().init()
                array.addObject_(obj)
                first = array.objectAtIndex_(0)
                second = array.objectAtIndex_(0)
                self.assertEqual(first, second)
                self.assertFalse(first != second)
                self.assertEqual(hash(first), hash(second))
                self.assertEqual({first: 1}[second], 1)

    def test_different_objects_are_not_equal(self):
        pairs = {"plain": (NSObject.alloc().init(), NSObject.alloc().init()),
                 "tagged": (NSNumber.numberWithInt_(1), NSNumber.numberWithInt_(2))}
        for kind, (a, b) in pairs.items():
            with self.subTest(kind):
                self.assertNotEqual(a, b)
                self.assertTrue(a != b)
                self.assertFalse(a == b)

    def test_not_equal_to_non_objc_values(self):
        obj = NSObject.alloc().init()
        self.assertFalse(obj == 1)
        self.assertFalse(obj == None)  # noqa: E711
        self.assertTrue(obj != "text")


if __name__ == '__main__':
    unittest.main()
