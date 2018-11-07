import unittest
from pyobjus import autoclass, selector
from pyobjus.dylib_manager import load_dylib

Car = car = None

class UnknownTypesTest(unittest.TestCase):

    def setUp(self):
        global Car, car
        load_dylib('testlib.dylib', usr_path=False)
        Car = autoclass('Car')
        car = Car.alloc().init()

    @unittest.skip("Segfault, TBF")
    def test_generatingByMembers(self):
        ret_unknown = car.makeUnknownStr(members=['a', 'b', 'CGRect', 'ustr'])
        self.assertEquals(ret_unknown.ustr.a, 2)
        self.assertEquals(ret_unknown.ustr.b, 4)

    @unittest.skip("Segfault, TBF")
    def test_obtainMembers(self):
        member_list = ret_unknown = car.makeUnknownStr(members=['a', 'b', 'CGRect', 'ustr']).getMembers(only_fields=True)
        self.assertEquals(member_list, ['a', 'b', 'CGRect', 'ustr'])

    @unittest.skip("Segfault, TBF")
    def test_generatingUnknownType(self):
        ret_unknown = car.makeUnknownStr()
        self.assertEquals(ret_unknown.a, 10)
        self.assertEquals(ret_unknown.CGRect.origin.x, 20)
        self.assertEquals(ret_unknown.CGRect.origin.y, 30)

    def test_usingIMP(self):
        imp = car.methodForSelector_(selector('getSumOf:and:'))
        self.assertEquals(car.useImp_withA_andB_(imp, 5, 7), 12)
        imp = car.getImp()
        self.assertEquals(car.useImp_withA_andB_(imp, 10, 12), 22)
