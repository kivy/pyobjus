from libc.stdio cimport printf

cdef class ObjcReferenceToType(object):
    
    cdef public unsigned long long arg_ref
    cdef public char *type

    def __cinit__(self, unsigned long long arg, char *_type):
        self.arg_ref = arg
        self.type = _type

def cast_manager(obj_to_cast, type):
    ''' Function for casting python object of one type, to another (supported type)
    Args: 
        obj_to_cast: Python object which will be casted into some other type
        type: type in which object will be casted

    Returns:
        Casted Python object

    Note:
        It isn't implemented to work OK. Only started implementation!
    '''
    if issubclass(type, ctypes.Structure):
        return ctypes.cast(<unsigned long long>obj_to_cast, ctypes.POINTER(type)).contents

    cdef unsigned long long* ocl_lng_ptr
    if issubclass(type, ObjcClassInstance):
        ocl_lng_ptr = <unsigned long long*><unsigned long long>obj_to_cast
        return convert_to_cy_cls_instance(<id>ocl_lng_ptr)

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
        dprint("UNSUPPORTED DATA TYPE! Program will exit now...", type='e')
        raise SystemExit()

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
    cdef object del_arg_val_ptr = True
    cdef object objc_ref = False

    if by_value:
        by = 'value'
    else:
        if type(arg) is ObjcReferenceToType:
            arg_val_ptr = <unsigned long long*><unsigned long long>ctypes.c_ulonglong(arg.arg_ref).value
            objc_ref = True
        else:
            arg_val_ptr = malloc(size)
        by = 'reference'

    dprint("passing argument {0} by {1}".format(arg, by), type='i')

    # method is accepting char
    if sig == 'c':
        (<char*>val_ptr)[0] = <char>bytes(arg)
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
            dprint('==> Class arg', <ObjcClassInstance>arg)
            ocl = <ObjcClassInstance>arg
            (<Class*>val_ptr)[0] = <Class>ocl.o_cls
        else:
            if not objc_ref:
                ocl = <ObjcClassInstance>arg
                (<Class*>arg_val_ptr)[0] = <Class>ocl.o_cls
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
    
    # method is accepting structure
    elif sig[0] == '{':
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
    # TODO: union
    elif sig[0] == '(':
        pass
    # method is accepting void pointer (void*)
    elif sig[0] == 'v':
        if isinstance(arg, ctypes.Structure):
            (<unsigned long long*>val_ptr)[0] = <unsigned long long>ctypes.addressof(arg)
        elif isinstance(arg, ObjcClassInstance):
            ocl = <ObjcClassInstance>arg
            (<id*>val_ptr)[0] = <id>ocl.o_instance
        elif isinstance(arg, ObjcClass):
            pass
        elif isinstance(arg, ObjcSelector):
            pass
        else:
            # TODO: Add better conversion between types!
            if type(arg) is float:
                (<float*>arg_val_ptr)[0] = <float>arg
            elif type(arg) is int:
                (<int*>arg_val_ptr)[0] = <int>arg
            elif type(arg) is str:
                free(arg_val_ptr)
                arg_val_ptr = NULL
                del_arg_val_ptr = False
                # value is stored on stack (is it?), and we don't need to free this ptr
                arg_val_ptr = <char*>arg
            (<void**>val_ptr)[0] = <void*>arg_val_ptr
        
    # TODO: bit field
    elif sig[0] == 'b':
        pass
    # TODO: unknown type
    elif sig[0] == '?':
        pass
    else:
        (<int*>val_ptr)[0] = 0
    
    if arg_val_ptr != NULL and del_arg_val_ptr:
        free(arg_val_ptr)
        arg_val_ptr = NULL

    return val_ptr
