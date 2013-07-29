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
    cdef Ivar *ivar
    cdef public object prop_enc
    cdef public object by_value
    cdef public object prop_type
    cdef object cls_name
    cdef object prop_name
    cdef object attrs
    cdef id o_instance
    cdef id ivar_val
    cdef object prop_attrs_dict

    def __cinit__(self, property, attrs, ivar, name, cls_name, **kwargs):
        self.o_instance = NULL
        self.ivar = <Ivar*>malloc(sizeof(Ivar))
        self.by_value = True
        self.property = <objc_property_t*>malloc(sizeof(objc_property_t))
        self.property[0] = (<objc_property_t*><unsigned long long*><unsigned long long>property)[0]
        self.ivar[0] = (<Ivar*><unsigned long long*><unsigned long long>ivar)[0]
        self.attrs = attrs
        self.prop_name = name
        self.cls_name = cls_name

        self.prop_attrs_dict = {
            'readonly': False, 
            'copy': False,
            'retain': False,
            # NOTE: With "atomic", the synthesized setter/getter will ensure that a whole value is always 
            # returned from the getter or set by the setter, regardless of setter activity on any other thread. 
            # That is, if thread A is in the middle of the getter while thread B calls the setter, 
            # an actual viable value -- an autoreleased object, 
            # most likely -- will be returned to the caller in A.
            # In nonatomic, no such guarantees are made. Thus, nonatomic is considerably faster than "atomic"
            'nonatomic': False,
            # NOTE: @synthesize will generate getter and setter methods for your property. 
            # @dynamic just tells the compiler that the getter and setter methods 
            # are implemented not by the class itself but somewhere else
            'dynamic': False,
            'weak': False,
            'eligibleForGC': False,
            'oldStyleEnc': False,
            'customGetter': False,
            'customSetter': False
        }

        self._parse_attributes(attrs)

    def __dealloc__(self):
        if self.property is not NULL:
            free(self.property)
        if self.ivar is not NULL:
            free(self.ivar)

    def _get_attributes(self):
        ''' Method for getting list of property attributes
        
        Returns:
            List of attributes, eg. ['nonatomic', 'copy'] -> @property (nonatomic, copy) ...
        '''
        return [x for x, y in self.prop_attrs_dict.iteritems() if y is True]

    def _parse_attributes(self, attrs):
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
                elif attr_splt_res[0] is '^':
                    self.by_value = False
                    self.prop_enc = attr_splt_res
                    self.prop_type = attr_splt_res.split('^')[1]
                    if self.prop_type.find('=') is not -1:
                        self.prop_type = self.prop_type[1:-1].split('=', 1)
                else:
                    self.prop_enc = attr_splt_res
            elif attr[0] is 'V':
                self.prop_name = attr.split('V')[1]
            elif attr is 'R':
                self.prop_attrs_dict['readonly'] = True
            elif attr is 'N':
                self.prop_attrs_dict['nonatomic'] = True
            elif attr is '&':
                self.prop_attrs_dict['retain'] = True
            elif attr is 'C':
                self.prop_attrs_dict['copy'] = True
            elif attr is 'D':
                self.prop_attrs_dict['dynamic'] = True
            elif attr is 'W':
                self.prop_attrs_dict['weak'] = True
            elif attr is 'P':
                self.prop_attrs_dict['eligibleForGC'] = True
            # TODO: t<encoding>, G<name>, S<name>

    def _manage_dynamic_property(self, **kwargs):
        ''' Method for managing getting/setting values of dynamic (@dynamic) properties
        
        Returns:
            If user want to retrieve value, he will get actual Python representation of value for objc property
        '''

        cdef id key_val = NULL
        cdef id objc_val = NULL
        value = kwargs.get('value', None)
        by_value = kwargs.get('by_value', None)

        from pyobjus import autoclass
        NSString = autoclass("NSString")
        key_val = (<id*>convert_py_arg_to_cy(NSString.stringWithUTF8String_(self.prop_name), '@', True, 0))[0]

        if kwargs.get('mode') is 'Set':
            if by_value:
                objc_val = (<id*><unsigned long long>value)[0]
            else:
                objc_val = <id><unsigned long long>value
            objc_msgSend(self.o_instance, sel_registerName('setValue:forKey:'), objc_val, key_val)
        else:
            return oclass_register[self.cls_name]['instance'].valueForKey_(NSString.stringWithUTF8String_(self.prop_name))
 
    def get_value(self, obj_ptr):
        ''' Method for retrieveing value of some object property
        
        Args:
            obj_ptr: Pointer to objective c instance object -> o_instance
        Returns:
            Python representation of objective c property value
        '''
        dprint('getting value of {0} property with attrs {1}'.format(self.prop_name, self.attrs), type='d')

        if self.o_instance is NULL:
            self.o_instance = (<id*><unsigned long long>obj_ptr)[0]
        self.ivar_val = object_getIvar(self.o_instance, self.ivar[0])

        if not self.by_value:
            py_type = factory.find_object(self.prop_type)
            return convert_cy_ret_to_py(<id*>self.ivar_val, self.prop_enc, ctypes.sizeof(py_type), members=None, objc_prop=True)
        if self.prop_attrs_dict['dynamic']:
            return self._manage_dynamic_property()
        return convert_cy_ret_to_py(&self.ivar_val, self.prop_enc, 0, members=None, objc_prop=True)

    def set_value(self, obj_ptr, value):
        ''' Method for setting value of some object property
        
        Args:
            obj_ptr: Pointer to objective c instance object -> o_instance
            value: Value to set to property
        '''
        dprint('setting property {0} value'.format(self.prop_name), type='d')

        if self.prop_attrs_dict['readonly']:
            raise ObjcException('Assignment to readonly property')

        if self.o_instance is NULL:
            self.o_instance = (<id*><unsigned long long>obj_ptr)[0]
        if not self.by_value:
            # this is case where property doesn't have default getters/setters
            if self.prop_attrs_dict['dynamic']:
                self._manage_dynamic_property(value=value, by_value=self.by_value, mode='Set')
            else:
                object_setIvar(self.o_instance, self.ivar[0], <id><unsigned long long>value)
        else:
            if self.prop_attrs_dict['dynamic']:
                self._manage_dynamic_property(value=value, by_value=self.by_value, mode='Set')
            else:
                object_setIvar(self.o_instance, self.ivar[0], (<id*><unsigned long long>value)[0])

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
        cdef unsigned long long val_ulng_ptr

        if isinstance(object.__getattribute__(self, name), ObjcProperty):
            property = object.__getattribute__(self, name)

            size = 0
            if not property.by_value:
                size = py_type = ctypes.sizeof(factory.find_object(property.prop_type))
            elif isinstance(value, ctypes.Structure) or isinstance(value, ctypes.Union):
                size = ctypes.sizeof(value)

            if property.prop_enc[0] is '^':
                prop_enc = property.prop_enc.split('^')[1]
            else:
                prop_enc = property.prop_enc

            val_ptr = convert_py_arg_to_cy(value, prop_enc, property.by_value, size)
            if not property.by_value:
                val_ulng_ptr = (<unsigned long long*>val_ptr)[0]
            else:
                val_ulng_ptr = <unsigned long long>val_ptr

            property.set_value(<unsigned long long>&self.o_instance, val_ulng_ptr)
        else:
            try:
                object.__setattr__(self, name, value)
            except:
                dprint('Unknown error occured while setting attribute to {0} object'.format(self), type='e')

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
