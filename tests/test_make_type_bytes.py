"""
Regression tests for the bytes/str mismatch in Factory.make_type.

On Python 3, signature_types_to_list returns bytes items (e.g. b'd'), but the
`types` dict in objc_py_types has str keys ('d').  Pre-registered structs
(CGRect, NSRange, …) never hit make_type, so this was invisible until a
non-pre-registered struct such as UIEdgeInsets was used.

See: https://github.com/kivy/pyobjus/issues/148
"""
import ctypes
import sys
import unittest

import pytest


@pytest.mark.skipif(sys.platform != "darwin", reason="Only for macOS")
class TestMakeTypeBytesDecode(unittest.TestCase):

    def setUp(self):
        from pyobjus.objc_py_types import Factory
        self.factory = Factory()

    # --- auto-generated field names (exercises line that was KeyError) -------

    def test_double_fields_bytes_encoding(self):
        """4-double struct (UIEdgeInsets shape) must not raise KeyError(b'd')."""
        result = self.factory.make_type([b'TestEdgeInsets', b'dddd'])
        self.assertTrue(issubclass(result, ctypes.Structure))
        field_types = [ft for _, ft in result._fields_]
        self.assertEqual(field_types, [ctypes.c_double] * 4)

    def test_float_fields_bytes_encoding(self):
        """2-float struct must not raise KeyError(b'f')."""
        result = self.factory.make_type([b'TestFloatPair', b'ff'])
        self.assertTrue(issubclass(result, ctypes.Structure))
        field_types = [ft for _, ft in result._fields_]
        self.assertEqual(field_types, [ctypes.c_float] * 2)

    def test_mixed_primitive_fields_bytes_encoding(self):
        """int + float struct exercises multiple type-dict lookups with bytes."""
        result = self.factory.make_type([b'TestIntFloat', b'if'])
        self.assertTrue(issubclass(result, ctypes.Structure))
        field_types = [ft for _, ft in result._fields_]
        self.assertEqual(field_types, [ctypes.c_int, ctypes.c_float])

    def test_all_primitive_types_bytes_encoding(self):
        """Every entry in the types dict must be reachable with a bytes key."""
        from pyobjus.objc_py_types import types as type_map
        for char, expected_ctype in type_map.items():
            with self.subTest(type_char=char):
                enc = char.encode("ascii")
                result = self.factory.make_type([b'TestSingle_' + enc, enc])
                self.assertTrue(issubclass(result, ctypes.Structure))
                field_types = [ft for _, ft in result._fields_]
                self.assertEqual(field_types, [expected_ctype])

    # --- explicit member names (exercises the else branch with field_name set) -

    def test_named_double_fields_bytes_encoding(self):
        """Explicit member names must work with bytes type encoding."""
        result = self.factory.make_type(
            [b'TestEdgeInsetsNamed', b'dddd'],
            members=['top', 'left', 'bottom', 'right'],
        )
        self.assertTrue(issubclass(result, ctypes.Structure))
        self.assertEqual(
            [(fn, ft) for fn, ft in result._fields_],
            [('top', ctypes.c_double), ('left', ctypes.c_double),
             ('bottom', ctypes.c_double), ('right', ctypes.c_double)],
        )

    def test_named_mixed_fields_bytes_encoding(self):
        """Named int + float fields with bytes encoding."""
        result = self.factory.make_type(
            [b'TestPoint2D', b'ff'],
            members=['x', 'y'],
        )
        self.assertTrue(issubclass(result, ctypes.Structure))
        self.assertEqual(
            [(fn, ft) for fn, ft in result._fields_],
            [('x', ctypes.c_float), ('y', ctypes.c_float)],
        )

    # --- nested structs (the nested member's encoding is bytes too) ----------

    def test_nested_named_struct(self):
        """A named nested struct becomes a field named after its type."""
        result = self.factory.make_type([b'TestOuter', b'{TestInner=di}fd'])
        self.assertEqual([fn for fn, _ in result._fields_], ['TestInner', 'a', 'b'])
        inner = result._fields_[0][1]
        self.assertEqual([ft for _, ft in inner._fields_], [ctypes.c_double, ctypes.c_int])

        class Inner(ctypes.Structure):
            _fields_ = [('a', ctypes.c_double), ('b', ctypes.c_int)]

        class Outer(ctypes.Structure):
            _fields_ = [('inner', Inner), ('c', ctypes.c_float), ('d', ctypes.c_double)]

        self.assertEqual(ctypes.sizeof(result), ctypes.sizeof(Outer))

    def test_nested_anonymous_structs(self):
        """Anonymous nested structs ({?=...}) get distinct generated names."""
        result = self.factory.make_type([b'?', b'{?=qiIq}{?=qiIq}'])
        names = [fn for fn, _ in result._fields_]
        self.assertEqual(len(set(names)), 2)
        self.assertEqual(ctypes.sizeof(result), 48)

    def test_nested_registered_struct(self):
        """A registered nested struct (CGPoint) reuses the registered type."""
        from pyobjus.objc_py_types import NSPoint
        result = self.factory.make_type([b'TestWithPoint', b'{CGPoint=dd}d'])
        self.assertIs(result._fields_[0][1], NSPoint)
        self.assertEqual(ctypes.sizeof(result), 24)
