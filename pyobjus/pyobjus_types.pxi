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


cdef class ObjcProperty:
    ''' Class for representing Objective c properties '''

    cdef objc_property_t *property
    cdef public object prop_enc
    cdef object prop_type
    cdef object prop_name
    cdef object attrs
    cdef id o_instance
    cdef Ivar ivar
    cdef id ivar_val
    cdef object prop_attrs_dict

    def __cinit__(self, property, attrs, **kwargs):
        self.o_instance = NULL
        self.ivar = NULL
        self.property = <objc_property_t*>malloc(sizeof(objc_property_t))
        self.property[0] = (<objc_property_t*><unsigned long long*><unsigned long long>property)[0]
        self.attrs = attrs

        self.prop_attrs_dict = {
            'isReadOnly': False, 
            'isCopy': False,
            'isRetain': False,
            'isNonAtomic': False,
            'isDynamic': False,
            'isWeak': False,
            'isEligibleForGC': False,
            'isOldStyleEnc': False,
            'isCustomGetter': False,
            'isCustomSetter': False
        }

        self.parse_attributes(attrs)

    def __call__(self, *args, **kwargs):
        pass

    def __dealloc__(self):
        if self.property is not NULL:
            free(self.property)

    def parse_attributes(self, attrs):
        ''' Method for parsing property signature
    
        Args:
            attrs: String containing info about property, eg. Ti,Vprop_int -> @property (assign) int prop_int
        '''
        dprint('Parsing property attributes --> {0}'.format(attrs), type='d')

        for attr in attrs.split(','):
            if attr[0] is 'T':
                attr_splt_res = attr.split('T')[1]
                if attr_splt_res[0] is '@':
                    self.prop_type = attr_splt_res.split('@')[1]
                    self.prop_enc = attr_splt_res[0]
                else:
                    self.prop_enc = attr_splt_res

            elif attr[0] is 'V':
                self.prop_name = attr.split('V')[1]

    def get_value(self, obj_ptr):
        ''' Method for retrieveing value of some object property
        
        Args:
            obj_ptr: Pointer to objective c instance object -> o_instance
        Returns:
            Python representation of objective c property value
        '''
        dprint('getting value of {0} property with attrs {1}'.format(self.prop_name, self.attrs), type='d')
        if self.o_instance == NULL:
            self.o_instance = (<id*><unsigned long long>obj_ptr)[0]
        if self.ivar == NULL:
            self.ivar = object_getInstanceVariable(self.o_instance, <char*>self.prop_name, <void**>&self.ivar_val)
        else:
            # if we already have Ivar value, then object_getIvar is faster than object_getInstanceVariable
            self.ivar_val = object_getIvar(self.o_instance, self.ivar)
        return convert_cy_ret_to_py(&self.ivar_val, self.prop_enc, 0)

    def set_value(self, obj_ptr, value):
        ''' Method for setting value of some object property
        
        Args:
            obj_ptr: Pointer to objective c instance object -> o_instance
            value: Value to set to property
        '''
        dprint('setting property {0} value'.format(self.prop_name), type='d')
        object_setIvar(self.o_instance, self.ivar, <id>(<id*><unsigned long long>value)[0])

cdef class ObjcClassInstance(object):

    enc = '@'
    cdef Class o_cls
    cdef id o_instance
    cdef int val

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

    def __getattribute__(self, name):
        if isinstance(object.__getattribute__(self, name), ObjcProperty):
            return object.__getattribute__(self, name).get_value(<unsigned long long>&self.o_instance)
        return object.__getattribute__(self, name)

    def __setattr__(self, name, value):
        cdef void *val_ptr

        if isinstance(object.__getattribute__(self, name), ObjcProperty):
            property = object.__getattribute__(self, name)
            size = 0
            if isinstance(value, ctypes.Structure):
                size = ctypes.sizeof(value)
            val_ptr = convert_py_arg_to_cy(value, property.prop_enc, True, size)
            object.__getattribute__(self, name).set_value(<unsigned long long>&self.o_instance, <unsigned long long>val_ptr)
        else:
            object.__setattr__(self, name, value)

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
