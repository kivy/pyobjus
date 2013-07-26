from objc_py_types import Factory
from libc.stdio cimport printf

factory = Factory()
ctypes_struct_cache = []

cdef extern from "string.h":
  char *strcpy(char *dest, char *src)

def dereference(py_ptr, **kwargs):
    ''' Function for casting python object of one type, to another (supported type)
    Args: 
        obj_to_cast: Python object which will be casted into some other type
        type: type in which object will be casted

    Returns:
        Casted Python object

    Note:
        All types aren't implemented!
    '''
    if py_ptr is None:
        return None

    cdef unsigned long long *c_addr
    cdef void *struct_res_ptr = NULL

    if isinstance(py_ptr, ObjcReferenceToType):
        c_addr = <unsigned long long*><unsigned long long>py_ptr.arg_ref
    else:
        c_addr = <unsigned long long*><unsigned long long>py_ptr
    
    if 'type' in kwargs:
        type = kwargs['type']
        if issubclass(type, ctypes.Structure) or issubclass(type, ctypes.Union):
            return ctypes.cast(<unsigned long long>c_addr, ctypes.POINTER(type)).contents
        elif issubclass(type, ObjcClassInstance):
            return convert_to_cy_cls_instance(<id>c_addr)
        
        py_ptr.type = type.enc
        # TODO: other types
        # elif issubclass(type, MissingTypes....):
        #    pass
    return convert_cy_ret_to_py(<id*>c_addr, py_ptr.type, py_ptr.size)

cdef void* cast_to_cy_data_type(id *py_obj, size_t size, char* type, by_value=True):
    ''' Function for casting Python data type (struct, union) to some Cython type
    
    Args:
        py_obj: address of Python data type which need to be converted to Cython data type
        size: size in bypes of data type
        type: string containing name of data type
        by_value: boolean value, indicate wheather we need pass data type by value or by reference

    Returns:
        void* to eqvivalent Cython data type
    '''    
    cdef void *val_ptr = malloc(size)

    if str(type) == '_NSRange':
        if by_value:
            (<CFRange*>val_ptr)[0] = (<CFRange*>py_obj)[0]
        else:
            (<CFRange**>val_ptr)[0] = <CFRange*>py_obj

    elif str(type) == 'CGPoint':
        if by_value:
            (<CGPoint*>val_ptr)[0] = (<CGPoint*>py_obj)[0]
        else:
            (<CGPoint**>val_ptr)[0] = <CGPoint*>py_obj

    elif str(type) == 'CGSize':
        if by_value:
            (<CGSize*>val_ptr)[0] = (<CGSize*>py_obj)[0]
        else:
            (<CGSize**>val_ptr)[0] = <CGSize*>py_obj

    elif str(type) == 'CGRect':
        if by_value:
            (<CGRect*>val_ptr)[0] = (<CGRect*>py_obj)[0]
        else:
            (<CGRect**>val_ptr)[0] = <CGRect*>py_obj

    else:
        if by_value:
            (<id*>val_ptr)[0] = (<id*>py_obj)[0]
        else:
            (<id**>val_ptr)[0] = (<id*>py_obj)
        dprint("Possible problems with casting, in pyobjus_conversionx.pxi", type='w')

    return val_ptr

cdef convert_to_cy_cls_instance(id ret_id):
    ''' Function for converting C pointer into Cython ObjcClassInstance type
    Args:
        ret_id: C pointer

    Returns:
        ObjcClassInstance type
    '''    

    cdef ObjcClassInstance cret 
    bret = <bytes><char *>object_getClassName(ret_id)
    dprint(' - object_getClassName(f_result) =', bret)
    if bret == 'nil':
        dprint('<-- returned pointer value:', pr(ret_id), type="w")
        return None
    
    cret = autoclass(bret, new_instance=True)(noinstance=True)
    cret.instanciate_from(ret_id)
    dprint('<-- return object', cret)
    return cret

cdef object convert_cy_ret_to_py(id *f_result, sig, size_t size, members=None, objc_prop=False):

    if f_result is NULL:
        dprint('null pointer in convert_cy_ret_to_py function', type='w')
        return None

    if sig[0][0] in ['(', '{']:
        return_type = sig[1:-1].split('=', 1)

    elif sig == 'c':
        # this should be a char. Most of the time, a BOOL is also
        # implemented as a char. So it's not a string, but just the numeric
        # value of the char.
        return (<int><char>f_result[0])
    elif sig == 'i':
        return (<int>f_result[0])
    elif sig == 's':
        return (<short>f_result[0])
    elif sig == 'l':
        return (<long>f_result[0])
    elif sig == 'q':
        return (<long long>f_result[0])
    elif sig == 'C':
        return (<unsigned char>f_result[0])
    elif sig == 'I':
        return (<unsigned int>f_result[0])
    elif sig == 'S':
        return (<unsigned short>f_result[0])
    elif sig == 'L':
        return (<unsigned long>f_result[0])
    elif sig == 'Q':
        return (<unsigned long long>f_result[0])
    elif sig == 'f':
        return (<float>ctypes.cast(<unsigned long long>f_result, ctypes.POINTER(ctypes.c_float)).contents.value)
    elif sig == 'd':
        return (<double>ctypes.cast(<unsigned long long>f_result, ctypes.POINTER(ctypes.c_double)).contents.value)
    elif sig == 'B':
        if <int>f_result[0]:
            return True
        return False
    elif sig == 'v':
        return None
    elif sig == '*':
        return <bytes>(<char*>f_result[0])
    
    # return type -> id
    if sig == '@':
        return convert_to_cy_cls_instance(<id>f_result[0])
    # return type -> class
    elif sig == '#':
        ocls = ObjcClass()
        ocls.o_cls = <Class>object_getClass(<id>f_result[0])
        return ocls
    # return type -> selector
    elif sig == ':':
        osel = ObjcSelector()
        osel.selector = <SEL>f_result[0]
        return osel
    elif sig[0] == '[':
        # array
        pass

    # return type -> struct OR union
    elif sig[0] in ['(', '{']:
        #NOTE: This need to be tested more! Does this way work in all cases? TODO: Find better solution for this!
        if <long>f_result[0] in ctypes_struct_cache:
            dprint("ctypes struct value found in cache", type='i')
            val = ctypes.cast(<unsigned long long>f_result[0], ctypes.POINTER(factory.find_object(return_type, members=members))).contents
        else:
            val = ctypes.cast(<unsigned long long>f_result, ctypes.POINTER(factory.find_object(return_type, members=members))).contents
        factory.empty_cache()
        return val

    # TODO:  return type -> bit field
    elif sig == 'b':
        raise ObjcException("Bit fields aren't supported in pyobjus!")

    # return type --> pointer to type
    elif sig[0] == '^':
        if objc_prop:
            c_addr = <unsigned long long>f_result
        else:
            c_addr = <unsigned long long>f_result[0]
        
        return ObjcReferenceToType(c_addr, sig.split('^')[1], size)

    # return type --> unknown type
    elif sig == '?':
        # TODO: Check is this possible at all?
        dprint('Returning unknown type by value...')
        assert(0)

    else:
        assert(0)


cdef char convert_py_bool_to_objc(arg):
    ''' Function for converting python bool value (True, False, 0, 1) to objc BOOL type (YES, NO)
    Args:
        arg: argument to convert to objc equivalent bool value

    Returns:
        Returns objective c boolean value (YES or NO)
    '''

    if arg == True or arg == 1:
        return YES
    return NO


cdef void* convert_py_arg_to_cy(arg, sig, by_value, size_t size):
    ''' Function for converting Python argument to Cython, by given method signature
    Args:
        arg: argument to convert
        sig: method signature
        by_value: True or False, are we passing argument by value or by reference
        size: size of argument in memory
        
    Returns:
        Pointer (void*) to converted Cython object
    '''

    cdef void *val_ptr = malloc(size)
    cdef void *arg_val_ptr = NULL
    cdef object del_arg_val_ptr = False
    cdef object objc_ref = False

    if by_value:
        by = 'value'
    else:
        if type(arg) is ObjcReferenceToType:
            arg_val_ptr = <unsigned long long*><unsigned long long>arg.arg_ref
            objc_ref = True
        elif not isinstance(arg, ctypes.Structure):
            arg_val_ptr = malloc(size)
            del_arg_val_ptr = True
        by = 'reference'

    dprint("passing argument {0} by {1}".format(arg, by), type='i')

    # method is accepting char (or BOOL, which is also interpreted as char)
    if sig == 'c':
        if by_value:
            if arg in [True, False, 1, 0]:
                (<char*>val_ptr)[0] = convert_py_bool_to_objc(arg)
            else:
                (<char*>val_ptr)[0] = <char>bytes(arg)
        else:
            if not objc_ref:
                if arg in [True, False, 1, 0]:
                    (<char*>arg_val_ptr)[0] = convert_py_bool_to_objc(arg)
                else:
                    (<char*>arg_val_ptr)[0] = <char>bytes(arg)
            (<char**>val_ptr)[0] = <char*>arg_val_ptr
    # method is accepting int
    elif sig == 'i':
        if by_value:
            (<int*>val_ptr)[0] = <int> int(arg)
        else:
            if not objc_ref:
                (<int*>arg_val_ptr)[0] = <int>int(arg)
            (<int**>val_ptr)[0] = <int*>arg_val_ptr
    # method is accepting short
    elif sig == 's':
        if by_value:
            (<short*>val_ptr)[0] = <short> int(arg)
        else:
            if not objc_ref:
                (<short*>arg_val_ptr)[0] = <short>int(arg)
            (<short**>val_ptr)[0] = <short*>arg_val_ptr
    # method is accepting long
    elif sig == 'l':
        if by_value:
            (<long*>val_ptr)[0] = <long>long(arg)
        else:
            if not objc_ref:
                (<long*>arg_val_ptr)[0] = <long>long(arg)
            (<long**>val_ptr)[0] = <long*>arg_val_ptr
    # method is accepting long long
    elif sig == 'q':
        if by_value:
            (<long long*>val_ptr)[0] = <long long>ctypes.c_longlong(arg).value
        else:
            if not objc_ref:
                (<long long*>arg_val_ptr)[0] = <long long>ctypes.c_ulonglong(arg).value
            (<long long**>val_ptr)[0] = <long long*>arg_val_ptr

    # method is accepting unsigned char
    elif sig == 'C':
        (<unsigned char*>val_ptr)[0] = <unsigned char>arg

    # method is accepting unsigned integer
    elif sig == 'I':
        if by_value:
            (<unsigned int*>val_ptr)[0] = <unsigned int>ctypes.c_uint32(arg).value
        else:
            if not objc_ref:
                (<unsigned int*>arg_val_ptr)[0] = <unsigned int>ctypes.c_uint32(arg).value
            (<unsigned int**>val_ptr)[0] = <unsigned int*>arg_val_ptr
    # method is accepting unsigned short
    elif sig == 'S':
        if by_value:
            (<unsigned short*>val_ptr)[0] = <unsigned short>ctypes.c_ushort(arg).value
        else:
            if not objc_ref:
                (<unsigned short*>arg_val_ptr)[0] = <unsigned short>ctypes.c_ushort(arg).value
            (<unsigned short**>val_ptr)[0] = <unsigned short*>arg_val_ptr
    # method is accepting unsigned long
    elif sig == 'L':
        if by_value:
            (<unsigned long*>val_ptr)[0] = <unsigned long>ctypes.c_ulong(arg).value
        else:
            if not objc_ref:
                (<unsigned long*>arg_val_ptr)[0] = <unsigned long>ctypes.c_ulong(arg).value
            (<unsigned long**>val_ptr)[0] = <unsigned long*>arg_val_ptr
    # method is accepting unsigned long long                
    elif sig == 'Q':
        if by_value:
            (<unsigned long long*>val_ptr)[0] = <unsigned long long>ctypes.c_ulonglong(arg).value
        else:
            if not objc_ref:
                (<unsigned long long*>arg_val_ptr)[0] = <unsigned long long>ctypes.c_ulonglong(arg).value
            (<unsigned long long**>val_ptr)[0] = <unsigned long long*>arg_val_ptr

    # method is accepting float
    elif sig == 'f':
        if by_value:
            (<float*>val_ptr)[0] = <float>float(arg)
        else:
            if not objc_ref:
                (<float*>arg_val_ptr)[0] = <float>float(arg)
            (<float**>val_ptr)[0] = <float*>arg_val_ptr
    # method is accepting double
    elif sig == 'd':
        if by_value:
            (<double*>val_ptr)[0] = <double>ctypes.c_double(arg).value
        else:
            if not objc_ref:
                (<double*>arg_val_ptr)[0] = <double>ctypes.c_double(arg).value
            (<double**>val_ptr)[0] = <double*>arg_val_ptr

    # method is accepting bool
    elif sig == 'B':
        if by_value:
            (<bool*>val_ptr)[0] = <bool>ctypes.c_bool(arg).value
        else:
            if not objc_ref:
                (<bool*>arg_val_ptr)[0] = <bool>ctypes.c_bool(arg).value
            (<bool**>val_ptr)[0] = <bool*>arg_val_ptr

    # method is accepting character string (char *)
    elif sig == '*':
        (<char **>val_ptr)[0] = <char *><bytes>arg
    # method is accepting an object
    elif sig == '@':
        dprint('====> ARG', <ObjcClassInstance>arg)
        if arg == None:
            (<id*>val_ptr)[0] = <id>NULL
        else:
            ocl = <ObjcClassInstance>arg
            (<id*>val_ptr)[0] = <id>ocl.o_instance
    # method is accepting class
    elif sig == '#':
        if by_value:
            dprint('==> Class arg', <ObjcClass>arg)
            ocls = <ObjcClass>arg
            (<Class*>val_ptr)[0] = <Class>ocls.o_cls
        else:
            if not objc_ref:
                ocls = <ObjcClass>arg
                (<Class*>arg_val_ptr)[0] = <Class>ocls.o_cls
            (<Class**>val_ptr)[0] = <Class*>arg_val_ptr
    # method is accepting selector
    elif sig == ":":
        if by_value:
            dprint("==> Selector arg", <ObjcSelector>arg)
            osel = <ObjcSelector>arg
            (<SEL*>val_ptr)[0] = <SEL>osel.selector
        else:
            if not objc_ref:
                osel = <ObjcSelector>arg
                (<SEL*>arg_val_ptr)[0] = <SEL>osel.selector
            (<SEL**>val_ptr)[0] = <SEL*>arg_val_ptr
    # TODO: array
    elif sig[0] == '[':
        pass
    
    # method is accepting structure OR union
    # NOTE: Support for passing union as arguments by value wasn't supported with libffi,
    # in time of writing this version of pyobjus.
    # However we can pass union as argument if function accepts pointer to union type
    # Return types for union are working (both, returned union is value, or returned union is pointer)
    # NOTE: There are no problems with structs, only unions, reason -> libffi
    # TODO: ADD SUPPORT FOR PASSING UNIONS AS ARGUMENTS BY VALUE
    elif sig[0] in ['(', '{']:
        dprint("==> Structure arg", arg)
        arg_type = sig[1:-1].split('=', 1)[0] 
        if by_value:
            str_long_ptr = <unsigned long long*><unsigned long long>ctypes.addressof(arg)
            ctypes_struct_cache.append(<unsigned long long>str_long_ptr)
            val_ptr = cast_to_cy_data_type(<id*>str_long_ptr, size, arg_type)
        else:
            if not objc_ref:
                str_long_ptr = <unsigned long long*><unsigned long long>ctypes.addressof(arg)
                val_ptr = cast_to_cy_data_type(<id*>str_long_ptr, size, arg_type, by_value=False)
            else:
                val_ptr = cast_to_cy_data_type(<id*>arg_val_ptr, size, arg_type, by_value=False)

    # method is accepting void pointer (void*)
    elif sig[0] == 'v':
        if isinstance(arg, ctypes.Structure) or isinstance(arg, ctypes.Union):
            (<void**>val_ptr)[0] = <void*><unsigned long long>ctypes.addressof(arg)
        elif isinstance(arg, ObjcReferenceToType):
            (<unsigned long long**>val_ptr)[0] = <unsigned long long*>arg_val_ptr
        elif isinstance(arg, ObjcClassInstance):
            ocl = <ObjcClassInstance>arg
            (<void**>val_ptr)[0] = <void*>ocl.o_instance
        elif isinstance(arg, ObjcClass):
            ocls = <ObjcClass>arg
            (<void**>val_ptr)[0] = <void*>ocls.o_cls
        elif isinstance(arg, ObjcSelector):
            osel = <ObjcSelector>arg
            (<void**>val_ptr)[0] = <void*>osel.selector
        # TODO: Add other types..
        # elif:
            # ARRAY, ETC.
        else:
            # TODO: Add better conversion between primitive types!
            if type(arg) is float:
                (<float*>arg_val_ptr)[0] = <float>arg
            elif type(arg) is int:
                (<int*>arg_val_ptr)[0] = <int>arg
            elif type(arg) is str:
                strcpy(<char*>arg_val_ptr, <char*>arg)
            (<void**>val_ptr)[0] = <void*>arg_val_ptr
        
    # TODO: method is accepting bit field
    elif sig[0] == 'b':
        raise ObjcException("Bit fields aren't supported in pyobjus!")

    # method is accepting unknown type (^?)
    elif sig[0] == '?':
        if by_value:
            assert(0)
        else:
            (<void**>val_ptr)[0] = arg_val_ptr

    else:
        (<int*>val_ptr)[0] = 0

    # TODO: Find best time to dealloc memory used by this pointer
    #if arg_val_ptr != NULL and del_arg_val_ptr:
    #    free(arg_val_ptr)
    #    arg_val_ptr = NULL

    return val_ptr
