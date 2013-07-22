class ObjcException(Exception):
    pass


cdef class ObjcClassStorage:
    cdef Class o_cls

    def __cinit__(self):
        self.o_cls = NULL


cdef class ObjcChar:
    enc = 'c'


cdef class ObjcInt:
    enc = 'i'


cdef class ObjcShort:
    enc = 's'


cdef class ObjcLong:
    enc = 'l'


cdef class ObjcLongLong:
    enc = 'q'


cdef class ObjcUChar:
    enc = 'C'


cdef class ObjcUInt:
    enc = 'I'


cdef class ObjcUShort:
    enc = 'S'


cdef class ObjcULong:
    enc = 'L'


cdef class ObjcULongLong:
    enc = 'Q'


cdef class ObjcFloat:
    enc = 'f'


cdef class ObjcDouble:
    enc = 'd'


cdef class ObjcBool:
    enc = 'B'


cdef class ObjcBOOL:
    enc = 'c'


cdef class ObjcVoid:
    enc = 'v'


cdef class ObjcString:
    enc = '*'


cdef class ObjcSelector(object):
    """ Class for storing selector 
    """    
    enc = ':'
    cdef SEL selector 

    def __cinit__(self, *args, **kwargs):
        self.selector = NULL


cdef class ObjcClass(object):

    enc = '#'
    cdef Class o_cls

    def __cinit__(self, *args, **kwargs):
        self.o_cls = NULL


cdef class ObjcClassHlp(object):
    # if we are calling class method, set is_static field to True
    def __getattribute__(self, attr):
        if(isinstance(object.__getattribute__(self, attr), ObjcMethod)):
            object.__getattribute__(self, attr).set_is_static(True)

        return object.__getattribute__(self, attr)


cdef class ObjcClassInstance(object):

    enc = '@'
    cdef Class o_cls
    cdef id o_instance

    def __cinit__(self, *args, **kwargs):
        self.o_cls = NULL
        self.o_instance = NULL

    def __init__(self, *args, **kwargs):
        super(ObjcClassInstance, self).__init__()
        cdef ObjcClassStorage storage
        if 'getcls' not in kwargs:
            storage = self.__cls_storage
            self.o_cls = storage.o_cls

        if 'noinstance' not in kwargs:
            self.call_constructor(args)
            self.resolve_methods()
            self.resolve_fields()

    def __dealloc__(self):
        if self.o_instance != NULL:
            objc_msgSend(self.o_instance, sel_registerName('release'))
            self.o_instance = NULL

    cdef void instanciate_from(self, id o_instance) except *:
        self.o_instance = o_instance
        # XXX is retain is needed ?
        self.o_instance = objc_msgSend(self.o_instance, sel_registerName('retain'))
        #print 'retainCount', <int>objc_msgSend(self.o_instance,
        #        sel_registerName('retainCount'))
        self.resolve_methods()
        self.resolve_fields()

    cdef void call_constructor(self, args) except *:
        # FIXME it seems that doing nothing is changed:
        # -> doing alloc + init doesn't change anything, it still run
        # -> is class_createInstance() is sufficient itself?
        # -> make tests change with and without alloc+init, check the test_isequal
        #print '-' * 80
        #print 'call_constructor() for', self.__cls_storage
        self.o_instance = class_createInstance(self.o_cls, 0);
        #print 'o_instance (first)', pr(self.o_instance)
        #self.o_instance = objc_msgSend(self.o_cls, sel_registerName('alloc'))
        #print 'o_instance (alloc)', pr(self.o_instance)
        #print 'retainCount (alloc)', <int>objc_msgSend(self.o_instance,
        #        sel_registerName('retainCount'))
        if self.o_instance == NULL:
            raise ObjcException('Unable to instanciate {0}'.format(
                self.__javaclass__))
        #self.o_instance = objc_msgSend(self.o_instance,
        #    sel_registerName('init'))
        #print 'o_instance (init)', pr(self.o_instance)
        #print 'retainCount (init)', <int>objc_msgSend(self.o_instance,
        #        sel_registerName('retainCount'))


    cdef void resolve_methods(self) except *:
        
        cdef ObjcMethod om
        for name, value in self.__class__.__dict__.iteritems():
            if isinstance(value, ObjcMethod):
                om = value
                #if om.is_static:
                #    continue
                om.set_resolve_info(name, self.o_cls, self.o_instance)
                om.p_class = self

    cdef void resolve_fields(self) except *:
        pass


cdef class ObjcReferenceToType(object):
    ''' Class for representing reference to some objective c type
    '''

    cdef public unsigned long long arg_ref
    cdef public char *type
    cdef public size_t size

    def __cinit__(self, unsigned long long arg, char *_type, size_t _size):
        self.arg_ref = arg
        self.type = _type
        self.size = _size

cdef class ObjcIvar(object):
    pass
