from debug import dprint

cdef extern from "CoreFoundation/CoreFoundation.h":

    ctypedef struct CFRange:
        pass

cdef extern from "CoreGraphics/CoreGraphics.h":
    
    ctypedef struct CGPoint:
        pass
    ctypedef struct CGSize:
        pass
    ctypedef struct CGRect:
        pass
