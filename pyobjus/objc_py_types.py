import ctypes
import itertools
from .pyobjus import (
    signature_types_to_list, dprint, NSRect, NSPoint, NSSize, NSRange)

########## NS STRUCT TYPES ##########

types = {
    'c': ctypes.c_char,
    'i': ctypes.c_int,
    's': ctypes.c_short,
    'l': ctypes.c_long,
    'q': ctypes.c_longlong,
    'C': ctypes.c_ubyte,
    'I': ctypes.c_uint,
    'S': ctypes.c_ushort,
    'L': ctypes.c_ulong,
    'Q': ctypes.c_ulonglong,
    'f': ctypes.c_float,
    'd': ctypes.c_double,
    'B': ctypes.c_bool,
    '*': ctypes.c_char_p
}

letters = 'abcdefghijklmnopqrstuvwxyz'

class Factory(object):
    ''' Class for making and returning some of objective c types '''

    field_name_ind = None
    registry = {}

    def __init__(self):
        super(Factory, self).__init__()
        # register defaults classes
        self.registry["NSRect"] = NSRect
        self.registry["NSRange"] = NSRange
        self.registry["NSPoint"] = NSPoint
        self.registry["NSSize"] = NSSize
        self.registry["CCFRange"] = NSRange
        self.registry["_NSRange"] = NSRange
        self.registry["CGPoint"] = NSPoint
        self.registry["CGSize"] = NSSize
        self.registry["CGRect"] = NSRect

    def _generate_variable_name(self, letter, perm_n, perms):
        ''' Helper private method for generating name for field

        Returns:
            Some name (letter/letters)
        '''
        global letters

        if len(perms) > letter:
            ltr = perms[letter]
            letter += 1
            return ltr, letter, perm_n, perms
        else:
            perms = [''.join(x) for x in itertools.permutations(letters, perm_n)]
            perm_n += 1
            letter = 0
            return self._generate_variable_name(letter, perm_n, perms)

    def make_type(self, obj_type, members=None):
        ''' Method for making type from method signature
        Args:
            obj_type: array with two elements, containing info about new type.
                On index 0 is type name, and on index 1 are field types of new type
            members: Optional argument. If it is provided it need to contain info about field names of new type

        Returns:
            UnknownType instance, representing new type
        '''

        if obj_type[0] in globals():
            return globals()[obj_type[0]]

        class UnknownType(ctypes.Structure):
            '''
            Class for representing some unknown type instance
            '''

            def getMembers(self, *args, **kwargs):
                ''' Method for getting members (fields and types) of some unknown type
                Args:
                    only_fields: If this kwarg is set to True, user will get only fields of some unknown type
                    only_types: If this kwarg is set to True, user will get only types of some unknown type

                Returns:
                    Method returns list of unknown type members
                '''
                if True not in kwargs.values():
                    return self._fields_
                if 'only_types' in kwargs:
                    return [ty[1] for ty in self._fields_]
                return [ty[0] for ty in self._fields_]

        self.field_name_ind = 0
        sig_list = signature_types_to_list(obj_type[1])

        letter = 26
        perm_n = 1
        perms = []
        members_cpy = None
        members_keys = []
        field_list = []
        if members is not None and len(members):
            members_cpy = members[:]

            for val in members_cpy:
                if isinstance(val, dict):
                    members_keys.append(val.keys()[0])
                else:
                    members_keys.append(val)

        for _type in sig_list:
            field_name = None
            if members_cpy is not None and len(members_cpy) > self.field_name_ind:
                field_name = members_keys[self.field_name_ind]

            if _type.find(b'=') >= 0:
                type_obj = _type[1:-1].split('=', 1)
                if type_obj[0] == b'?':
                    if not field_name:
                        # TODO: This is temporary solution. Find more efficient solution for this!
                        while True:
                            field_name, letter, perm_n, perms = self._generate_variable_name(letter, perm_n, perms)
                            if field_name not in [x for x, y in field_list]:
                                break
                        members = None
                    else:
                        members = members[self.field_name_ind:-1]
                else:
                    if not field_name:
                        field_name = type_obj[0]
                        members = None
                    else:
                        members = members[self.field_name_ind:-1]

                field_list.append((field_name, self.find_object(type_obj, members=members)))
            else:
                if not field_name:
                    field_name, letter, perm_n, perms = self._generate_variable_name(letter, perm_n, perms)
                    field_list.append((field_name, types[_type]))
                else:
                    field_list.append((field_name, types[_type]))
            self.field_name_ind += 1
        UnknownType._fields_ = field_list
        return UnknownType

    def find_object(self, obj_type, members=None):
        ''' Method for searching for, and returning some objective c type
        Args:
            obj_type: array with two elements, containing info about new type.
                On index 0 is type name, and on index 1 are field types of new type
            members: Optional argument. If it is provided it need to contain info about field names of new type

        Returns:
            Requested type
        '''
        obj_name = obj_type[0]
        if isinstance(obj_name, bytes):
            obj_name = obj_name.decode("utf-8")
        if obj_name in self.registry:
            return self.registry[obj_name]
        if obj_name in globals():
            return globals()[obj_name]
        try:
            if obj_type in types.keys():
                return types[obj_type]
        except TypeError:
            pass
        #if len(cached_unknown_type):
        #    return cached_unknown_type[0]
        return self.make_type(obj_type, members=members)

    def empty_cache(self):
        pass
    #    ''' Method for deleting cache of some unknown type '''
    #    del cached_unknown_type[:]

########## NS ENUM TYPES ##########

def enum(enum_type, **enums):
    return type(enum_type, (), enums)

NSComparisonResult = enum(
    "NSComparisonResult",
    NSOrderedAscending=-1,
    NSOrderedSame=0,
    NSOrderedDescending=1)

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
