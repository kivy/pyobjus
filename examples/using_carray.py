import ctypes
from pyobjus import autoclass, dereference, CArray, CArrayCount
from pyobjus.dylib_manager import load_dylib

load_dylib('CArrayTestlib.dylib', usr_path=False)

CArrayTestlib = autoclass("CArrayTestlib")

_instance = CArrayTestlib.alloc()


# int array
nums = [0, 2, 1, 5, 4, 3, 6, 7, 8, 9]  # we can set values with Python List(nums) or CArray style(array)
array = (ctypes.c_int * 10)(*nums)  # this is optional, another way of passing carray to pyobjus
_instance.setIntValues_(array)  #Do not forget for _ to signify no. of arguments
#_instance.printIntValues()
returned_PyList = dereference(_instance.getIntValues(), of_type=CArray, return_count=10)
print returned_PyList 

# If method returns values/ArrayCount over reference and you don't provide CArrayCount on the right position in the method signature,
# you will get "IndexError: tuple index out of range" or segmentation fault, so don't forget to provide CArrayCount on the right position
returned_PyList_withCount = dereference(_instance.getIntValuesWithCount_(CArrayCount), of_type=CArray)
print returned_PyList_withCount


## char array
char_list = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"]
char_cstyle = (ctypes.c_char * 10)(*char_list) # this is optional
print char_cstyle
_instance.setCharValues_(char_list)
chars = _instance.getCharValues()  # no need for derefenrencing it since pyobjus converts it to string type 
print chars
chars_WithCount = _instance.getCharValuesWithCount_(CArrayCount)
print chars_WithCount


## short array
short_array = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
_instance.setShortValues_(short_array)
returned_shorts = dereference(_instance.getShortValues(), of_type=CArray, return_count=10)
print returned_shorts
returned_shorts_WithCount = dereference(_instance.getShortValuesWithCount_(CArrayCount), of_type=CArray)
print returned_shorts_WithCount


## long array
long_array = [100, -200, 300, -400, 500, -600, 700, -800, 900, -1000]
_instance.setLongValues_(long_array)
returned_longs = dereference(_instance.getLongValues(), of_type=CArray, return_count=10)
print returned_longs
returned_longs_WithCount = dereference(_instance.getLongValuesWithCount_(CArrayCount), of_type=CArray)
print returned_longs_WithCount


## long long array
_instance.setLongLongValues_(long_array)
returned_longlongs = dereference(_instance.getLongLongValues(), of_type=CArray, return_count=10)
print returned_longlongs
returned_longlongs_WithCount = dereference(_instance.getLongLongValuesWithCount_(CArrayCount), of_type=CArray)
print returned_longlongs_WithCount


## float array
float_array = [1.0, 2.1, 3.2, 4.3, 5.4, 6.5, 7.6, 8.7, 9.8, 10.9]
_instance.setFloatValues_(float_array)
returned_floats = dereference(_instance.getFloatValues(), of_type=CArray, return_count=10)
print returned_floats  # posible bug in CArray lib, lost precision?
returned_floats_WithCount = dereference(_instance.getFloatValuesWithCount_(CArrayCount), of_type=CArray)
print returned_floats_WithCount


## double array
_instance.setDoubleValues_(float_array)
returned_doubles = dereference(_instance.getFloatValues(), of_type=CArray, return_count=10)
print returned_doubles
returned_doubles_WithCount = dereference(_instance.getFloatValuesWithCount_(CArrayCount), of_type=CArray)
print returned_doubles_WithCount


## unsigned int array
uint_array = nums
_instance.setUIntValues_(uint_array)
returned_uints = dereference(_instance.getUIntValues(), of_type=CArray, return_count=10)
print returned_uints
returned_uints_WithCount = dereference(_instance.getUIntValuesWithCount_(CArrayCount), of_type=CArray)
print returned_uints_WithCount


## unsigned short array
ushort_array = short_array
_instance.setUShortValues_(ushort_array)
returned_ushorts = dereference(_instance.getUShortValues(), of_type=CArray, return_count=10)
print returned_ushorts
returned_ushorts_WithCount = dereference(_instance.getUShortValuesWithCount_(CArrayCount), of_type=CArray)
print returned_ushorts_WithCount

## unsigned long array
# If method is accepting unsigned values be carefull that you don't provide array with negative values, 
# otherwise you will get OverflowError
ulong_array = [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000,10000]
_instance.setULongValues_(ulong_array)
returned_ulongs = dereference(_instance.getULongValues(), of_type=CArray, return_count=10)
print returned_ulongs
returned_ulongs_WithCount = dereference(_instance.getULongValuesWithCount_(CArrayCount), of_type=CArray, return_count=10)
print returned_ulongs_WithCount


## unsigned long long array
ulonglong_array = ulong_array
_instance.setULongLongValues_(ulonglong_array)
returned_ulonglongs = dereference(_instance.getULongLongValues(), of_type=CArray, return_count=10)
print returned_ulonglongs
returned_ulonglongs_WithCount = dereference(_instance.getULongLongValuesWithCount_(CArrayCount), of_type=CArray)
print returned_ulonglongs_WithCount


## unsigned char array
uchar_array = char_list
_instance.setUCharValues_(uchar_array)
returned_uchars = _instance.getUCharValues()
print returned_uchars
returned_uchars_WithCount = _instance.getUCharValuesWithCount_(CArrayCount)
print returned_uchars_WithCount


## bool array
bool_array = [True, False, True, True, False, True, False, False, True, True]
_instance.setBoolValues_(bool_array)
returned_bools = dereference(_instance.getBoolValues(), of_type=CArray, return_count=10)
print returned_bools
returned_bools_WithCount = dereference(_instance.getBoolValuesWithCount_(CArrayCount), of_type=CArray)
print returned_bools_WithCount


## signature: *  # char* array
char_ptr_array = ["abc1", "abc2", "abc3", "abc4", "abc5", "abc6", "abc7", "abc8", "abc9", "abc10"]
_instance.setCharPtrValues_(char_ptr_array)
returned_chars = dereference(_instance.getCharPtrValues(), of_type=CArray, return_count=10)
print returned_chars
returned_chars_WithCount = dereference(_instance.getCharPtrValuesWithCount_(CArrayCount), of_type=CArray)
print returned_chars_WithCount


## signature: @
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

## signature: #
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
## signature: :

## signature: []

## signature: {}

## signature: ()

## signature: bnum

## signature: ^

## signature: ?