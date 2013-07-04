from ctypes import Structure
import ctypes
from debug import dprint

class NSRange(Structure):
    _fields_ = [('location', ctypes.c_ulonglong), ('length', ctypes.c_ulonglong)]
CFRange = _NSRange = NSRange

class NSPoint(Structure):
    _fields_ = [('x', ctypes.c_double), ('y', ctypes.c_double)]
CGPoint = NSPoint

class NSSize(Structure):
    _fields_ = [('width', ctypes.c_double), ('height', ctypes.c_double)]
CGSize = NSSize

class NSRect(Structure):
    _fields_ = [('origin', NSPoint), ('size', NSSize)]
CGRect = NSRect

class Factory(object):

    def find_object(self, type_name):
        if type_name in globals():
            return globals()[type_name]
        else:
            dprint("UNSUPPORTED STRUCTURE TYPE! Program will exit now...", type='e')
            raise SystemExit()
