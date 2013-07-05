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

def signature_types_to_list(type_encoding):

    type_enc_list = []
    curvy_brace_count = 0
    begin_ind = 0
    end_ind = 0
    started_complex_elem = False
    types_str = ""

    if type_encoding.find('=') == -1:
        return [ret_type for ret_type in type_encoding]

    for letter in type_encoding:
        if letter == '{':
            if types_str:
                begin_ind = end_ind
                type_enc_list.append(types_str)
                types_str = ""
            started_complex_elem = True
            curvy_brace_count += 1
            end_ind += 1
        elif letter == '}':
            curvy_brace_count -= 1
            if curvy_brace_count == 0:
                end_ind += 1
                type_enc_list.append(type_encoding[begin_ind:end_ind])
                begin_ind = end_ind
                started_complex_elem = False
            else:
                end_ind += 1
        elif started_complex_elem is False:
            types_str += letter
            end_ind += 1
        else:
            end_ind += 1
    if started_complex_elem is False and types_str:
        type_enc_list.append(types_str)

    return type_enc_list

cdef ffi_type* type_encoding_to_ffitype(type_encoding):
    cdef ffi_type** ffi_complex_type_elements
    cdef ffi_type* ffi_complex_type

    enc = type_encoding
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
    elif enc == 'v':
        return &ffi_type_void
    # pointer to type --> NOTE: need to be tested!
    elif enc[0] == '^':
        return &ffi_type_pointer
    # return type is struct
    elif enc[0] == '{':
        # NOTE: Tested with this nested input, and it works!
        #signature_types_to_list('{CGPoint=dd{CGPoint={CGPoint=d{CGPoint=dd}}}{CGSize=dd}dd{CSize=aa}dd}')

        types_list = []
        types_list = signature_types_to_list(enc[1:-1].split('=', 1)[1])

        types_count = len(types_list)
        ffi_complex_type = <ffi_type*>malloc(sizeof(ffi_type))
        ffi_complex_type_elements = <ffi_type**>malloc(sizeof(ffi_type)*int(types_count+1))

        ffi_complex_type.size = 0
        ffi_complex_type.alignment = 0
        ffi_complex_type.type = FFI_TYPE_STRUCT
        ffi_complex_type.elements = ffi_complex_type_elements
       
        for i in range(types_count):
            if types_list[i].find('=') != -1:
                ffi_complex_type_elements[i] = type_encoding_to_ffitype(types_list[i])
            else:
                ffi_complex_type_elements[i] = type_encoding_to_ffitype(types_list[i])
        ffi_complex_type_elements[types_count] = NULL
        return ffi_complex_type
       
    raise Exception('Missing encoding for {0!r}'.format(enc))
    #TODO: missing encodings:
    #[array type]    An array
    #(name=type...)    A union
    #bnum    A bit field of num bits
    #^type    A pointer to type
    #?    An unknown type (among other things, 
    #   this code is used for function pointers)
