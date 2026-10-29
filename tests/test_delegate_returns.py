"""@protocol methods can return values to Objective-C via forwardInvocation:."""

import contextlib
import ctypes
import io
import platform
import sys
import unittest
from unittest import mock

import pytest

from objc_msgsend import OBJC, msg_send as _msg_send
from pyobjus import (
    autoclass, convert_py_to_nsobject, objc_str, protocol)
from pyobjus.dylib_manager import INCLUDE, load_framework
from pyobjus.protocols import protocols


pytestmark = pytest.mark.skipif(
    sys.platform != 'darwin', reason='macOS + pyobjus only')


def _restore_protocol(name, mapping):
    if mapping is None:
        protocols.pop(name, None)
    else:
        protocols[name] = mapping


def _poison_table_height_encoding(test_case):
    """Temporarily install a stale float encoding for NSTableViewDelegate."""
    original = protocols.get('NSTableViewDelegate')
    poisoned = dict(original or {})
    poisoned['tableView:heightOfRow:'] = (
        'f16@0:4@8i12', 'f32@0:8@16i24')
    protocols['NSTableViewDelegate'] = poisoned
    test_case.addCleanup(_restore_protocol, 'NSTableViewDelegate', original)


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
    def doubleConstNameForKey_(self, key):
        # ObjC qualifiers (here r and n) must still resolve to object return.
        self.log.append('double-const-name')
        return objc_str('icon.png')

    @protocol('PyobjusReturnTest')
    def consumePointer_(self, ptr):
        self.log.append(('pointer', ptr))
        return None

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
    def offsetForKey_(self, key):
        self.log.append('offset')
        return -1

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

    @protocol('PyobjusReturnTest')
    def delegateForKey_(self, key):
        # A Python delegate, converted through the wrapper in delegate_register.
        return self

    @protocol('PyobjusReturnTest')
    def copyWithZone_(self, zone):
        self.copy = objc_str('a copy long enough not to be a tagged pointer')
        return self.copy

    @protocol('PyobjusReturnTest')
    def runBlock_(self, block):
        self.log.append(('block', block))

    @protocol('PyobjusReturnTest')
    def badCountForKey_(self, key):
        return 'invalid'  # int() fails

    @protocol('PyobjusReturnTest')
    def badNameForKey_(self, key):
        return object()  # not convertible, and not a delegate

    def helper(self):
        pass


def _retain_count(obj):
    return _msg_send(ctypes.c_ulong, obj, 'retainCount')


def _new_pool():
    OBJC.objc_getClass.restype = ctypes.c_void_p
    OBJC.objc_getClass.argtypes = [ctypes.c_char_p]
    pool_cls = OBJC.objc_getClass(b'NSAutoreleasePool')
    return _msg_send(ctypes.c_void_p, _msg_send(ctypes.c_void_p, pool_cls, 'alloc'), 'init')


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
            'doubleConstNameForKey:': ('rn@@:@', 'rn@@:@'),
            'consumePointer:': ('v@:^i', 'v24@0:8^i16'),
            'flagForKey:': ('B@:@', 'B@:@'),
            'charForKey:': ('c@:@', 'c@:@'),
            'ucharForKey:': ('C@:@', 'C@:@'),
            'countForKey:': ('Q@:@', 'Q@:@'),
            'offsetForKey:': ('q@:@', 'q@:@'),
            'floatForKey:': ('f@:@', 'f@:@'),
            'doubleForKey:': ('d@:@', 'd@:@'),
            'voidForKey:': ('v@:@', 'v@:@'),
            'delegateForKey:': ('@@:@', '@@:@'),
            'copyWithZone:': ('@@:^{_NSZone=}', '@@:^{_NSZone=}'),
            'runBlock:': ('v@:@?', 'v@:@?'),
            'badCountForKey:': ('q@:@', 'q@:@'),
            'badNameForKey:': ('@@:@', '@@:@'),
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

    def test_msgsend_double_const_qualified_string_return(self):
        ptr = _msg_send(
            ctypes.c_void_p, self.target, 'doubleConstNameForKey:', self.key)
        self.assertIn('double-const-name', self.delegate.log)
        self.assertTrue(
            ptr, 'double-qualified NSString return was NULL')
        length = _msg_send(ctypes.c_ulong, ptr, 'length')
        self.assertEqual(length, len('icon.png'))

    def test_pointer_argument_preserves_pointee_type(self):
        value = ctypes.c_int(42)
        ptr = ctypes.cast(ctypes.pointer(value), ctypes.c_void_p)
        _msg_send(None, self.target, 'consumePointer:', ptr)
        entries = [e for e in self.delegate.log if e[0] == 'pointer']
        self.assertEqual(len(entries), 1)
        ref = entries[0][1]
        self.assertEqual(ref.of_type, b'i')

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

    def test_msgsend_negative_int_return(self):
        val = _msg_send(
            ctypes.c_longlong, self.target, 'offsetForKey:', self.key)
        self.assertIn('offset', self.delegate.log)
        self.assertEqual(val, -1)

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
        _msg_send(None, self.target, 'voidForKey:', self.key)
        self.assertIn('void', self.delegate.log)

    def test_returning_a_python_delegate_keeps_it_alive(self):
        # The returned wrapper lives in delegate_register and owns its
        # reference; the +0 handoff must retain before it autoreleases.
        # Extra retains keep the object alive if the count does drop, so a
        # bug fails the assertion instead of crashing the test process.
        for _ in range(3):
            _msg_send(ctypes.c_void_p, self.target, 'retain')
        before = _retain_count(self.target)
        pool = _new_pool()
        for _ in range(3):
            ptr = _msg_send(
                ctypes.c_void_p, self.target, 'delegateForKey:', self.key)
            self.assertEqual(ptr, self.target.get_address())
        _msg_send(None, pool, 'drain')
        self.assertEqual(_retain_count(self.target), before)

    def test_copy_family_returns_retained_object(self):
        # copyWithZone: hands the caller a +1 object, which the caller
        # releases; an autoreleased return would then be over-released.
        pool = _new_pool()
        ptr = _msg_send(ctypes.c_void_p, self.target, 'copyWithZone:', None)
        self.assertEqual(ptr, self.delegate.copy.get_address())
        for _ in range(2):
            _msg_send(ctypes.c_void_p, ptr, 'retain')  # keep alive on a bug
        _msg_send(None, ptr, 'release')  # the caller's release of its copy
        _msg_send(None, pool, 'drain')
        # the two test retains and the Python wrapper's own retain remain
        self.assertEqual(_retain_count(ptr), 3)

    def test_block_argument_reaches_python(self):
        _msg_send(None, self.target, 'runBlock:', None)
        self.assertEqual(self.delegate.log, [('block', None)])

    def test_unconvertible_return_is_zero(self):
        # The conversion raises inside a noexcept function; the return
        # buffer is undefined unless it was set, so it must come back 0/nil.
        # The error must be reported from inside the function, not escape as
        # an "unraisable" exception, which would mean it exited early.
        unraisable = []
        with mock.patch.object(sys, 'unraisablehook', unraisable.append), \
                contextlib.redirect_stderr(io.StringIO()) as err:
            count = _msg_send(
                ctypes.c_longlong, self.target, 'badCountForKey:', self.key)
            name = _msg_send(
                ctypes.c_void_p, self.target, 'badNameForKey:', self.key)
        self.assertEqual(count, 0)
        self.assertIsNone(name)
        self.assertEqual(unraisable, [])
        self.assertIn("invalid literal for int()", err.getvalue())

    def test_responds_to_selector_returns_bool(self):
        # objc_msgSend ignores the registered encoding, so check it directly:
        # callers that build an NSInvocation from it need the platform's BOOL
        # encoding (signed char on x86_64, bool on arm64).
        OBJC.objc_getClass.restype = ctypes.c_void_p
        OBJC.objc_getClass.argtypes = [ctypes.c_char_p]
        OBJC.object_getClass.restype = ctypes.c_void_p
        OBJC.object_getClass.argtypes = [ctypes.c_void_p]
        OBJC.class_getInstanceMethod.restype = ctypes.c_void_p
        OBJC.class_getInstanceMethod.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
        OBJC.method_getTypeEncoding.restype = ctypes.c_char_p
        OBJC.method_getTypeEncoding.argtypes = [ctypes.c_void_p]
        selector = OBJC.sel_registerName(b'respondsToSelector:')
        method = OBJC.class_getInstanceMethod(
            OBJC.object_getClass(self.target.get_address()), selector)
        superclass_method = OBJC.class_getInstanceMethod(
            OBJC.objc_getClass(b'NSObject'), selector)
        self.assertEqual(
            OBJC.method_getTypeEncoding(method),
            OBJC.method_getTypeEncoding(superclass_method))

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

    def test_responds_to_selector_ignores_non_protocol_methods(self):
        # methodSignatureForSelector: has no signature for a method without
        # @protocol, so claiming it would make the call fail.
        sel_helper = OBJC.sel_registerName(b'helper')
        self.assertEqual(
            _msg_send(
                ctypes.c_ubyte, self.target, 'respondsToSelector:',
                sel_helper),
            0)
        self.assertFalse(_msg_send(
            ctypes.c_void_p, self.target, 'methodSignatureForSelector:',
            sel_helper))

    def test_class_methods_have_responds_and_signature(self):
        # NSObject methods are real methods of the delegate class; callers
        # that check respondsToSelector: then build an NSInvocation need both.
        # BOOL is bool on arm64 and signed char on x86_64.
        bool_type = b'B' if platform.machine() == 'arm64' else b'c'
        for name, return_type in ((b'description', b'@'),
                                  (b'isKindOfClass:', bool_type)):
            sel = OBJC.sel_registerName(name)
            self.assertEqual(
                _msg_send(
                    ctypes.c_ubyte, self.target, 'respondsToSelector:', sel),
                1, name)
            sig = _msg_send(
                ctypes.c_void_p, self.target, 'methodSignatureForSelector:',
                sel)
            self.assertTrue(sig, name)
            self.assertEqual(
                _msg_send(ctypes.c_char_p, sig, 'methodReturnType'),
                return_type)

    def test_method_signature_unknown_selector_is_null(self):
        # ObjC may still ask for a signature; must return nil, not raise.
        sel_missing = OBJC.sel_registerName(b'noSuchMethod:')
        sig = _msg_send(
            ctypes.c_void_p, self.target, 'methodSignatureForSelector:',
            sel_missing)
        self.assertFalse(sig)


class CleanTypeSpecifierTest(unittest.TestCase):

    def test_strips_every_leading_qualifier(self):
        from pyobjus.pyobjus import clean_type_specifier
        self.assertEqual(clean_type_specifier(b'rn@'), b'@')
        self.assertEqual(clean_type_specifier('r*'), b'*')
        self.assertEqual(clean_type_specifier(b'r'), b'')
        self.assertEqual(clean_type_specifier(b''), b'')


class SelectorReturnsRetainedTest(unittest.TestCase):

    def test_method_families(self):
        from pyobjus.pyobjus import selector_returns_retained
        for sel in (b'copy', b'copyWithZone:', b'mutableCopyWithZone:',
                    b'newObject', b'alloc', b'initWithName:', '_init'):
            self.assertTrue(selector_returns_retained(sel), sel)
        for sel in (b'copyright', b'newspaper:', b'initialize', b'nameForKey:'):
            self.assertFalse(selector_returns_retained(sel), sel)


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

    def test_msgsend_table_height_returns_double(self):
        # Even if the static table says float, a loaded AppKit protocol must
        # make heightOfRow: return a double to the caller.
        _poison_table_height_encoding(self)

        delegate = _TableHeightDelegate()
        target = convert_py_to_nsobject(delegate)
        sel = OBJC.sel_registerName(b'tableView:heightOfRow:')
        fn = ctypes.CFUNCTYPE(
            ctypes.c_double,
            ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_longlong)(
                ('objc_msgSend', OBJC))
        val = fn(target.get_address(), sel, None, 0)
        self.assertAlmostEqual(val, 42.5, places=10)

    def test_signature_cache_refreshes_when_encoding_changes(self):
        # Simulate a delegate that cached a stale float signature; runtime
        # lookup should rebuild it as double once AppKit is loaded.
        delegate = _TableHeightDelegate()
        target = convert_py_to_nsobject(delegate)
        stale = 'f32@0:8@16i24'
        NSMethodSignature = autoclass('NSMethodSignature')
        setattr(
            delegate,
            '_sig_tableView:heightOfRow:',
            NSMethodSignature.signatureWithObjCTypes_(stale))
        setattr(delegate, '_sigenc_tableView:heightOfRow:', stale)

        sel = OBJC.sel_registerName(b'tableView:heightOfRow:')
        sig = _msg_send(
            ctypes.c_void_p, target, 'methodSignatureForSelector:', sel)
        self.assertTrue(sig)

        fresh_enc = getattr(delegate, '_sigenc_tableView:heightOfRow:')
        if isinstance(fresh_enc, bytes):
            fresh_enc = fresh_enc.decode('utf8')
        self.assertTrue(
            fresh_enc.startswith('d'),
            'expected refreshed signature encoding to start with d, got %r'
            % fresh_enc)


if __name__ == '__main__':
    unittest.main()
