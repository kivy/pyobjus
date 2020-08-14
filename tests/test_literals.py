import unittest
from pyobjus import objc_c, objc_str, objc_i, objc_d, objc_arr, objc_dict, objc_b

class LiteralsTest(unittest.TestCase):

    def test_char(self):
        self.assertEqual(objc_c('I').charValue(), 'I')

    def test_string(self):
        self.assertEqual(objc_str('some string').UTF8String(), b'some string')

    def test_integer(self):
        self.assertEqual(objc_i(123).intValue(), 123)

    def test_double(self):
        self.assertEqual(objc_d(3.14).doubleValue(), 3.14)

    def test_array(self):
        self.assertEqual(objc_arr(objc_i(1), objc_i(2), objc_i(3)).count(), 3)

    def test_dict(self):
        o_dict = objc_dict({'first_key': objc_i(2345), 'second_key': objc_d(4.54)})
        self.assertEqual(o_dict.objectForKey_(objc_str('first_key')).intValue(), 2345)

    def test_bool(self):
        self.assertEqual(objc_b(True).boolValue(), True)
        self.assertEqual(objc_c(False).boolValue(), False)
