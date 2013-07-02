from ctypes import *

class NSRange(Structure):
    _fields_ = [('location', c_ulonglong), ('length', c_ulonglong)]

class NSPoint(Structure):
    _fields_ = [('x', c_double), ('y', c_double)]

class NSSize(Structure):
    _fields_ = [('width', c_double), ('height', c_double)]

class NSRect(Structure):
    _fields_ = [('origin', NSPoint), ('size', NSSize)]
