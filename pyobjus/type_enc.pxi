def seperate_encoding(sig):
    c = sig[0][:1]

    if c in b'rnNoORV':
        sig = (sig[0][1:], sig[1], c)
    else:
        sig = (sig[0], sig[1], None)
    return sig


def parse_signature(bytes signature):
    parts = re.split(b'(\d+)', signature)[:-1]
    signature_return = seperate_encoding(parts[0:2])
    parts = parts[2:]
    signature_args = [seperate_encoding(x) for x in zip(parts[0::2], parts[1::2])]

    # reassembly for array
    if b'[' in signature:
        tmp_sig = []
        arr_sig = b''
        for item in signature_args:
            if item[0].startswith(b'['):
                arr_sig += item[0] + item[1]
            elif item[0].endswith(b']'):
                arr_sig += item[0]
                tmp_sig.append((arr_sig, item[1], item[2]))
            else:
                tmp_sig.append(item)
        signature_args = tmp_sig

    return signature_return, signature_args


def signature_types_to_list(type_encoding):
    type_enc_list = []
    curvy_brace_count = 0
    begin_ind = 0
    end_ind = 0
    started_complex_elem = False
    types_str = b""

    if type_encoding.find(b'=') == -1:
        if PY_MAJOR_VERSION == 2:
            return list(type_encoding)
        else:
            return [bytes([ret_type]) for ret_type in type_encoding]

    for letter in type_encoding:
        letter = bytes([letter])
        dprint("type_encoding={!r} letter={!r}".format(type_encoding, letter))
        if letter in [b'(', b'{']:
            if types_str:
                begin_ind = end_ind
                types_str = ""
            started_complex_elem = True
            curvy_brace_count += 1
            end_ind += 1
        elif letter in [b')', b'}']:
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
            type_enc_list.append(letter)
            end_ind += 1
        else:
            end_ind += 1

    return type_enc_list

cdef ffi_type* type_encoding_to_ffitype(type_encoding, str_in_union=False):
    dprint("input for type_encoding_to_ffitype(type_encoding={}, str_in_union={})".format(type_encoding, str_in_union))

    cdef ffi_type** ffi_complex_type_elements
    cdef ffi_type* ffi_complex_type

    enc = type_encoding
    if enc == b'c':
        return &ffi_type_uint8
    elif enc == b'i':
        return &ffi_type_sint32
    elif enc == b's':
        return &ffi_type_sint16
    elif enc == b'l':
        return &ffi_type_sint32
    elif enc == b'q':
        return &ffi_type_sint64
    elif enc == b'C':
        return &ffi_type_uint8
    elif enc == b'I':
        return &ffi_type_uint32
    elif enc == b'S':
        return &ffi_type_uint16
    elif enc == b'L':
        return &ffi_type_uint32
    elif enc == b'Q':
        return &ffi_type_uint64
    elif enc == b'f':
        return &ffi_type_float
    elif enc == b'd':
        return &ffi_type_double
    elif enc == b'B':
        return &ffi_type_sint8
    elif enc == b'*':
        return &ffi_type_pointer
    elif enc == b'@':
        return &ffi_type_pointer
    elif enc == b'#':
        return &ffi_type_pointer
    elif enc == b':':
        return &ffi_type_pointer
    elif enc == b'v':
        return &ffi_type_void
    elif enc.startswith(b'^'):
        return &ffi_type_pointer
    elif enc.endswith(b'?'):
        # An unknown type (among other things, this code is used for function pointers)
        return &ffi_type_pointer
    # return type is struct or union
    elif enc.startswith((b'(', b'{')):
        # NOTE: Tested with this nested input, and it works!
        #signature_types_to_list('{CGPoint=dd{CGPoint={CGPoint=d{CGPoint=dd}}}{CGSize=dd}dd{CSize=aa}dd}')
        types_list = []
        obj_type = enc[1:-1].split(b'=', 1)
        types_list = signature_types_to_list(obj_type[1])
        dprint("rest list -->", types_list, type='i')

        types_count = len(types_list)
        ffi_complex_type = <ffi_type*>malloc(sizeof(ffi_type))
        ffi_complex_type_elements = <ffi_type**>malloc(sizeof(ffi_type)*int(types_count+1))

        if enc.startswith(b'(') or (str_in_union and enc.startswith(b'{')):
            ffi_complex_type.size = ctypes.sizeof(factory.find_object(obj_type))
        else:
            ffi_complex_type.size = 0
        ffi_complex_type.alignment = 0
        ffi_complex_type.type = FFI_TYPE_STRUCT
        ffi_complex_type.elements = ffi_complex_type_elements

        for i in range(types_count):
            if types_list[i].find(b'=') != -1:
                if types_list[i].split(b'=', 1)[0].startswith(b'('):
                    str_in_union = True
                ffi_complex_type_elements[i] = type_encoding_to_ffitype(types_list[i], str_in_union=str_in_union)
            else:
                ffi_complex_type_elements[i] = type_encoding_to_ffitype(types_list[i])

        ffi_complex_type_elements[types_count] = NULL
        return ffi_complex_type
    elif enc == b'b':
        raise ObjcException("Bit fields aren't supported in pyobjus!")
    elif enc.startswith(b'['): #[array type]    An array
        return &ffi_type_pointer


    raise Exception('Missing encoding for {0!r}'.format(enc))
    #TODO: missing encodings:
