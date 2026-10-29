import unittest
from pyobjus import autoclass, selector
from pyobjus.dylib_manager import load_dylib
import pytest
import sys

Car = car = None

@pytest.mark.skipif(sys.platform != "darwin", reason="Only for MacOS, as it needs test dylib")
class UnknownTypesTest(unittest.TestCase):

    def setUp(self):
        global Car, car
        load_dylib('testlib.dylib', usr_path=False)
        Car = autoclass('Car')
        car = Car.alloc().init()

    def test_generatingByMembers(self):
        ret_unknown = car.makeUnknownStr(members=['a', 'b', 'CGRect', 'ustr'])
        self.assertEqual(ret_unknown.ustr.a, 2)
        self.assertEqual(ret_unknown.ustr.b, 4)

    def test_obtainMembers(self):
        member_list = ret_unknown = car.makeUnknownStr(members=['a', 'b', 'CGRect', 'ustr']).getMembers(only_fields=True)
        self.assertEqual(member_list, ['a', 'b', 'CGRect', 'ustr'])

    def test_generatingUnknownType(self):
        ret_unknown = car.makeUnknownStr()
        self.assertEqual(ret_unknown.a, 10)
        self.assertEqual(ret_unknown.CGRect.origin.x, 20)
        self.assertEqual(ret_unknown.CGRect.origin.y, 30)

    def test_members_and_use_as_argument(self):
        ret_unknown = car.makeUnknownStr(
            members=['first', 'second', 'struct_field', 'tmp_field'])
        members = ret_unknown.getMembers()
        self.assertEqual(
            [name for name, _typ in members],
            ['first', 'second', 'struct_field', 'tmp_field'])
        self.assertEqual(
            ret_unknown.getMembers(only_types=True),
            [typ for _name, typ in members])
        car.useUnknownStr_(ret_unknown)

    def test_usingIMP(self):
        imp = car.methodForSelector_(selector('getSumOf:and:'))
        self.assertEqual(car.useImp_withA_andB_(imp, 5, 7), 12)
        imp = car.getImp()
        self.assertEqual(car.useImp_withA_andB_(imp, 10, 12), 22)
