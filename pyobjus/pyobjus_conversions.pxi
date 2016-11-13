from objc_py_types import Factory, NSRect, NSSize, NSPoint
from libc.stdio cimport printf

factory = Factory()
ctypes_struct_cache = []

cdef extern from "string.h":
  char *strcpy(char *dest, char *src)


def partition_array(array, dim):
    chunks = lambda l, n: [l[i:i + n] for i in range(0, len(l), n)]
    sol = chunks(array, dim[len(dim) - 1])
    dim.pop()
    while dim:
        sol = chunks(sol, dim[len(dim) - 1])
        dim.pop()
    return sol[0]


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
    
    if 'of_type' in kwargs:
        of_type = kwargs['of_type']
        if issubclass(of_type, ctypes.Structure) or issubclass(of_type, ctypes.Union):
            return ctypes.cast(<unsigned long long>c_addr, ctypes.POINTER(of_type)).contents
        
        elif issubclass(of_type, ObjcClassInstance):
            return convert_to_cy_cls_instance(<id>c_addr)
        
        elif issubclass(of_type, CArray) and "return_count" in kwargs:
            dprint("Returning CArray from c_addr, size={0}, type={1}".format(kwargs['return_count'], py_ptr.of_type))
            dprint("{}".format(str(py_ptr.of_type)))
            return CArray().get_from_ptr(py_ptr.arg_ref, py_ptr.of_type, kwargs['return_count'])
        
        elif issubclass(of_type, CArray) and "partition" in kwargs:
            partitions = kwargs["partition"]
            total_count = partitions[0]
            for i in xrange(1, len(partitions)):
                total_count *= int(partitions[i])
            
            dprint("Total count for {} is {}".format(partitions, total_count))
            array = CArray().get_from_ptr(py_ptr.arg_ref, py_ptr.of_type, total_count)
            return partition_array(array, partitions)
            
        elif issubclass(of_type, CArray):
            # search for return count in ObjcReferenceToType object
            dprint("Returning CArray, calculating returned value by 'reference'")
            for item in py_ptr.reference_return_values:
                if type(item) == CArrayCount:
                    dprint("CArray().get_from_ptr({0}, {1}, {2})".format(py_ptr.arg_ref, py_ptr.of_type, item.value))
                    return CArray().get_from_ptr(py_ptr.arg_ref, py_ptr.of_type, item.value)
        
        py_ptr.of_type = of_type.enc
        # TODO: other types
        # elif issubclass(type, MissingTypes....):
        #    pass
    return convert_cy_ret_to_py(<id*>c_addr, py_ptr.of_type, py_ptr.size)

cdef void* cast_to_cy_data_type(id *py_obj, size_t size, char* of_type, by_value=True, py_val=None):
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
    cdef CGRect rect
    cdef CGRect *rect_ptr
    cdef CGSize sz
    cdef CGPoint point

    if str(of_type) == '_NSRange':
        if by_value:
            (<CFRange*>val_ptr)[0] = (<CFRange*>py_obj)[0]
        else:
            (<CFRange**>val_ptr)[0] = <CFRange*>py_obj

    elif str(of_type) == 'CGPoint':
        if by_value:
            (<CGPoint*>val_ptr)[0] = (<CGPoint*>py_obj)[0]
        else:
            (<CGPoint**>val_ptr)[0] = <CGPoint*>py_obj

    elif str(of_type) == 'CGSize':
        if by_value:
            (<CGSize*>val_ptr)[0] = (<CGSize*>py_obj)[0]
        else:
            (<CGSize**>val_ptr)[0] = <CGSize*>py_obj

    elif str(of_type) == 'CGRect':
        IF PLATFORM == 'darwin':
            if by_value:
                (<CGRect*>val_ptr)[0] = (<CGRect*>py_obj)[0]
            else:
                (<CGRect**>val_ptr)[0] = <CGRect*>py_obj

        ELIF PLATFORM == 'ios':
            if py_val:
                point.x = py_val.origin.x
                point.y = py_val.origin.y
                sz.width = py_val.size.width
                sz.height = py_val.size.height

            if by_value and py_val:
                rect.origin = point
                rect.size = sz
                (<CGRect*>val_ptr)[0] = rect

            # TODO: find appropriate method and test these cases on iOS
            elif not by_value and py_val:
                rect_ptr = <CGRect*>malloc(sizeof(CGRect))
                rect_ptr.origin = point
                rect_ptr.size = sz
                (<CGRect**>val_ptr)[0] = rect_ptr
            elif not by_value and not py_val: 
                (<CGRect**>val_ptr)[0] = <CGRect*>py_obj

    else:
        if by_value:
            (<id*>val_ptr)[0] = (<id*>py_obj)[0]
        else:
            (<id**>val_ptr)[0] = (<id*>py_obj)
        dprint("Possible problems with casting, in pyobjus_conversionx.pxi", of_type='w')

    return val_ptr

cdef convert_to_cy_cls_instance(id ret_id, main_cls_name=None):
    ''' Function for converting C pointer into Cython ObjcClassInstance type
    Args:
        ret_id: C pointer

    Returns:
        ObjcClassInstance type
    '''
    dprint("convert_to_cy_cls_instance: {0}".format(pr(ret_id)))
    cdef ObjcClassInstance cret 
    bret = <bytes><char *>object_getClassName(ret_id)
    dprint(' - object_getClassName(f_result) =', bret)
    if bret == 'nil':
        dprint('<-- returned pointer value:', pr(ret_id), of_type="w")
        return None

    load_instance_methods = None
    if bret in omethod_partial_register:
        key = bret
    else:
        key = main_cls_name

    if key in omethod_partial_register:
        load_instance_methods = omethod_partial_register[key]
        omethod_partial_register[bret] = load_instance_methods

    cret = autoclass(bret, new_instance=True, load_instance_methods=load_instance_methods)(noinstance=True)
    cret.instanciate_from(ret_id)
    dprint('<-- return object', cret)
    return cret


cdef object convert_cy_ret_to_py(id *f_result, sig, size_t size, members=None, objc_prop=False, main_cls_name=None):

    cdef CGRect rect

    if f_result is NULL:
        dprint('null pointer in convert_cy_ret_to_py function', of_type='w')
        return None

    if sig[0][0] in ['(', '{']:
        return_type = sig[1:-1].split('=', 1)

    elif sig == 'c':
        # this should be a char. Most of the time, a BOOL is also
        # implemented as a char. So it's not a string, but just the numeric
        # value of the char.
        if <int>f_result[0] in [1, 0]:
            return ctypes.c_bool(<int>f_result[0]).value
        return chr(<int><char>f_result[0])
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
        if f_result[0] is not NULL:
            return <bytes>(<char*>f_result[0])
        else:
            return None
    # return type -> id
    if sig == '@':
        return convert_to_cy_cls_instance(<id>f_result[0], main_cls_name)
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
            dprint("ctypes struct value found in cache", of_type='i')
            val = ctypes.cast(<unsigned long long>f_result[0], ctypes.POINTER(factory.find_object(return_type, members=members))).contents
        else:
            if return_type[0] != 'CGRect' or dev_platform == 'darwin':
                val = ctypes.cast(<unsigned long long>f_result, ctypes.POINTER(factory.find_object(return_type, members=members))).contents
            else:
                # NOTE: this is hardcoded case for CGRect on iOS
                # For some reason CGRect with ctypes don't work as it should work on arm
                rect = (<CGRect*>f_result)[0]
                val = NSRect()
                val.size = NSSize(rect.size.width, rect.size.height)
                val.origin = NSPoint(rect.origin.x, rect.origin.y)
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
        return ObjcReferenceToType(c_addr, sig.split('^', 1)[1], size)

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


def remove_dimensions(array):
    """ Function for flattening multidimensional list to one dimensional """
    result = list()
    if isinstance(array , list):
        for item in array:
            result.extend(remove_dimensions(item))
    else:
        result.append(array)
    return result


cdef void *parse_array(sig, arg, size, multidimension=False):

    cdef void *val_ptr = malloc(size)
    
    sig = sig[1:len(sig) - 1]
    sig_split = re.split('(\d+)', sig)
    array_size = int(sig_split[1])
    array_type = sig_split[2]
    dprint(" ..[+] parse_array({}, {}, {})".format(sig, arg, size))
   
    if array_size != len(arg) and not multidimension:
        dprint("DyLib is accepting array of size {0}, but you are forwarding {1} args.".format(
            array_size, len(arg)))
        raise TypeError()
        
    if array_type[0] == "i":
        dprint("  [+] ...array is integer!")
        (<int **>val_ptr)[0] = CArray(arg).as_int()

    if array_type[0] == "c":
        dprint("  [+] ...array is char!")
        (<char **>val_ptr)[0] = CArray(arg).as_char()

    if array_type[0] == "s":
        dprint("  [+] ...array is short")
        (<short **>val_ptr)[0] = CArray(arg).as_short()

    if array_type[0] == "l":
        dprint("  [+] ...array is long")
        (<long **>val_ptr)[0] = CArray(arg).as_long()

    if array_type[0] == "q":
        dprint("  [+] ...array is long long")
        (<long long**>val_ptr)[0] = CArray(arg).as_longlong()

    if array_type[0] == "f":
        dprint("  [+] ...array is float")
        (<float**>val_ptr)[0] = CArray(arg).as_float()

    if array_type[0] == "d":
        dprint("  [+] ...array is double")
        (<double**>val_ptr)[0] = CArray(arg).as_double()

    if array_type[0] == "I":
        dprint("  [+] ...array is unsigned int")
        (<unsigned int**>val_ptr)[0] = CArray(arg).as_uint()

    if array_type[0] == "S":
        dprint("  [+] ...array is unsigned short")
        (<unsigned short**>val_ptr)[0] = CArray(arg).as_ushort()

    if array_type[0] == "L":
        dprint("  [+] ...array is unsigned long")
        (<unsigned long**>val_ptr)[0] = CArray(arg).as_ulong()

    if array_type[0] == "Q":
        dprint("  [+] ...array is unsigned long long")
        (<unsigned long long**>val_ptr)[0] = CArray(arg).as_ulonglong()

    if array_type[0] == "C":
        dprint("  [+] ...array is unsigned char")
        (<unsigned char**>val_ptr)[0] = CArray(arg).as_uchar()

    if array_type[0] == "B":
        dprint("  [+] ...array is bool")
        (<bool**>val_ptr)[0] = CArray(arg).as_bool()

    if array_type[0] == "*":
        dprint("  [+] ...array is char*")
        (<char***>val_ptr)[0] = CArray(arg).as_char_ptr()

    if array_type[0] == "@":
        dprint("  [+] ...array is object(@)")
        (<id**>val_ptr)[0] = CArray(arg).as_object_array()

    if array_type[0] == "#":
        dprint("  [+] ...array is class(#)")
        (<Class**>val_ptr)[0] = CArray(arg).as_class_array()
        
    if array_type[0] == ":":
        dprint("  [+] ...array is sel(:)")
        (<SEL**>val_ptr)[0] = CArray(arg).as_sel_array()
    
    if array_type[0] == "[":
        dprint("  [+] ...array is array({})".format(sig))
        parse_position = sig.find("[")
        depth = int(sig[0:parse_position])
        sig = sig[parse_position:]
        dprint("Entering recursion for signature {}".format(sig))
        return parse_array(sig, remove_dimensions(arg), size, multidimension=True)
        
    if array_type[0] in ["{", "("]:
        arg_type = array_type[1:-1].split('=', 1)
        dprint("  [+] ...array is struct: {}".format(arg_type))
        (<id**>val_ptr)[0] = CArray(arg).as_struct_array(size, arg_type)
    if array_type[0] == "b":
        pass
    if array_type[0] == "^":
        pass
    if array_type[0] == "?":
        pass

    return val_ptr

cdef extern from "objc/objc.h":
    cdef id *nil

cpdef object convert_py_to_nsobject(arg):
    if arg is None or isinstance(arg, ObjcClassInstance):
        return arg
    elif arg in (True, False):
        return autoclass('NSNumber').alloc().initWithBool_(int(arg))
    elif isinstance(arg, (str, unicode)):
        return autoclass('NSString').alloc().initWithUTF8String_(arg)
    elif isinstance(arg, long):
        return autoclass('NSNumber').alloc().initWithInt_(arg)
    elif isinstance(arg, int):
        return autoclass('NSNumber').alloc().initWithLong_(arg)
    elif isinstance(arg, float):
        return autoclass('NSNumber').alloc().initWithFloat_(arg)
    elif isinstance(arg, list):
        args = arg + [None]
        return autoclass('NSArray').alloc().initWithObjects_(*args)
    elif isinstance(arg, dict):
        items = []
        for key, value in arg.items():
            items.append(key)
            items.append(value)
        items.append(None)
        return autoclass('NSDictionary').alloc().initWithObjectsAndKeys_(*items)
    
    # maybe it's a delegate ?
    dprint('construct a delegate!')
    d = objc_create_delegate(arg)
    dprint('delegate is', d)
    return d


cdef void* convert_py_arg_to_cy(arg, sig, by_value, size_t size) except *:
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

    dprint("passing argument {} by {} (sig={})".format(
        arg, by, sig), of_type='i')

    # method is accepting char (or BOOL, which is also interpreted as char)
    if sig == 'c':
        if by_value:
            if arg in [True, False, 1, 0]:
                (<char*>val_ptr)[0] = convert_py_bool_to_objc(arg)
            else:
                (<char*>val_ptr)[0] = <char>ord(arg)
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
        arg = convert_py_to_nsobject(arg)
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
        dprint("==> Array signature for: {0}".format(list(arg)))
        val_ptr = parse_array(sig, arg, size)

    # method is accepting structure OR union
    # NOTE: Support for passing union as arguments by value wasn't supported with libffi,
    # in time of writing this version of pyobjus.
    # However we can pass union as argument if function accepts pointer to union type
    # Return types for union are working (both, returned union is value, or returned union is pointer)
    # NOTE: There are no problems with structs, only unions, reason -> libffi
    # TODO: ADD SUPPORT FOR PASSING UNIONS AS ARGUMENTS BY VALUE
    elif sig[0] in ['(', '{']:
        dprint("==> Structure arg", arg, sig)
        arg_type = sig[1:-1].split('=', 1)[0]
        if arg is None:
            (<void**>val_ptr)[0] = nil
        elif by_value:
            str_long_ptr = <unsigned long long*><unsigned long long>ctypes.addressof(arg)
            ctypes_struct_cache.append(<unsigned long long>str_long_ptr)
            val_ptr = cast_to_cy_data_type(<id*>str_long_ptr, size, arg_type, by_value=True, py_val=arg)
        else:
            if not objc_ref:
                str_long_ptr = <unsigned long long*><unsigned long long>ctypes.addressof(arg)
                val_ptr = cast_to_cy_data_type(<id*>str_long_ptr, size, arg_type, by_value=False, py_val=arg)
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
            if type(arg) is long:
                (<void**>val_ptr)[0] = <void*><unsigned long long>arg
            elif type(arg) is str:
                # passing bytes as void* is the same as for char*
                (<char **>val_ptr)[0] = <char *><bytes>arg
            else:
                if type(arg) is float:
                    (<float*>arg_val_ptr)[0] = <float>arg
                elif type(arg) is int:
                    (<int*>arg_val_ptr)[0] = <int>arg
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
    if arg_val_ptr != NULL and del_arg_val_ptr:
        free(arg_val_ptr)
        arg_val_ptr = NULL

    return val_ptr
