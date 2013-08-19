import ctypes
from pyobjus import autoclass, dereference, CArray, CArrayCount
from pyobjus.dylib_manager import load_dylib

load_dylib('CArrayTestlib.dylib', usr_path=False)

CArrayTestlib = autoclass("CArrayTestlib")

_instance = CArrayTestlib.alloc()

nums = [0, 2, 1, 5, 4, 3, 6, 7, 8, 9]
array = (ctypes.c_int * 10)(*nums)

_instance.setIntValues_(array)  #Do not forget for _ to signify no. of arguments
_instance.printIntValues()


returned_PyList = dereference(_instance.getIntValues(), of_type=CArray, return_count=10)
print returned_PyList

#int_ptr = ctypes.POINTER(ctypes.c_uint32)
#count = ctypes.c_uint32(5)
#count = ctypes.c_uint32(1337)
#returned_PyList_withCount = _instance.getIntValuesWithCount_(CArrayCount)
ref_obj = _instance.getIntValuesWithCount_(CArrayCount)
returned_PyList_withCount = dereference(ref_obj, of_type=CArray)
print returned_PyList_withCount

#for item in ref_obj.reference_return_values:
#    if type(item) == CArrayCount:
#        print item.value