from libc.stdio cimport printf

cdef class ObjcArgReference(object):
    
    cdef public unsigned long long arg_ref

    def __cinit__(self, unsigned long long arg):
        self.arg_ref = arg

def cast_manager(obj_to_cast, type):
    ''' Function for casting python object of one type, to another (supported type)
    Args: 
        obj_to_cast: Python object which will be casted into some other type
        type: type in which object will be casted

    Returns:
        Casted Python object
    '''
    if issubclass(type, ctypes.Structure):
        return ctypes.cast(<unsigned long long>obj_to_cast, ctypes.POINTER(type)).contents

    cdef unsigned long long* ocl_lng_ptr
    if issubclass(type, ObjcClassInstance):
        ocl_lng_ptr = <unsigned long long*><unsigned long long>obj_to_cast
        return convert_to_cy_cls_instance(<id>ocl_lng_ptr)

cdef void* cast_to_cy(id *py_obj, size_t size, char* type):
    ''' Function for casting Python argument to some Cython type
        TODO: Add docs!
    '''    
    cdef void *val_ptr = malloc(size)

    if str(type) == '_NSRange':
        print "r val ->", <unsigned long long>(py_obj)[0]
        (<CFRange*>val_ptr)[0] = (<CFRange*>py_obj)[0]
    elif str(type) == 'CGPoint':
        (<CGPoint*>val_ptr)[0] = (<CGPoint*>py_obj)[0]
    elif str(type) == 'CGSize':
        (<CGSize*>val_ptr)[0] = (<CGSize*>py_obj)[0]
    elif str(type) == 'CGRect':
        (<CGRect*>val_ptr)[0] = (<CGRect*>py_obj)[0]
    else:
        dprint("UNSUPPORTED STRUCTURE TYPE! Program will exit now...", type='e')
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
    cdef unsigned long long* str_long_ptr
    cdef int *tmp_ptr
    cdef int int_arg
    cdef short short_arg
    cdef long long_arg
    cdef unsigned int uint_arg
    cdef unsigned short ushort_arg
    cdef unsigned long ulong_arg
    cdef unsigned long long *ull_ptr

    if type(arg) is ObjcArgReference:
        ull_ptr = <unsigned long long*><unsigned long long>ctypes.c_ulonglong(arg.arg_ref).value

    if by_value:
        by = 'value'
    else:
        by = 'reference'

    dprint("passing argument {0} by {1}".format(arg, by), type='i')

    # method is accepting char
    if sig == 'c':
        (<char*>val_ptr)[0] = bytes(arg)
    # method is accepting int
    elif sig == 'i':
        if by_value:
            (<int*>val_ptr)[0] = <int> int(arg)
        elif isinstance(arg, ObjcArgReference):
            (<int**>val_ptr)[0] = <int*>ull_ptr
        else:
            int_arg = <int>int(arg)
            (<int**>val_ptr)[0] = &int_arg
    # method is accepting short
    elif sig == 's':
        if by_value:
            (<short*>val_ptr)[0] = <short> int(arg)
        else:
            short_arg = <short>int(arg)
            (<short**>val_ptr)[0] = &short_arg
    # method is accepting long
    elif sig == 'l':
        if by_value:
            (<long*>val_ptr)[0] = <long>long(arg)
        else:
            long_arg = <long>long(arg)
            (<long**>val_ptr)[0] = &long_arg
    # method is accepting long long
    elif sig == 'q':
        (<long long*>val_ptr)[0] = <long long>ctypes.c_longlong(arg).value
    # method is accepting unsigned char
    elif sig == 'C':
        (<unsigned char*>val_ptr)[0] = <unsigned char>bytes(arg)

    # method is accepting unsigned integer
    elif sig == 'I':
        if by_value:
            (<unsigned int*>val_ptr)[0] = <unsigned int>ctypes.c_uint32(arg).value
        else:
            uint_arg = <unsigned int>ctypes.c_uint32(arg).value
            (<unsigned int**>val_ptr)[0] = &uint_arg
    # method is accepting unsigned short
    elif sig == 'S':
        if by_value:
            (<unsigned short*>val_ptr)[0] = <unsigned short>ctypes.c_ushort(arg).value
        else:
            ushort_arg = ctypes.c_ushort(arg).value
            (<unsigned short**>val_ptr)[0] = &ushort_arg
    # method is accepting unsigned long
    elif sig == 'L':
        if by_value:
            (<unsigned long*>val_ptr)[0] = <unsigned long>ctypes.c_ulong(arg).value
        else:
            ulong_arg = <unsigned long>ctypes.c_ulong(arg).value
            (<unsigned long**>val_ptr)[0] = &ulong_arg
    # method is accepting unsigned long long                
    elif sig == 'Q':
        (<unsigned long long*>val_ptr)[0] = <unsigned long long>ctypes.c_ulonglong(arg).value

    # method is accepting float
    elif sig == 'f':
        (<float*>val_ptr)[0] = <float>float(arg)
    # method is accepting double
    elif sig == 'd':
        if by_value:
            (<double*>val_ptr)[0] = <double>ctypes.c_double(arg).value
        elif isinstance(arg, ObjcArgReference):
            (<double**>val_ptr)[0] = <double*>ull_ptr
            
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
        dprint('==> Class arg', <ObjcClassInstance>arg)
        ocl = <ObjcClassInstance>arg
        (<Class*>val_ptr)[0] = <Class>ocl.o_cls
    # method is accepting selector
    elif sig == ":":
        dprint("==> Selector arg", <ObjcSelector>arg)
        osel = <ObjcSelector>arg
        (<id*>val_ptr)[0] = <id>osel.selector
    # TODO: array
    elif sig[0] == '[':
        pass
    
    # method is accepting structure
    elif sig[0] == '{':
        dprint("==> Structure arg", arg)
        arg_type = sig[1:-1].split('=', 1)[0] 
        str_long_ptr = <unsigned long long*><unsigned long long>ctypes.addressof(arg)
        ctypes_struct_cache.append(<unsigned long long>str_long_ptr)
        val_ptr = cast_to_cy(<id*>str_long_ptr, size, arg_type)
    # TODO: union
    elif sig[0] == '(':
        pass
    # method is accepting pointer to type
    elif sig[0] == '^':
        arg_type = sig.split('^', 1)[1]
        if arg_type == 'v':
            if isinstance(arg, ctypes.Structure):
                (<unsigned long long*>val_ptr)[0] = <unsigned long long>ctypes.addressof(arg)
            elif isinstance(arg, ObjcClassInstance):
                ocl = <ObjcClassInstance>arg
                (<id*>val_ptr)[0] = <id>ocl.o_instance
            elif isinstance(arg, ObjcClass):
                pass
            elif isinstance(arg, ObjcSelector):
                pass
    # TODO: bit field
    elif sig[0] == 'b':
        pass
    # TODO: unknown type
    elif sig[0] == '?':
        pass
    else:
        (<int*>val_ptr)[0] = 0

    return val_ptr
