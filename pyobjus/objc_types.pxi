cdef extern from "_objc_types.h":
    
    ctypedef unsigned long long NSUInteger

    ctypedef struct _CFRange:
        NSUInteger location
        NSUInteger length
    ctypedef _CFRange CFRange
