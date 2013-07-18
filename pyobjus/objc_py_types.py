import ctypes
import itertools
from ctypes import Structure
from debug import dprint
from pyobjus import signature_types_to_list

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

types = dict(
    i = ctypes.c_int,
    f = ctypes.c_float
)

letter = 26
perm_n = 1
field_name_ind = 0
letters = 'abcdefghijklmnopqrstuvwxyz'
perms = []
cached_unknown_type = []

class Factory(object):

    def _reset_globals(self):
        global letter, perm_n, perms
        letter = 26
        perm_n = 1
        perms = []

    def _generate_variable_name(self):
        global letter, perm_n, letters, perms

        if len(perms) > letter:
            ltr = perms[letter]
            letter += 1
            return ltr
        else:
            perms = [''.join(x) for x in itertools.permutations(letters, perm_n)]
            perm_n += 1
            letter = 0
            return self._generate_variable_name()

    def _resolve_field(self, signature):

        for type in signature:
            yield (self._generate_variable_name(), types[type])

    def make_type(self, obj_type, members=None):

        if obj_type[0] in globals():
            return globals()[obj_type[0]]
        field_list = []
        self._reset_globals()
        class UnknownType(Structure):
            pass

        for type in signature_types_to_list(obj_type[1]):
            field_name = ""
            if members is not None:
                global field_name_ind
                field_name = members[field_name_ind]
                field_name_ind += 1

            if type.find('=') != -1:
                type_obj = type[1:-1].split('=', 1)
                if type_obj[0] == '?':
                    if not field_name:
                        field_name = self._generate_variable_name()
                else:
                    if not field_name:
                        field_name = type_obj[0]
                if members is None:
                    field_list.append((field_name, self.find_object(type_obj)))
                else:
                    field_list.append((field_name, members[field_name_ind:]))
            else:
                if not field_name:
                    field_list.append((self._generate_variable_name(), types[type]))
                else:
                    field_list.append((field_name, types[type]))

        UnknownType._fields_ = field_list

        return UnknownType

    def find_object(self, obj_type, members=None):
        if obj_type[0] in globals():
            return globals()[obj_type[0]]

        elif obj_type[0] == '?':
            #if len(cached_unknown_type):
            #    return cached_unknown_type[0]
            return self.make_type(obj_type, members=members)

        else:
            dprint("UNSUPPORTED DATA TYPE! Program will exit now...", type='e')
            raise SystemExit()

    def empty_cache(self):
        del cached_unknown_type[:]

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
