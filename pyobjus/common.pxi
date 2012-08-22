
cdef extern from *:
    ctypedef char* const_char_ptr "const char*"

cdef extern from "stdlib.h":
    void   free(void* ptr)
    void*  malloc(size_t size)
    void*  realloc(void* ptr, size_t size)



