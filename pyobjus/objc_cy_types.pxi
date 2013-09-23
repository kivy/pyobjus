from debug import dprint

cdef extern from "CoreFoundation/CoreFoundation.h":

    ctypedef struct CFRange:
        pass

cdef extern from "CoreGraphics/CoreGraphics.h":
    
    ctypedef struct CGPoint:
        float x
        float y
    ctypedef struct CGSize:
        float width
        float height
    ctypedef struct CGRect:
        CGPoint origin
        CGSize size
