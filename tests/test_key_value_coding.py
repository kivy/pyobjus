import unittest

from pyobjus import autoclass, objc_arr


class KeyValueCodingTest(unittest.TestCase):

    def test_set_and_get_a_value_for_a_key(self):
        d = autoclass('NSMutableDictionary').alloc().init()
        d.setValue_forKey_(42, 'answer')
        self.assertEqual(d.valueForKey_('answer').intValue(), 42)
        self.assertIsNone(d.valueForKey_('missing'))

    def test_key_path_through_a_nested_object(self):
        inner = autoclass('NSMutableDictionary').alloc().init()
        inner.setValue_forKey_(7, 'leaf')
        outer = autoclass('NSMutableDictionary').alloc().init()
        outer.setValue_forKey_(inner, 'branch')
        self.assertEqual(outer.valueForKeyPath_('branch.leaf').intValue(), 7)

    def test_collection_operators(self):
        numbers = objc_arr(1, 2, 3)
        self.assertEqual(numbers.valueForKeyPath_('@sum.self').intValue(), 6)
        self.assertEqual(numbers.valueForKeyPath_('@max.self').intValue(), 3)
        self.assertEqual(numbers.valueForKeyPath_('@count').intValue(), 3)


if __name__ == '__main__':
    unittest.main()
