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


cdef class CastFactory(object):

    cdef cast_to_cy(self, id *py_obj, void* val_ptr, char* type):
        if str(type) == '_NSRange':
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
