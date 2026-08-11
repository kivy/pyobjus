"""@protocol methods can return values to Objective-C via forwardInvocation:."""

import ctypes
import ctypes.util
import sys
import unittest

import pytest

from pyobjus import (
    autoclass, convert_py_to_nsobject, objc_str, protocol)
from pyobjus.dylib_manager import INCLUDE, load_framework
from pyobjus.protocols import protocols


pytestmark = pytest.mark.skipif(
    sys.platform != 'darwin', reason='macOS + pyobjus only')

_objc_path = ctypes.util.find_library('objc') if sys.platform == 'darwin' else None
OBJC = None
if _objc_path:
    OBJC = ctypes.cdll.LoadLibrary(_objc_path)
    OBJC.sel_registerName.restype = ctypes.c_void_p
    OBJC.sel_registerName.argtypes = [ctypes.c_char_p]


def _msg_send(restype, target, sel_name, *args):
    sel = OBJC.sel_registerName(
        sel_name.encode('utf8') if isinstance(sel_name, str) else sel_name)
    argtypes = [ctypes.c_void_p, ctypes.c_void_p] + [
        ctypes.c_void_p] * len(args)
    fn = ctypes.CFUNCTYPE(restype, *argtypes)(('objc_msgSend', OBJC))
    call_args = [target.get_address() if hasattr(target, 'get_address')
                 else target, sel]
    for a in args:
        call_args.append(a.get_address() if hasattr(a, 'get_address') else a)
    return fn(*call_args)


class _ReturnDelegate(object):
    def __init__(self):
        self.log = []

    @protocol('PyobjusReturnTest')
    def nameForKey_(self, key):
        self.log.append('name')
        return objc_str('icon.png')

    @protocol('PyobjusReturnTest')
    def pyNameForKey_(self, key):
        # Plain Python str → alloc/init NSString; must not CFRetain (leak).
        self.log.append('py-name')
        return 'from-python.png'

    @protocol('PyobjusReturnTest')
    def constNameForKey_(self, key):
        # Encoding uses leading 'r' (const) qualifier — must still forward @.
        self.log.append('const-name')
        return objc_str('icon.png')

    @protocol('PyobjusReturnTest')
    def flagForKey_(self, key):
        self.log.append('flag')
        return True

    @protocol('PyobjusReturnTest')
    def charForKey_(self, key):
        self.log.append('char')
        return 65  # 'A', must not be collapsed to boolean 1

    @protocol('PyobjusReturnTest')
    def ucharForKey_(self, key):
        self.log.append('uchar')
        return 200

    @protocol('PyobjusReturnTest')
    def countForKey_(self, key):
        self.log.append('count')
        return 1

    @protocol('PyobjusReturnTest')
    def floatForKey_(self, key):
        self.log.append('float')
        return 1.5

    @protocol('PyobjusReturnTest')
    def doubleForKey_(self, key):
        self.log.append('double')
        return 2.25

    @protocol('PyobjusReturnTest')
    def voidForKey_(self, key):
        self.log.append('void')


class DelegateReturnsTest(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        if OBJC is None:
            raise unittest.SkipTest('libobjc not found')
        load_framework(INCLUDE.Foundation)
        load_framework(INCLUDE.AppKit)
        protocols['PyobjusReturnTest'] = {
            'nameForKey:': ('@@:@', '@@:@'),
            'pyNameForKey:': ('@@:@', '@@:@'),
            'constNameForKey:': ('r@@:@', 'r@@:@'),
            'flagForKey:': ('B@:@', 'B@:@'),
            'charForKey:': ('c@:@', 'c@:@'),
            'ucharForKey:': ('C@:@', 'C@:@'),
            'countForKey:': ('Q@:@', 'Q@:@'),
            'floatForKey:': ('f@:@', 'f@:@'),
            'doubleForKey:': ('d@:@', 'd@:@'),
            'voidForKey:': ('v@:@', 'v@:@'),
        }
        cls.key = autoclass('NSString').alloc().initWithUTF8String_('key')

    def setUp(self):
        self.delegate = _ReturnDelegate()
        self.target = convert_py_to_nsobject(self.delegate)

    def test_msgsend_string_return(self):
        ptr = _msg_send(
            ctypes.c_void_p, self.target, 'nameForKey:', self.key)
        self.assertIn('name', self.delegate.log)
        self.assertTrue(ptr, 'NSString return was NULL')
        # Prefer length over UTF8String: tagged-pointer NSStrings are fine,
        # and this avoids an extra c_char_p round-trip in the test process.
        length = _msg_send(ctypes.c_ulong, ptr, 'length')
        self.assertEqual(length, len('icon.png'))

    def test_msgsend_python_str_return(self):
        ptr = _msg_send(
            ctypes.c_void_p, self.target, 'pyNameForKey:', self.key)
        self.assertIn('py-name', self.delegate.log)
        self.assertTrue(ptr, 'NSString from Python str was NULL')
        length = _msg_send(ctypes.c_ulong, ptr, 'length')
        self.assertEqual(length, len('from-python.png'))

    def test_msgsend_const_qualified_string_return(self):
        ptr = _msg_send(
            ctypes.c_void_p, self.target, 'constNameForKey:', self.key)
        self.assertIn('const-name', self.delegate.log)
        self.assertTrue(
            ptr, 'const-qualified NSString return was NULL (qualifier strip?)')
        length = _msg_send(ctypes.c_ulong, ptr, 'length')
        self.assertEqual(length, len('icon.png'))

    def test_msgsend_bool_return(self):
        val = _msg_send(
            ctypes.c_ubyte, self.target, 'flagForKey:', self.key)
        self.assertIn('flag', self.delegate.log)
        self.assertEqual(val, 1)

    def test_msgsend_char_return(self):
        val = _msg_send(
            ctypes.c_byte, self.target, 'charForKey:', self.key)
        self.assertIn('char', self.delegate.log)
        self.assertEqual(val, 65)

    def test_msgsend_uchar_return(self):
        val = _msg_send(
            ctypes.c_ubyte, self.target, 'ucharForKey:', self.key)
        self.assertIn('uchar', self.delegate.log)
        self.assertEqual(val, 200)

    def test_msgsend_uint_return(self):
        val = _msg_send(
            ctypes.c_ulong, self.target, 'countForKey:', self.key)
        self.assertIn('count', self.delegate.log)
        self.assertEqual(val, 1)

    def test_msgsend_float_return(self):
        val = _msg_send(
            ctypes.c_float, self.target, 'floatForKey:', self.key)
        self.assertIn('float', self.delegate.log)
        self.assertAlmostEqual(val, 1.5, places=5)

    def test_msgsend_double_return(self):
        val = _msg_send(
            ctypes.c_double, self.target, 'doubleForKey:', self.key)
        self.assertIn('double', self.delegate.log)
        self.assertAlmostEqual(val, 2.25, places=10)

    def test_msgsend_void_return(self):
        _msg_send(ctypes.c_void_p, self.target, 'voidForKey:', self.key)
        self.assertIn('void', self.delegate.log)

    def test_responds_to_selector_returns_bool(self):
        sel_name = OBJC.sel_registerName(b'nameForKey:')
        sel_missing = OBJC.sel_registerName(b'noSuchMethod:')
        self.assertEqual(
            _msg_send(
                ctypes.c_ubyte, self.target, 'respondsToSelector:', sel_name),
            1)
        self.assertEqual(
            _msg_send(
                ctypes.c_ubyte, self.target, 'respondsToSelector:',
                sel_missing),
            0)

    def test_method_signature_unknown_selector_is_null(self):
        # ObjC may still ask for a signature; must return nil, not raise.
        sel_missing = OBJC.sel_registerName(b'noSuchMethod:')
        sig = _msg_send(
            ctypes.c_void_p, self.target, 'methodSignatureForSelector:',
            sel_missing)
        self.assertFalse(sig)


class _TableHeightDelegate(object):
    """NSTableViewDelegate height — CGFloat is double on 64-bit."""

    @protocol('NSTableViewDelegate')
    def tableView_heightOfRow_(self, table_view, row):
        return 42.5


class CGFloatReturnRegressionTest(unittest.TestCase):
    """Stale protocols.py 'f' encodings must not win over runtime 'd' (CGFloat)."""

    @classmethod
    def setUpClass(cls):
        if OBJC is None:
            raise unittest.SkipTest('libobjc not found')
        load_framework(INCLUDE.Foundation)
        load_framework(INCLUDE.AppKit)

    def test_runtime_table_height_encoding_is_double(self):
        from pyobjus.pyobjus import objc_protocol_get_delegates

        # Poison the static fallback; runtime AppKit protocol must still win.
        protocols['NSTableViewDelegate'] = dict(
            protocols.get('NSTableViewDelegate') or {})
        protocols['NSTableViewDelegate']['tableView:heightOfRow:'] = (
            'f16@0:4@8i12', 'f32@0:8@16i24')

        d = objc_protocol_get_delegates('NSTableViewDelegate')
        enc = d['tableView:heightOfRow:'][-1]
        if isinstance(enc, bytes):
            enc = enc.decode('utf8')
        self.assertEqual(
            enc[:1], 'd',
            'expected runtime CGFloat encoding to start with d, got %r' % enc)

    def test_msgsend_table_height_returns_double(self):
        # Even if the static table says float, a loaded AppKit protocol must
        # make heightOfRow: return a double to the caller.
        protocols['NSTableViewDelegate'] = dict(
            protocols.get('NSTableViewDelegate') or {})
        protocols['NSTableViewDelegate']['tableView:heightOfRow:'] = (
            'f16@0:4@8i12', 'f32@0:8@16i24')

        delegate = _TableHeightDelegate()
        target = convert_py_to_nsobject(delegate)
        sel = OBJC.sel_registerName(b'tableView:heightOfRow:')
        fn = ctypes.CFUNCTYPE(
            ctypes.c_double,
            ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_longlong)(
                ('objc_msgSend', OBJC))
        val = fn(target.get_address(), sel, None, 0)
        self.assertAlmostEqual(val, 42.5, places=10)


if __name__ == '__main__':
    unittest.main()
