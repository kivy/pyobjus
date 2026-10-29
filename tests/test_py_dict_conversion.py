from pyobjus import autoclass, convert_py_to_nsobject, objc_str


def test_convert_py_to_nsobject_keeps_dict_keys():
    d = convert_py_to_nsobject({'first_key': 'first value', 'second_key': 42})
    assert d.count() == 2
    assert d.objectForKey_(objc_str('first_key')).isEqualToString_('first value')
    assert d.objectForKey_(objc_str('second_key')).intValue() == 42


def test_dict_passed_as_objc_argument_keeps_keys():
    NSMutableDictionary = autoclass('NSMutableDictionary')
    d = NSMutableDictionary.alloc().initWithDictionary_({'key': 'value'})
    assert d.objectForKey_(objc_str('key')).isEqualToString_('value')
    assert d.objectForKey_(objc_str('value')) is None
