import re

def seperate_encoding(sig):
    c = sig[0][0]
    #print 'seperate_encoding', sig, c
    if c in 'rnNoORV':
        sig = (sig[0][1:], sig[1], c)
    else:
        sig = (sig[0], sig[1], None)
    return sig

def parse_signature(bytes signature):
    parts = re.split('(\d+)', signature)[:-1]
    signature_return = seperate_encoding(parts[0:2])
    parts = parts[2:]
    signature_args = [seperate_encoding(x) for x in zip(parts[0::2], parts[1::2])]
    return signature_return, signature_args


cdef ffi_type* type_encoding_to_ffitype(type_encoding):
    enc, offset, attr = type_encoding
    if enc == 'c':
        return &ffi_type_uint8
    elif enc == 'i':
        return &ffi_type_sint32
    elif enc == 's':
        return &ffi_type_sint16
    elif enc == 'l':
        return &ffi_type_sint32
    elif enc == 'q':
        return &ffi_type_sint64
    elif enc == 'C':
        return &ffi_type_uint8
    elif enc == 'I':
        return &ffi_type_uint32
    elif enc == 'S':
        return &ffi_type_uint16
    elif enc == 'L':
        return &ffi_type_uint32
    elif enc == 'Q':
        return &ffi_type_uint64
    elif enc == 'f':
        return &ffi_type_float
    elif enc == 'd':
        return &ffi_type_double
    elif enc == 'B':
        return &ffi_type_sint8
    elif enc == '*':
        return &ffi_type_pointer
    elif enc == '@':
        return &ffi_type_pointer
    elif enc == '#':
        return &ffi_type_pointer
    elif enc == ':':
        return &ffi_type_pointer
    raise Exception('Missing encoding for {0!r}'.format(enc))
    #TODO: missing encodings:
    #[array type]	An array
    #{name=type...}	A structure
    #(name=type...)	A union
    #bnum	A bit field of num bits
    #^type	A pointer to type
    #?	An unknown type (among other things, 
    #   this code is used for function pointers)

"""
cpdef convert_objctype_arg(signature, arg):
    sig, offset = signature
    if sig == 'c':
        return <char> bytes(arg)
    elif sig == 'i':
        return <int> int(arg)
    elif sig == 's':
        return <short> int(arg)
    elif sig == 'l':
        return <long> int(arg)
    elif sig == 'q':
        return <long long> long(arg)
    elif sig == 'C':
        return <unsigned char> bytes(arg)
    elif sig == 'I':
        return <unsigned int> int(arg)
    elif sig == 'S':
        return <unsigned short> int(arg)
    elif sig == 'L':
        return <unsigned long> long(arg)
    elif sig == 'Q':
        return <unsigned long long> long(arg)
    elif sig == 'f':
        return <float> float(arg)
    elif sig == 'd':
        return <double> float(arg)
    elif sig == 'B':
        v = False
        if arg:
            v = True
        return <unsigned char> v
    elif sig == '*':
        return arg
    elif sig == '@':
        return arg
    elif sig == '#':
        return arg
    elif sig == ':':
        return arg
    else:
        return arg
    """
