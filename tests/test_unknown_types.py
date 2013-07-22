import unittest
import os
import ctypes
from pyobjus import autoclass, selector

Car = car = None

class UnknownTypesTest(unittest.TestCase):

    def setUp(self):
        # LOADING USER DEFINED CLASS (dylib) FROM /objc_usr_classes/ DIR #
        root_pyobjus = os.path.abspath("../")
        usrlib_dir = root_pyobjus + '/objc_usr_classes/usrlib.dylib'
        ctypes.CDLL(usrlib_dir)
        # -------------------------------------------------------------- #

        global Car, car
        Car = autoclass('Car')
        car = Car.alloc().init()

    def test_generatingByMembers(self):
        ret_unknown = car.makeUnknownStr(members=['a', 'b', 'CGRect', 'ustr'])
        self.assertEquals(ret_unknown.ustr.a, 2)
        self.assertEquals(ret_unknown.ustr.b, 4)

    def test_obtainMembers(self):
        member_list = ret_unknown = car.makeUnknownStr(members=['a', 'b', 'CGRect', 'ustr']).getMembers(only_fields=True)
        self.assertEquals(member_list, ['a', 'b', 'CGRect', 'ustr'])

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
