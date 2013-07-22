cdef extern from "ffi/ffi.h":

    ctypedef unsigned long  ffi_arg
    ctypedef signed long    ffi_sarg
    ctypedef enum: FFI_TYPE_STRUCT
    ctypedef enum ffi_status:
        FFI_OK = 0,
        FFI_BAD_TYPEDEF,
        FFI_BAD_ABI

    ctypedef enum ffi_abi:
        FFI_FIRST_ABI = 0,
        FFI_SYSV,
        FFI_UNIX64,
        FFI_DEFAULT_ABI,
        FFI_LAST_ABI

    ctypedef struct ffi_cif:
        pass

    ctypedef struct ffi_type:
        size_t size
        unsigned short alignment
        unsigned short type
        ffi_type **elements
    ctypedef ffi_type ffi_type

    cdef ffi_type ffi_type_void
    cdef ffi_type ffi_type_uint8
    cdef ffi_type ffi_type_sint8
    cdef ffi_type ffi_type_uint16
    cdef ffi_type ffi_type_sint16
    cdef ffi_type ffi_type_uint32
    cdef ffi_type ffi_type_sint32
    cdef ffi_type ffi_type_uint64
    cdef ffi_type ffi_type_sint64
    cdef ffi_type ffi_type_float
    cdef ffi_type ffi_type_double
    cdef ffi_type ffi_type_longdouble
    cdef ffi_type ffi_type_pointer

    cdef ffi_status  ffi_prep_cif(ffi_cif *cif, ffi_abi abi,
                        unsigned int nargs,ffi_type *rtype, ffi_type **atypes)

    cdef void        ffi_call(ffi_cif *cif, void (*fn)(), void *rvalue,
                        void **avalue)
