import ctypes
from pyobjus import autoclass, selector, dereference, CArray, CArrayCount
from pyobjus.dylib_manager import load_dylib


load_dylib('CArrayTestlib.dylib', usr_path=False)

CArrayTestlib = autoclass("CArrayTestlib")

_instance = CArrayTestlib.alloc()


################################# INT ARRAY ####################################################
# Objective-C method signatures:
# - (void) setIntValues: (int[10]) val_arr;
# - (int*) getIntValues;
# - (void) printIntValues;
# - (int*) getIntValuesWithCount: (unsigned int*) n;

nums = [0, 2, 1, 5, 4, 3, 6, 7, 8, 9]  # we can set values with Python List(nums) or CArray style(array)
array = (ctypes.c_int * 10)(*nums)  # this is optional, another way of passing carray to pyobjus
_instance.setIntValues_(array)  #Do not forget for _ to signify no. of arguments
#_instance.printIntValues()
returned_PyList = dereference(_instance.getIntValues(), of_type=CArray, return_count=10)
print returned_PyList 
# If method returns values/ArrayCount over reference and you don't provide CArrayCount 
# on the right position in the method signature, you will get "IndexError: tuple index out of range" 
# or segmentation fault, so don't forget to provide CArrayCount on the right position
returned_PyList_withCount = dereference(_instance.getIntValuesWithCount_(CArrayCount), of_type=CArray)
print returned_PyList_withCount

#################################################################################################


################################## CHAR ARRAY ###################################################
# Objective-C method signatures:
# - (void) setCharValues: (char[10]) val_arr;
# - (char*) getCharValues;
# - (char*) getCharValuesWithCount: (unsigned int*) n;

char_list = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"]
char_cstyle = (ctypes.c_char * 10)(*char_list) # this is optional
print char_cstyle
_instance.setCharValues_(char_list)
chars = _instance.getCharValues()  # no need for derefenrencing it since pyobjus converts it to string type 
print chars
chars_WithCount = _instance.getCharValuesWithCount_(CArrayCount)
print chars_WithCount

#################################################################################################


################################### SHORT ARRAY #################################################
# Objective-C method signatures:
# - (void) setShortValues: (short[10]) val_arr;
# - (short*) getShortValues;
# - (short*) getShortValuesWithCount: (unsigned int*) n;

short_array = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
_instance.setShortValues_(short_array)
returned_shorts = dereference(_instance.getShortValues(), of_type=CArray, return_count=10)
print returned_shorts
returned_shorts_WithCount = dereference(_instance.getShortValuesWithCount_(CArrayCount), of_type=CArray)
print returned_shorts_WithCount

#################################################################################################


################################### LONG ARRAY ##################################################
# Objective-C method signatures:
# - (void) setLongValues: (long[10]) val_arr;
# - (long*) getLongValues;
# - (long*) getLongValuesWithCount: (unsigned int*) n;

long_array = [100, -200, 300, -400, 500, -600, 700, -800, 900, -1000]
_instance.setLongValues_(long_array)
returned_longs = dereference(_instance.getLongValues(), of_type=CArray, return_count=10)
print returned_longs
returned_longs_WithCount = dereference(_instance.getLongValuesWithCount_(CArrayCount), of_type=CArray)
print returned_longs_WithCount

#################################################################################################


#################################### LONG LONG ARRAY ############################################
# Objective-C method signatures:
# - (void) setLongLongValues: (long long[10]) val_arr;
# - (long long*) getLongLongValues;
# - (long long*) getLongLongValuesWithCount: (unsigned int*) n;

_instance.setLongLongValues_(long_array)
returned_longlongs = dereference(_instance.getLongLongValues(), of_type=CArray, return_count=10)
print returned_longlongs
returned_longlongs_WithCount = dereference(_instance.getLongLongValuesWithCount_(CArrayCount), of_type=CArray)
print returned_longlongs_WithCount

#################################################################################################


# ###################################### FLOAT ARRAY ##############################################
# Objective-C method signatures:
# - (void) setFloatValues: (float[10]) val_arr;
# - (float*) getFloatValues;
# - (float*) getFloatValuesWithCount: (unsigned int*) n;

float_array = [1.000000, 2.100000, 3.200000, 4.300000, 5.400000, 6.500000, 7.600000, 8.700000, 9.800000, 10.900000]
_instance.setFloatValues_(float_array)
returned_floats = dereference(_instance.getFloatValues(), of_type=CArray, return_count=10)
print returned_floats  # posible bug in CArray lib, lost precision?
returned_floats_WithCount = dereference(_instance.getFloatValuesWithCount_(CArrayCount), of_type=CArray)
print returned_floats_WithCount

#################################################################################################


###################################### DOUBLE ARRAY #############################################
# Objective-C method signatures:
# - (void) setDoubleValues: (double[10]) val_arr;
# - (double*) getDoubleValues;
# - (double*) getDoubleValuesWithCount: (unsigned int*) n;

_instance.setDoubleValues_(float_array)
returned_doubles = dereference(_instance.getDoubleValues(), of_type=CArray, return_count=10)
print returned_doubles
returned_doubles_WithCount = dereference(_instance.getDoubleValuesWithCount_(CArrayCount), of_type=CArray)
print returned_doubles_WithCount

#################################################################################################


################################# UNSIGNED INT ARRAY ##########################################
# Objective-C method signatures:
# - (void) setUIntValues: (unsigned int[10]) val_arr;
# - (unsigned int*) getUIntValues;
# - (unsigned int*) getUIntValuesWithCount: (unsigned int*) n;

uint_array = nums
_instance.setUIntValues_(uint_array)
returned_uints = dereference(_instance.getUIntValues(), of_type=CArray, return_count=10)
print returned_uints
returned_uints_WithCount = dereference(_instance.getUIntValuesWithCount_(CArrayCount), of_type=CArray)
print returned_uints_WithCount

#################################################################################################


################################## UNSIGNED SHORT ARRAY #########################################
# Objective-C method signatures:
# - (void) setUShortValues: (unsigned short[10]) val_arr;
# - (unsigned short*) getUShortValues;
# - (unsigned short*) getUShortValuesWithCount: (unsigned int*) n;

ushort_array = short_array
_instance.setUShortValues_(ushort_array)
returned_ushorts = dereference(_instance.getUShortValues(), of_type=CArray, return_count=10)
print returned_ushorts
returned_ushorts_WithCount = dereference(_instance.getUShortValuesWithCount_(CArrayCount), of_type=CArray)
print returned_ushorts_WithCount

#################################################################################################


################################## UNSIGNED LONG ARRAY ##########################################
# Objective-C method signatures:
# - (void) setULongValues: (unsigned long[10]) val_arr;
# - (unsigned long*) getULongValues;
# - (unsigned long*) getULongValuesWithCount: (unsigned int*) n;

# If method is accepting unsigned values be carefull that you don't provide array with negative values, 
# otherwise you will get OverflowError
ulong_array = [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000,10000]
_instance.setULongValues_(ulong_array)
returned_ulongs = dereference(_instance.getULongValues(), of_type=CArray, return_count=10)
print returned_ulongs
returned_ulongs_WithCount = dereference(_instance.getULongValuesWithCount_(CArrayCount), of_type=CArray, return_count=10)
print returned_ulongs_WithCount

#################################################################################################


################################ UNSIGNED LONG LONG ARRAY #######################################
# Objective-C method signatures:
# - (void) setULongLongValues: (unsigned long long[10]) val_arr;
# - (unsigned long long*) getULongLongValues;
# - (unsigned long long*) getULongLongValuesWithCount: (unsigned int*) n;

ulonglong_array = ulong_array
_instance.setULongLongValues_(ulonglong_array)
returned_ulonglongs = dereference(_instance.getULongLongValues(), of_type=CArray, return_count=10)
print returned_ulonglongs
returned_ulonglongs_WithCount = dereference(_instance.getULongLongValuesWithCount_(CArrayCount), of_type=CArray)
print returned_ulonglongs_WithCount

#################################################################################################


################################### UNSIGNED CHAR ARRAY #########################################
# Objective-C method signatures:
# - (void) setUCharValues: (unsigned char[10]) val_arr;
# - (unsigned char*) getUCharValues;
# - (unsigned char*) getUCharValuesWithCount: (unsigned int*) n;

uchar_array = char_list
_instance.setUCharValues_(uchar_array)
returned_uchars = _instance.getUCharValues()
print returned_uchars
returned_uchars_WithCount = _instance.getUCharValuesWithCount_(CArrayCount)
print returned_uchars_WithCount

#################################################################################################


##################################### BOOL ARRAY ##########################################
# Objective-C method signatures:
# - (void) setBoolValues: (bool[10]) val_arr;
# - (bool*) getBoolValues;
# - (bool*) getBoolValuesWithCount: (unsigned int*) n;

bool_array = [True, False, True, True, False, True, False, False, True, True]
_instance.setBoolValues_(bool_array)
returned_bools = dereference(_instance.getBoolValues(), of_type=CArray, return_count=10)
print returned_bools
returned_bools_WithCount = dereference(_instance.getBoolValuesWithCount_(CArrayCount), of_type=CArray)
print returned_bools_WithCount

#################################################################################################


################################# SIGNATURE: *, char* ARRAY ####################################
# Objective-C method signatures:
# - (void) setCharPtrValues: (char*[10]) val_arr;
# - (void) printCharPtrValues;
# - (char**) getCharPtrValues;
# - (char**) getCharPtrValuesWithCount: (unsigned int*) n;

char_ptr_array = ["abc1", "abc2", "abc3", "abc4", "abc5", "abc6", "abc7", "abc8", "abc9", "abc10"]
_instance.setCharPtrValues_(char_ptr_array)
returned_chars = dereference(_instance.getCharPtrValues(), of_type=CArray, return_count=10)
print returned_chars
returned_chars_WithCount = dereference(_instance.getCharPtrValuesWithCount_(CArrayCount), of_type=CArray)
print returned_chars_WithCount


############################## SIGNATURE: @, OBJECT ARRAY ######################################
# Objective-C method signatures:
# - (void) setNSNumberValues: (NSNumber *__unsafe_unretained[10]) val_arr;
# - (NSNumber *__unsafe_unretained*) getNSNumberValues;
# - (NSNumber *__unsafe_unretained*) getNSNumberValuesWithCount: (unsigned int*) n;

NSNumber = autoclass("NSNumber")
ns_number_array = list()
for i in xrange(0, 10):
    ns_number_array.append(NSNumber.alloc().initWithInt_(i))
_instance.setNSNumberValues_(ns_number_array)
nsnumber_ptr_array = _instance.getNSNumberValues()
returned_nsnumbers = dereference(nsnumber_ptr_array, of_type=CArray, return_count=10)
for i in xrange(len(returned_nsnumbers)):
    print returned_nsnumbers[i].intValue()

returned_nsnumbers_WithCount = dereference(_instance.getNSNumberValuesWithCount_(CArrayCount), of_type=CArray)
for i in xrange(len(returned_nsnumbers_WithCount)):
    print returned_nsnumbers_WithCount[i].intValue()

#################################################################################################


################################# SIGNATURE: #, CLASS ARRAY #####################################
# Objective-C method signatures:
# - (void) setClassValues: (Class __unsafe_unretained[10]) val_arr;
# - (Class*) getClassValues;
# - (Class*) getClassValuesWithCount: (unsigned int*) n;

nsnumber_class = NSNumber.oclass()
nsnumber_class_array = [nsnumber_class for i in xrange(0, 10)]
_instance.setClassValues_(nsnumber_class_array)
returned_classes = dereference(_instance.getClassValues(), of_type=CArray, return_count=10)
print returned_classes
for i in xrange(len(returned_classes)):
    print NSNumber.isKindOfClass_(returned_classes[i])
returned_classes_WithCount = dereference(_instance.getClassValuesWithCount_(CArrayCount), of_type=CArray)
for i in xrange(len(returned_classes_WithCount)):
    print NSNumber.isKindOfClass_(returned_classes_WithCount[i])

#################################################################################################


################################# SIGNATURE: :, SELECTOR ARRAY ###################################
# Objective-C method signatures:
# - (void) printSelector;
# - (void) setSELValues: (SEL[10]) val_arr;
# - (SEL*) getSELValues;
# - (SEL*) getSELValuesWithCount: (unsigned int*) n;


sel = selector("printSelector")
sel_array = [sel for i in xrange(0, 10)]
print sel_array
_instance.setSELValues_(sel_array)
returned_selectors = dereference(_instance.getSELValues(), of_type=CArray, return_count=10)
print returned_selectors
returned_selectors_WithCount = dereference(_instance.getSELValuesWithCount_(CArrayCount), of_type=CArray)
print returned_selectors_WithCount

# TODO: performSelector example

#################################################################################################


############################# SIGNATURE: [], Multidimensional array #############################
# Objective-C method signatures:
# - (void) set2DIntValues: (int[10][10]) val_arr;
# - (int*) get2DIntValues;
# - (int*) get2DIntValuesWithCount: (unsigned int*) n :(unsigned int*) m;

twoD_array = [
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    [11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
    [21, 22, 23, 24, 25, 26, 27, 28, 29, 30],
    [31, 32, 33, 34, 35, 36, 37, 38, 39, 40],
    [41, 42, 43, 44, 45, 46, 47, 48, 49, 50],
    [51, 52, 53, 54, 55, 56, 57, 58, 59, 60],
    [61, 62, 63, 64, 65, 66, 67, 68, 69, 70],
    [71, 72, 73, 74, 75, 76, 77, 78, 79, 80],
    [81, 82, 83, 84, 85, 86, 87, 88, 89, 90],
    [91, 92, 93, 94, 95, 96, 97, 98, 99, 100]
]

_instance.set2DIntValues_(twoD_array)
returned_2d_list = dereference(_instance.get2DIntValues(), of_type=CArray, partition=[10,10])
print returned_2d_list

# TODO: returned_2d_list_WithCounts

#################################################################################################


########################### SIGNATURE: {}, Struct Array  #######################################
# Objective-C method signatures:
# - (bar) initFooBarStruct: (int) a :(float) b;
# - (void) setFooBarValues: (bar[10]) val_arr;
# - (bar*) getFooBarValues;
# - (bar*) getFooBarValuesWithCount: (unsigned int*) n;

from pyobjus.objc_py_types import NSRect, NSPoint, NSSize

struct_array = [NSRect(NSPoint(300 + i, 500 + i), NSSize(320, 480)) for i in xrange(1, 11)]
print struct_array
_instance.setNSRectValues_(struct_array)
returned_struct_array = dereference(_instance.getNSRectValues(), of_type=CArray, return_count=10)

print returned_struct_array
for item in returned_struct_array:
    print item.origin.x, item.origin.y

#################################################################################################


## Aditional test for floats decimal places
_instance.setFloatValues_(float_array)
returned_floats = dereference(_instance.getFloatValues(), of_type=CArray, return_count=10)
print returned_floats  
returned_floats_WithCount = dereference(_instance.getFloatValuesWithCount_(CArrayCount), of_type=CArray)
print returned_floats_WithCount
