from ctypes import *

class NSRange(Structure):
    _fields_ = [('location', c_ulonglong), ('length', c_ulonglong)]
