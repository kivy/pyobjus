import unittest
from pyobjus import autoclass


class PartialLoadTest(unittest.TestCase):

    def tearDown(self):
        autoclass('NSString', reset_autoclass=True)

    def check_partial_class_methods(self, class_methods):
        NSString = autoclass('NSString', load_class_methods=class_methods)
        self.assertTrue(hasattr(NSString, 'alloc'))
        self.assertFalse(hasattr(NSString, 'stringWithUTF8String_'))

    def check_partial_instance_methods(self, instance_methods):
        source = autoclass('NSString').stringWithUTF8String_('some string')
        NSString = autoclass('NSString', load_class_methods=['alloc'],
                             load_instance_methods=instance_methods)
        instance = NSString.alloc()
        self.assertFalse(hasattr(instance, 'initWithUTF8String_'))
        text = instance.initWithString_(source)
        self.assertEqual(text.UTF8String(), b'some string')

    def test_partial_class_methods_str(self):
        self.check_partial_class_methods(['alloc'])

    def test_partial_class_methods_bytes(self):
        self.check_partial_class_methods([b'alloc'])

    def test_partial_instance_methods_str(self):
        self.check_partial_instance_methods(['init', 'initWithString:', 'UTF8String'])

    def test_partial_instance_methods_bytes(self):
        self.check_partial_instance_methods([b'init', b'initWithString:', b'UTF8String'])

    def test_reset_autoclass_loads_all_methods(self):
        autoclass('NSString', load_class_methods=['alloc'])
        NSString = autoclass('NSString', reset_autoclass=True)
        self.assertTrue(hasattr(NSString, 'stringWithUTF8String_'))
