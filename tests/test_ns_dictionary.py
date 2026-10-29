import unittest
from pyobjus import autoclass


def _str(text):
    return autoclass('NSString').stringWithUTF8String_(text)


class NSMutableDictionaryTest(unittest.TestCase):

    def test_set_object_and_enumerate(self):
        pairs = [
            (_str("someKey"), _str("some text for NSDictionary")),
            (_str("someOtherKey"), _str("some other text for NSDictionary")),
        ]
        dictionary = autoclass("NSMutableDictionary").dictionaryWithCapacity_(10)
        for key, value in pairs:
            dictionary.setObject_forKey_(value, key)

        self.assertEqual(
            dictionary.objectForKey_(pairs[0][0]).UTF8String(),
            "some text for NSDictionary")

        found = []
        enumerator = dictionary.objectEnumerator()
        obj = enumerator.nextObject()
        while obj:
            found.append(obj.UTF8String())
            obj = enumerator.nextObject()
        self.assertCountEqual(found, [
            "some text for NSDictionary",
            "some other text for NSDictionary",
        ])
