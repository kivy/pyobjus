"""A @protocol method that raises must not leave the exception set.

Objective-C calls the delegate through forwardInvocation:, so there is no
Python caller to receive the exception. It has to be reported and cleared
there, with a zero/nil return, or it surfaces in the next unrelated call.
"""

import ctypes
import sys
import unittest

import pytest

from objc_msgsend import OBJC, msg_send as _msg_send
from pyobjus import autoclass, convert_py_to_nsobject, protocol
from pyobjus.dylib_manager import INCLUDE, load_framework
from pyobjus.protocols import protocols


pytestmark = pytest.mark.skipif(
    sys.platform != 'darwin', reason='macOS + pyobjus only')


class _RaisingDelegate(object):
    def __init__(self):
        self.fail = True
        self.calls = 0

    @protocol('PyobjusRaiseTest')
    def countForKey_(self, key):
        self.calls += 1
        if self.fail:
            raise ValueError('boom from countForKey_')
        return 7

    @protocol('PyobjusRaiseTest')
    def nameForKey_(self, key):
        self.calls += 1
        if self.fail:
            raise ValueError('boom from nameForKey_')
        return 'name'


class DelegateExceptionsTest(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        if OBJC is None:
            raise unittest.SkipTest('libobjc not found')
        load_framework(INCLUDE.Foundation)
        protocols['PyobjusRaiseTest'] = {
            'countForKey:': ('Q@:@', 'Q@:@'),
            'nameForKey:': ('@@:@', '@@:@'),
        }
        cls.key = autoclass('NSString').alloc().initWithUTF8String_('key')

    @classmethod
    def tearDownClass(cls):
        protocols.pop('PyobjusRaiseTest', None)

    @pytest.fixture(autouse=True)
    def _capsys(self, capsys):
        self.capsys = capsys

    def setUp(self):
        self.delegate = _RaisingDelegate()
        self.target = convert_py_to_nsobject(self.delegate)

    def test_raising_method_returns_zero_and_reports(self):
        val = _msg_send(ctypes.c_ulong, self.target, 'countForKey:', self.key)
        self.assertEqual(val, 0)
        self.assertIn('boom from countForKey_', self.capsys.readouterr().err)

    def test_raising_object_method_returns_nil(self):
        ptr = _msg_send(ctypes.c_void_p, self.target, 'nameForKey:', self.key)
        self.assertFalse(ptr)
        self.assertIn('boom from nameForKey_', self.capsys.readouterr().err)

    def test_next_call_into_delegate_succeeds(self):
        _msg_send(ctypes.c_ulong, self.target, 'countForKey:', self.key)
        self.delegate.fail = False
        val = _msg_send(ctypes.c_ulong, self.target, 'countForKey:', self.key)
        self.assertEqual(val, 7)
        self.assertEqual(self.delegate.calls, 2)


if __name__ == '__main__':
    unittest.main()
