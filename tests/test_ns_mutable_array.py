import unittest
from pyobjus import autoclass

NSMutableArray = None
NSString = None
test_array = None
Str = lambda x: NSString.stringWithUTF8String_(x)

class NSMutableArrayTest(unittest.TestCase):

    def setUp(self):
        global NSString, NSMutableArray, test_array
        NSMutableArray = autoclass('NSMutableArray')
        NSString = autoclass('NSString')
        test_array = NSMutableArray.arrayWithObjects_(Str("Some text"), Str("Some other test"), None)

    def test_count(self):
        self.assertEqual(test_array.count(), 2)

    def test_add(self):
        test_array.addObject_(Str("Text of added object"))
        self.assertEqual(test_array.count(), 3)

    def test_remove_object(self):
        ns_string_object = Str("Text of added object")
        test_array.addObject_(ns_string_object)
        test_array.removeObject_(ns_string_object)
        self.assertEqual(test_array.count(), 2)

    def test_remove_at_index(self):
        test_array.addObject_(Str("Text of added object"))
        test_array.removeObjectAtIndex_(0)
        self.assertEqual(test_array.count(), 2)

    def test_return_object(self):
        returned_object = test_array.objectAtIndex_(0)
        self.assertEqual(returned_object.UTF8String(), b'Some text')

    def test_replace(self):
        ns_string_object = Str("Replaced text")
        test_array.replaceObjectAtIndex_withObject_(0, ns_string_object)
        self.assertNotEqual(test_array.objectAtIndex_(0).UTF8String(), 'Some text')
        self.assertEqual(test_array.objectAtIndex_(0).UTF8String(), 'Replaced text')
