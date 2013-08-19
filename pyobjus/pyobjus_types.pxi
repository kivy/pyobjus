######################################### CArray #############################################
cdef class CArrayCount:
    
    cdef public unsigned int value
    
    def __cinit__(self, unsigned int set_value):
        self.value = set_value


cdef class CArray:
    """Class for representing c-array. Due to lack of void ptr arithmetic support there is no void casting magic, therefore per type casting is needed."""

    cdef public list PyList
    cdef public unsigned int PyListSize
        
    def __init__(self, arr=None):
        dprint("Initialize CArray in __init__")
        if arr is not None:
            self.PyList = self.fix_args(arr)
            self.PyListSize = <unsigned int> len(self.PyList)
            dprint("CArray values initialized: {0}".format(self.PyList, self.PyListSize))
        else:
            dprint("CArray(arr=None)")


    def fix_args(self, arr):
        if type(arr) == list:
            return arr
        else:
            return list(arr)


    def get_from_ptr(self, unsigned long long ptr, char *of_type, unsigned long long arr_size):
        dprint("CArray().get_from_ptr({0}, {1}, {2})".format(ptr, of_type, arr_size))
        ret = list()
        if str(of_type) == "i":
            arr_cast = ctypes.cast(ptr, ctypes.POINTER(ctypes.c_int))
            for i in xrange(arr_size):
                ret.append(arr_cast[i])
                
        # TODO: remaining types
        return ret
        
        
    cdef int* as_int(self):
        dprint(" [+] ...converting to int array")
        cdef int *int_t = <int*> malloc(sizeof(int) * self.PyListSize)
        if int_t is NULL:
            raise MemoryError()
        for i in xrange(self.PyListSize):
            int_t[i] = self.PyList[i]
        return int_t


    cdef char* as_char(self):
        cdef char *char_t = <char*> malloc(sizeof(char) * self.PyListSize)
        if char_t is NULL:
            raise MemoryError()
        for i in xrange(self.PyListSize):
            char_t[i] = self.PyList[i]
        return char_t


    cdef short* as_short(self):
        cdef short *short_t = <short*> malloc(sizeof(short) * self.PyListSize)
        if short_t is NULL:
            raise MemoryError()
        for i in xrange(self.PyListSize):
            short_t[i] = self.PyList[i]
        return short_t


########## Pyobjus literals <-> Objective C literals ##########

NSNumber = lambda: autoclass('NSNumber')
NSString = lambda: autoclass('NSString')
NSArray = lambda: autoclass('NSArray')
NSDictionary = lambda: autoclass('NSDictionary')

objc_c = lambda x: NSNumber().numberWithChar_(x)
objc_i = lambda x: NSNumber().numberWithInt_(x)
objc_ui = lambda x: NSNumber().numberWithUnsignedInt_(x)
objc_l = lambda x: NSNumber().numberWithLong_(x)
objc_ll = lambda x: NSNumber().numberWithLongLong_(x)
objc_f = lambda x: NSNumber().numberWithFloat_(x)
objc_d = lambda x: NSNumber().numberWithDouble_(x)
objc_b = lambda x: NSNumber().numberWithBool_(x)

objc_str = lambda x: NSString().stringWithUTF8String_(x)

def objc_arr(*args):
    if args[-1] is not None:
        args = args + (None,)
    return NSArray().arrayWithObjects_(*args) 

def objc_dict(arg_dict):
    keys_tuple = tuple([objc_str(x) for x in arg_dict.keys()]) + (None,)
    values_tuple = tuple(arg_dict.values()) + (None,)

    pyobjus_values = objc_arr(*values_tuple)
    pyobjus_keys = objc_arr(*keys_tuple)
    return NSDictionary().dictionaryWithObjects_forKeys_(pyobjus_values, pyobjus_keys)

###############################################################

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
    cdef object prop_name
    cdef object attrs
    cdef id o_instance
    cdef public object prop_attrs_dict

    cdef public object getter_func
    cdef public object setter_func

    def __cinit__(self, property, attrs, ivar, name, **kwargs):
        self.o_instance = NULL
        self.ivar = <Ivar*>malloc(sizeof(Ivar))
        self.by_value = True
        self.property = <objc_property_t*>malloc(sizeof(objc_property_t))
        self.property[0] = (<objc_property_t*><unsigned long long*><unsigned long long>property)[0]
        self.ivar[0] = (<Ivar*><unsigned long long*><unsigned long long>ivar)[0]
        self.attrs = attrs
        self.prop_name = name

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
        dprint('Parsing property attributes --> {0}'.format(attrs))

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
            elif attr[0] is 'G':
                self.getter_func = attr.split('G', 1)[1]
                self.prop_attrs_dict['customGetter'] = True
            elif attr[0] is 'S':
                self.setter_func = attr.split('S', 1)[1][0:-1]
                self.setter_func += '_'
                self.prop_attrs_dict['customSetter'] = True
            # TODO: t<encoding>

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
            property = object.__getattribute__(self, name)
            # if we have custom getter for property, call custom getter
            if property.prop_attrs_dict['customGetter']:
                return self.__getattribute__(property.getter_func)()
            # otherwise call default getter
            else:
                return self.__getattribute__('__getter__' + name)()
        return object.__getattribute__(self, name)

    def upcase_first_letter(self, string):
        return string[0].upper() + string[1:]

    def __setattr__(self, name, value):

        if isinstance(object.__getattribute__(self, name), ObjcProperty):
            property = object.__getattribute__(self, name)
            
            # property is using custom setter
            if property.prop_attrs_dict['customSetter']:
                self.__getattribute__(property.setter_func)(value)
            # property is using default setter
            else:
                setter = 'set' + self.upcase_first_letter(name) + '_'
                self.__getattribute__(setter)(value)
        else:
            try:
                object.__setattr__(self, name, value)
            except:
                dprint('Unknown error occured while setting attribute to {0} object'.format(self), of_type='e')

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
    cdef public char *of_type
    cdef public size_t size

    def __cinit__(self, unsigned long long arg, char *_type, size_t _size):
        self.arg_ref = arg
        self.of_type = _type
        self.size = _size
