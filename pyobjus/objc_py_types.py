from ctypes import Structure
import ctypes
from debug import dprint

########## NS STRUCT TYPES ##########

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
            dprint("UNSUPPORTED DATA TYPE! Program will exit now...", type='e')
            raise SystemExit()


########## NS ENUM TYPES ##########

def enum(enum_type, **enums):
    return type(enum_type, (), enums)

NSComparisonResult = enum("NSComparisonResult", NSOrderedAscending=-1, NSOrderedSame=0, NSOrderedDescending=1)

string_encodings = dict(
    NSASCIIStringEncoding = 1,
    NSNEXTSTEPStringEncoding = 2,
    NSJapaneseEUCStringEncoding = 3,
    NSUTF8StringEncoding = 4,
    NSISOLatin1StringEncoding = 5,
    NSSymbolStringEncoding = 6,
    NSNonLossyASCIIStringEncoding = 7,
    NSShiftJISStringEncoding = 8,
    NSISOLatin2StringEncoding = 9,
    NSUnicodeStringEncoding = 10,
    NSWindowsCP1251StringEncoding = 11,
    NSWindowsCP1252StringEncoding = 12,
    NSWindowsCP1253StringEncoding = 13,
    NSWindowsCP1254StringEncoding = 14,
    NSWindowsCP1250StringEncoding = 15,
    NSISO2022JPStringEncoding = 21,
    NSMacOSRomanStringEncoding = 30,
    NSUTF16StringEncoding = 10,
    NSUTF16BigEndianStringEncoding = 0x90000100,
    NSUTF16LittleEndianStringEncoding = 0x94000100,
    NSUTF32StringEncoding = 0x8c000100,
    NSUTF32BigEndianStringEncoding = 0x98000100,
    NSUTF32LittleEndianStringEncoding = 0x9c000100,
    NSProprietaryStringEncoding = 65536
)
NSStringEncoding = enum("NSStringEncoding", **string_encodings)

########## USER DEFINED TYPES ##########

class testUn(ctypes.Union):
    _fields_ = [('a', ctypes.c_ulonglong), ('b', ctypes.c_ulonglong), ('c', ctypes.c_int)]

class test_un_(ctypes.Union):
    _fields_ = [('range', NSRange), ('rect', NSRect), ('d', testUn), ('e', ctypes.c_int), ('f', ctypes.c_int)]
    #_fields_ = [('e', ctypes.c_int), ('f', ctypes.c_int)]
