from ctypes import Structure
import ctypes

class NSRange(Structure):
    _fields_ = [('location', ctypes.c_ulonglong), ('length', ctypes.c_ulonglong)]

class _NSRange(NSRange):
    pass

class CGRange(NSRange):
    pass

class NSPoint(Structure):
    _fields_ = [('x', ctypes.c_double), ('y', ctypes.c_double)]

class CGPoint(NSPoint):
    pass

class NSSize(Structure):
    _fields_ = [('width', ctypes.c_double), ('height', ctypes.c_double)]

class CGSize(NSSize):
    pass

class NSRect(Structure):
    _fields_ = [('origin', NSPoint), ('size', NSSize)]

class CGRect(NSRect):
    pass

class Factory(object):

    def find_object(self, type_name):
        try:
            return globals()[type_name]
        except:
            return None
