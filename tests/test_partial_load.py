import unittest
from pyobjus import autoclass

class PartialLoadTest(unittest.TestCase):

    def test_partial_class_methods(self):
        NSString = autoclass('NSString', load_class_methods_dict=['alloc'])
        self.assertRaises(Exception, NSString.stringWithUTF8String_('some string'))

    def test_partial_instance_methods(self):
        NSString = autoclass('NSString', load_instance_methods_dict=['init'])
        self.assertRaises(Exception, NSString.alloc().initWithUTF8String_('some string'))
