'''
Type documentation: https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
'''

__all__ = ('ObjcClassInstance', 'ObjcClass', 'ObjcMethod', 'MetaObjcClass', 'ObjcException',
    'autoclass', 'selector')


include "common.pxi"
include "runtime.pxi"
include "ffi.pxi"
include "type_enc.pxi"
include "objc_types.pxi"

from debug import dprint
from objc_py_types import NSRange

# do the initialization!
pyobjc_internal_init()

cdef pr(void *pointer):
    # convert a void* to a 0x... value
    return '0x%x' % <unsigned long>pointer

cdef dict oclass_register = {}

class ObjcException(Exception):
    pass


cdef class ObjcClassStorage:
    cdef Class o_cls

    def __cinit__(self):
        self.o_cls = NULL


class MetaObjcClass(type):
    def __new__(meta, classname, bases, classDict):
        meta.resolve_class(classDict)
        tp = type.__new__(meta, classname, bases, classDict)
        
        if(classDict['__objcclass__'] not in oclass_register):
            oclass_register[classDict['__objcclass__']] = {}

        # for every class we save class instance and class object to cache
        if(ObjcClass not in bases):
            oclass_register[classDict['__objcclass__']]['instance'] = tp
        else:
            oclass_register[classDict['__objcclass__']]['class'] = tp
        return tp

    def __getattr__(self, name):
        ocls = self.get_objcclass(self.__name__)
        sel_name = name.replace("_",":")
        cdef SEL cls_method_sel
        cls_method_sel = <SEL>(<bytes>sel_name)
        return None

    @staticmethod
    def get_objcclass(name):
        return oclass_register.get(name)

    @classmethod
    def resolve_class(meta, classDict):
        # search the Objc class, and bind to our object
        if '__objcclass__' not in classDict:
            return ObjcException('__objcclass__ definition missing')

        cdef bytes __objcclass__ = <bytes>classDict['__objcclass__']
        cdef ObjcClassStorage storage = ObjcClassStorage()

        storage.o_cls = <Class>objc_getClass(__objcclass__)
        if storage.o_cls == NULL:
            raise ObjcException('Unable to found the class {0!r}'.format(
                __objcclass__))

        classDict['__cls_storage'] = storage

        cdef ObjcMethod om
        for name, value in classDict.iteritems():
            if isinstance(value, ObjcMethod):
                om = value
                if om.is_static:
                    om.set_resolve_info(name, storage.o_cls, NULL)

        # FIXME do the static fields resolution

def selector(name):
    """ Function for getting selector for given method name

    Args:
        name: method name
    Returns:
        ObjcSelector instance, which contains SEL pointer
    """
    osel = ObjcSelector()
    osel.selector = sel_registerName(name)
    dprint(pr(osel.selector), type="i")
    return osel

cdef class ObjcSelector(object):
    """ Class for storing selector 
    """    
    cdef SEL selector 

    def __cinit__(self, *args, **kwargs):
        self.selector = NULL

cdef class ObjcMethod(object):
    cdef bytes name
    cdef bytes signature
    cdef int is_static
    cdef object signature_return
    cdef object signature_args
    # this attribute is required for pyobjus varargs implementation
    cdef object signature_default_args
    cdef Class o_cls
    cdef id o_instance
    cdef SEL selector 
    cdef SEL *selectors
    cdef ObjcClassInstance p_class
    cdef int is_varargs
    cdef int is_ready
    cdef ffi_cif f_cif
    cdef ffi_type* f_result_type
    cdef ffi_type **f_arg_types

    def __cinit__(self, signature, **kwargs):
        self.is_ready = 0
        self.f_result_type = NULL
        self.f_arg_types = NULL
        self.name = None
        self.selector = NULL
        self.selectors = NULL
        self.is_varargs = False

    def __dealloc__(self):
        self.is_ready = 0
        if self.f_result_type != NULL:
            free(self.f_result_type)
            self.f_result_type = NULL
        if self.f_arg_types != NULL:
            free(self.f_arg_types)
            self.f_arg_types = NULL

    def __init__(self, signature, **kwargs):
        super(ObjcMethod, self).__init__()
        self.signature = <bytes>signature
        self.signature_return, self.signature_args = parse_signature(signature)
        self.is_static = kwargs.get('static', False)
        self.name = kwargs.get('name')

        py_selectors = kwargs.get('selectors', [])
        if len(py_selectors):
            self.selectors = <SEL *>malloc(sizeof(SEL) * len(py_selectors))
            for index, name in enumerate(py_selectors):
                self.selectors[index] = sel_registerName(<bytes>name)

    def set_is_static(self, value):
        self.is_static = value

    cdef void set_resolve_info(self, bytes name, Class o_cls, id o_instance) except *:

        # we are doing this because we can't call method with class() -> it is python keyword, so
        # we call method .oclass() and here we can set selector to be of method with name -> class
        if name == "oclass":
            self.name = name.replace("oclass", "class")

        self.name = self.name or name.replace("_", ":")
        self.selector = sel_registerName(<bytes>self.name)
        self.o_cls = o_cls
        self.o_instance = o_instance

    cdef void ensure_method(self) except *:
        if self.is_ready:
            return

        dprint('-' * 80)
        dprint('signature ensure_method -->', self.name, self.signature_return)
        
        cdef ffi_type f_type
        cdef ffi_type* elements[3]
        
        if self.signature_return[0][0] != '{':
            self.f_result_type = type_encoding_to_ffitype(self.signature_return)
        else:
            # currently this only works for rangeOfString: method 
            f_type.size = 0
            f_type.alignment = 0
            f_type.type = FFI_TYPE_STRUCT
            f_type.elements = elements
            elements[0] = &ffi_type_uint64
            elements[1] = &ffi_type_uint64
            elements[2] = NULL

            self.f_result_type = &f_type
        
        # allocate memory to hold ffitype* of arguments
        cdef int size = sizeof(ffi_type) * len(self.signature_args)
        self.f_arg_types = <ffi_type **>malloc(size)
        if self.f_arg_types == NULL:
            raise MemoryError()

        # populate f_args_type array for FFI prep
        cdef int index = 0
        for arg in self.signature_args:
            dprint("argument ==>", arg, len(self.signature_args))
            self.f_arg_types[index] = type_encoding_to_ffitype(arg)
            index = index + 1

        # FFI PREP 
        cdef ffi_status f_status
        f_status = ffi_prep_cif(&self.f_cif, FFI_DEFAULT_ABI,
                len(self.signature_args), self.f_result_type, self.f_arg_types)
        if f_status != FFI_OK:
            raise ObjcException(
                    'Unable to prepare the method {0!r}'.format(self.name))

        self.is_ready = 1

    def __get__(self, obj, objtype):
        if obj is None:
            return self
        cdef ObjcClassInstance oc = obj
        self.o_instance = oc.o_instance
        return self

    def __call__(self, *args, **kwargs):
        if len(args) > (len(self.signature_args) - 2):
            dprint("preparing potential varargs method...", type='i')
            self.is_varargs = True
            self.is_ready = False 

            # we are substracting 2 because first two arguments are selector and self
            self.signature_default_args = self.signature_args[:]
            num_of_signature_args = len(self.signature_args) - 2
            num_of_passed_args = len(args)
            num_of_arguments_to_add = num_of_passed_args - num_of_signature_args
            
            for i in range(num_of_arguments_to_add):
                self.signature_args.append(self.signature_args[-1])
            
            # we need prepare new number of arguments for ffi_call
            self.ensure_method()        
        return self._call_instance_method(*args)

    def _reset_method_attributes(self):
        '''Method for setting adapted attributes values to default ones
        '''
        dprint("reseting method attributes...", type='i')
        self.signature_args = self.signature_default_args
        self.is_ready = False
        self.ensure_method()
        # this is little optimisation in case of calling varargs method multiple times with None as argument
        self.is_varargs = False

    def _call_instance_method(self, *args):
        
        dprint('-' * 80)
        dprint('call_instance_method()', self.name, pr(self.o_cls), pr(self.o_instance))
        self.ensure_method()
        dprint('--> want to call', self.name, args)
        dprint('--> return def is', self.signature_return)
        dprint('--> args def is', self.signature_args)

        cdef ffi_arg f_result
        cdef void* void_ptr
        cdef void **f_args
        cdef int index
        cdef size_t size
        cdef ObjcClassInstance arg_objcclass
        cdef size_t result_size = <size_t>int(self.signature_return[1])
        # allocate f_args
        f_args = <void**>malloc(sizeof(void *) * len(self.signature_args))
        if f_args == NULL:
            free(f_args)
            raise MemoryError('Unable to allocate f_args')

        # arg 0 and 1 are the instance and the method selector
        #for class methods, we need the class itself is theinstance
        if self.is_static:
            f_args[0] = &self.o_cls
            dprint(' - [0] static class instance', pr(self.o_cls))
        else:
            f_args[0] = &self.o_instance
            dprint(' - [0] class instance', pr(self.o_instance))


        f_args[1] = &self.selector
        dprint(' - selector is', pr(self.selector))

        # populate the rest of f_args based on method signature
        cdef void* val_ptr
        f_index = 1
        cdef ObjcClassInstance ocl
        for index in range(2, len(self.signature_args)):
            # argument passed to call
            arg = args[index-2]
            
            # we already know the ffitype/size being used
            val_ptr = <void*>malloc(self.f_arg_types[index][0].size)
            dprint("index {}: allocating {} bytes for arg: {!r}".format(
                    index, self.f_arg_types[index][0].size, arg))

            # cast the argument type based on method sig and store at val_ptr
            sig, offset, attr = self.signature_args[index]

            if sig == 'c':
                (<char*>val_ptr)[0] = bytes(arg)
            elif sig == 'i':
                (<int*>val_ptr)[0] = <int> int(arg)
            elif sig == 's':
                (<short*>val_ptr)[0] = <short> int(arg)
            elif sig == 'Q':
                (<unsigned long long*>val_ptr)[0] = <unsigned long long> long(arg)
            elif sig == '*':
                (<char **>val_ptr)[0] = <char *><bytes>arg
            elif sig == '@':
                dprint('====> ARG', <ObjcClassInstance>arg)
                if arg == None:
                    (<id*>val_ptr)[0] = <id>NULL
                else:
                    ocl = <ObjcClassInstance>arg
                    (<id*>val_ptr)[0] = <id>ocl.o_instance
            # method is accepting class
            elif sig == '#':
                dprint('===> Class arg', <ObjcClassInstance>arg)
                ocl = <ObjcClassInstance>arg
                (<Class*>val_ptr)[0] = <Class>ocl.o_cls
            # method is accepting selector
            elif sig == ":":
                dprint("==> Selector arg", <ObjcSelector>arg)
                osel = <ObjcSelector>arg
                (<id*>val_ptr)[0] = <id>osel.selector
            
            else:
                (<int*>val_ptr)[0] = 0
            dprint("fargs[{0}] = {1}, {2!r}".format(index, sig, arg))

            f_index += 1
            f_args[f_index] = val_ptr

            dprint('pointer before ffi_call:', pr(f_args[f_index]))

        if self.signature_return[0][0] != '{':
            ffi_call(&self.f_cif, <void(*)()>objc_msgSend, &f_result, f_args)
        else:
            void_ptr = malloc(result_size)
            # TODO: Need to add objc_msgSend_stret method invocation in case of big structures
            ffi_call(&self.f_cif, <void(*)()>objc_msgSend, void_ptr, f_args)

        sig = self.signature_return[0]
        dprint("return signature", sig, type="i")
        if self.is_varargs:
            self._reset_method_attributes()
        
        cdef CFRange result_range
        cdef CFRange *result_range_ptr
 
        cdef id ret_id
        cdef ObjcClassInstance cret
        cdef bytes bret
        if sig == '@':
            dprint(' - @ f_result:', pr(<void *>f_result))
            ret_id = (<id>f_result)
            if ret_id == self.o_instance:
                return self.p_class
            bret = <bytes><char *>object_getClassName(ret_id)
            dprint(' - object_getClassName(f_result) =', bret)
            if bret == 'nil':
                dprint('<-- returned pointer value:', pr(ret_id), type="w")
                return None
            
            cret = autoclass(bret, new_instance=True)(noinstance=True)
            cret.instanciate_from(ret_id)
            dprint('<-- return object', cret)
            return cret

        elif sig == 'c':
            # this should be a char. Most of the time, a BOOL is also
            # implemented as a char. So it's not a string, but just the numeric
            # value of the char.
            return (<int><char>f_result)
        elif sig == 'i':
            return (<int>f_result)
        elif sig == 's':
            return (<short>f_result)
        elif sig == 'l':
            return (<long>f_result)
        elif sig == 'q':
            return (<long long>f_result)
        elif sig == 'C':
            return (<unsigned char>f_result)
        elif sig == 'I':
            return (<unsigned int>f_result)
        elif sig == 'S':
            return (<unsigned short>f_result)
        elif sig == 'L':
            return (<unsigned long>f_result)
        elif sig == 'Q':
            return (<unsigned long long>f_result)
        elif sig == 'f':
            return (<float>f_result)
        elif sig == 'd':
            return (<double>f_result)
        elif sig == 'b':
            return (<bool>f_result)
        elif sig == 'v':
            return None
        elif sig == '*':
            return <bytes>(<char*>f_result)

        # return type -> class
        elif sig == '#':
            ocl = ObjcClassInstance(noinstance="True", getcls="True")
            ocl.o_cls = <Class>object_getClass(<id>f_result)
            return ocl
        # return type -> selector. TODO: Test this !!!
        elif sig == ':':
            osel = ObjcSelector()
            osel.selector = <SEL>f_result
            return osel
        elif sig[0] == '[':
            # array
            pass

        # return type -> struct
        elif sig[0] == '{':
            result_range_ptr = <CFRange*>void_ptr
            result_range = <CFRange>result_range_ptr[0]
            # TODO: Find better solution for this 
            ns_range = NSRange(<unsigned long long>result_range.location, <unsigned long long>result_range.length)       
            return ns_range
        
        elif sig[0] == '(':
            # union
            pass
        elif sig == 'b':
            # bitfield
            pass
        elif sig[0] == '^':
            # pointer to type
            pass
        elif sig == '?':
            # unknown type
            pass

        else:
            assert(0)


cdef class ObjcClass(object):
    # if we are calling class method, set is_statis field to True
    def __getattribute__(self, attr):
        if(isinstance(object.__getattribute__(self, attr), ObjcMethod)):
            object.__getattribute__(self, attr).set_is_static(True)

        return object.__getattribute__(self, attr)


cdef class ObjcClassInstance(object):
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

registers = []

cdef class_get_methods(Class cls, static=False):
    cdef unsigned int index, num_methods
    cdef char *method_name
    cdef char *method_args
    cdef bytes py_name
    cdef dict methods = {}
    cdef Method* class_methods = class_copyMethodList(cls, &num_methods)
    for i in xrange(num_methods):
        method_name = <char*>sel_getName(method_getName(class_methods[i]))
        method_args = <char*>method_getTypeEncoding(class_methods[i])
        py_name = (<bytes>method_name).replace(":", "_")
        
        methods[py_name] = ObjcMethod(<bytes>method_args, static=static)
    free(class_methods)
    return methods

cdef class_get_static_methods(Class cls):
    cdef Class meta_cls = <Class>object_getClass(<id>cls)
    return class_get_methods(meta_cls, True)

cdef class_get_super_class_name(Class cls):
    """ Get super class name of some class
    Args:
        cls: Class for which we will lookup for super class name
    Returns:
        Super class name of class
    """
    cdef Class cls_super = class_getSuperclass(<Class>cls)
    return object_getClassName(<id>cls_super)

cdef resolve_super_class_methods(Class cls, instance_methods=True):
    """ Getting super classes methods of some class
    Args:
        cls: Class for which we will try to get super methods
        
    Returns:
        A dict with super methods
    """
    cdef dict super_cls_methods_dict = {}
    cdef Class cls_super = class_getSuperclass(<Class>cls)
    super_cls_name = object_getClassName(<id>cls_super)
    
    while str(super_cls_name) != "nil":
        if(instance_methods == True):
            super_cls_methods_dict.update(class_get_methods(cls_super))
        else:
            super_cls_methods_dict.update(class_get_static_methods(cls_super))

        super_cls_name = class_get_super_class_name(cls_super)
        cls_super = <Class>objc_getClass(super_cls_name)

    return super_cls_methods_dict

def autoclass(cls_name, new_instance=False):
    # if class or class instance is already in cache, return requested value
    if cls_name in oclass_register:
        if new_instance == False and "class" in oclass_register[cls_name]:
            dprint("getting class from cache...", type='i')
            return oclass_register[cls_name]['class']
        elif new_instance == True and "instance" in oclass_register[cls_name]:
            dprint('getting instance from cache...', type='i')
            return oclass_register[cls_name]['instance']

    cdef Class cls = <Class>objc_getClass(cls_name)
    cdef Class cls_super

    cdef dict instance_methods = class_get_methods(cls)
    cdef dict class_methods = class_get_static_methods(cls)
    cdef dict class_dict = {'__objcclass__':  cls_name}

    # if this isn't new instance of some class, retrieve only static methods
    if(new_instance == False):
        class_dict.update(resolve_super_class_methods(cls, instance_methods=False))
        class_dict.update(class_methods)
    # otherwise retrieve instance methods
    else:
        class_dict.update(resolve_super_class_methods(cls))
        class_dict.update(instance_methods)

    if "class" in class_dict:
        class_dict.update({'oclass': class_dict['class']})
        class_dict.pop("class", None)

    if(new_instance == False):
        return MetaObjcClass.__new__(MetaObjcClass, cls_name, (ObjcClassInstance, ObjcClass), class_dict)()

    return MetaObjcClass.__new__(MetaObjcClass, cls_name, (ObjcClassInstance,), class_dict)
