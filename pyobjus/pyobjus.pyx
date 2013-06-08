'''
Type documentation: https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
'''

__all__ = ('ObjcClass', 'ObjcMethod', 'MetaObjcClass', 'ObjcException',
    'autoclass')


include "common.pxi"
include "runtime.pxi"
include "ffi.pxi"
include "type_enc.pxi"
from ctypes import c_void_p

# do the initialization!
pyobjc_internal_init()

cdef pr(void *pointer):
    # convert a void* to a 0x... value
    return '0x%x' % <unsigned long>pointer

# currently this is no working
#cdef va_list * make_va_list(id n, ...):
#    cdef va_list args
#    va_start(args, n)
#    return &args

cdef dict oclass_register = {}

class ObjcException(Exception):
    pass


cdef class ObjcClassStorage:
    cdef Class o_cls

    def __cinit__(self):
        self.o_cls = NULL


class MetaObjcClass(type):
    class_methods = dict()
    def __new__(meta, classname, bases, classDict):
        meta.resolve_class(classDict)
        meta.class_methods.update(classDict)
        tp = type.__new__(meta, classname, bases, classDict)
        oclass_register[classDict['__objcclass__']] = tp
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


cdef class ObjcMethod(object):
    cdef bytes name
    cdef bytes signature
    cdef int is_static
    cdef object signature_return
    cdef object signature_args
    cdef Class o_cls
    cdef id o_instance
    cdef SEL selector 
    cdef SEL *selectors
    cdef ObjcClass p_class

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

    cdef void set_resolve_info(self, bytes name, Class o_cls, id o_instance) except *:
        self.name = self.name or name.replace("_", ":")
        self.selector = sel_registerName(<bytes>self.name)
        self.o_cls = o_cls
        self.o_instance = o_instance

    cdef void ensure_method(self) except *:
        if self.is_ready:
            return

        print '-' * 80
        print 'signature ensure_method -->', self.name, self.signature_return
        # get return type type as ffitype*
        self.f_result_type = type_encoding_to_ffitype(self.signature_return)

        # allocate memory to hold ffitype* of arguments
        cdef int size = sizeof(ffi_type) * len(self.signature_args)
        self.f_arg_types = <ffi_type **>malloc(size)
        if self.f_arg_types == NULL:
            raise MemoryError()

        # populate f_args_type array for FFI prep
        cdef int index = 0
        for arg in self.signature_args:
            print "argument ==>", arg, len(self.signature_args)
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
        cdef ObjcClass oc = obj
        self.o_instance = oc.o_instance
        return self

    def __call__(self, *args):
        #if self.is_static:
        #    return self._call_class_method(*args)
        return self._call_instance_method(*args)

    def _call_instance_method(self, *args):
        print '-' * 80
        print 'call_instance_method()', self.name, pr(self.o_cls), pr(self.o_instance)
        self.ensure_method()
        print '--> want to call', self.name, args
        print '--> return def is', self.signature_return
        print '--> args def is', self.signature_args

        cdef ffi_arg f_result
        cdef void **f_args
        cdef int index
        cdef size_t size
        cdef ObjcClass arg_objcclass

        # allocate f_args
        f_args = <void**>malloc(sizeof(void *) * len(self.signature_args))
        if f_args == NULL:
            free(f_args)
            raise MemoryError('Unable to allocate f_args')

        # arg 0 and 1 are the instance and the method selector
        #for class methods, we need the class itself is theinstance
        if self.is_static:
            print "static class !!!!"
            f_args[0] = &self.o_cls
            print ' - [0] static class instance', pr(self.o_cls)
        else:
            f_args[0] = &self.o_instance
            print ' - [0] class instance', pr(self.o_instance)


        f_args[1] = &self.selector
        print ' - selector is', pr(self.selector)

        # populate the rest of f_args based on method signature
        cdef void* val_ptr
        f_index = 1
        cdef ObjcClass ocl
        for index in range(2, len(self.signature_args)):
            # argument passed to call
            arg = args[index-2]

            # we already know the ffitype/size being used
            val_ptr = <void*>malloc(self.f_arg_types[index][0].size)
            print "index {}: allocating {} bytes for arg: {!r}".format(
                    index, self.f_arg_types[index][0].size, arg)

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
                print '====> ARG', <ObjcClass>arg
                ocl = <ObjcClass>arg
                (<id*>val_ptr)[0] = <id>ocl.o_instance
                                
            else:
                (<int*>val_ptr)[0] = 0
            print "fargs[{0}] = {1}, {2!r}".format(index, sig, arg)

            f_index += 1
            f_args[f_index] = val_ptr

            print 'pointer before ffi_call:', pr(f_args[f_index])
         
        ffi_call(&self.f_cif, <void(*)()>objc_msgSend, &f_result, f_args)

        sig = self.signature_return[0]
        cdef id ret_id
        cdef ObjcClass cret
        cdef bytes bret
        if sig == '@':
            print ' - @ f_result:', pr(<void *>f_result)
            ret_id = (<id>f_result)
            if ret_id == self.o_instance:
                return self.p_class
            bret = <bytes><char *>object_getClassName(ret_id)
            print ' - object_getClassName(f_result) =', bret
            if bret == 'nil':
                print '<-- returned pointer value:', pr(ret_id)
                assert(0)
            
            cret = autoclass(bret, new_instance=False)(noinstance=True)
            cret.instanciate_from(ret_id)
            print '<-- return object', cret
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
        elif sig == '#':
            # class ?
            pass
        elif sig == ':':
            # selector ? but as a return ?
            pass
        elif sig[0] == '[':
            # array
            pass
        elif sig[0] == '{':
            # array
            pass
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
    cdef Class o_cls
    cdef id o_instance

    def __cinit__(self, *args, **kwargs):
        self.o_cls = NULL
        self.o_instance = NULL

    def __init__(self, *args, **kwargs):
        super(ObjcClass, self).__init__()
        cdef ObjcClassStorage storage = self.__cls_storage
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
                if om.is_static:
                    continue
                om.set_resolve_info(name, self.o_cls, self.o_instance)
                om.p_class = self

    cdef void resolve_fields(self) except *:
        pass


registers = []

def ensureclass(clsname):
    if clsname in registers:
        return
    objcname = clsname.replace('.', '/')
    if MetaObjcClass.get_objcclass(objcname):
        return
    registers.append(clsname)
    autoclass(clsname)


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


def autoclass(cls_name, new_instance=True):
    cdef Class cls = <Class>objc_getClass(cls_name)
    cdef Class cls_super
    cdef dict instance_methods = class_get_methods(cls)
    cdef dict class_methods = class_get_static_methods(cls)
    cdef dict merged_class_dict = {}
    cdef dict class_dict = {'__objcclass__':  cls_name}

    class_dict.update(instance_methods)
    class_dict.update(class_methods)
    
    if(new_instance == False):
        cls_super = class_getSuperclass(cls)
        super_cls_name = object_getClassName(<id>cls_super)
        # if already exist super class instance
        if super_cls_name in oclass_register:
            merged_class_dict.update(oclass_register[super_cls_name].class_methods)
            merged_class_dict.update(instance_methods)
            merged_class_dict.update(class_methods)
            return MetaObjcClass.__new__(MetaObjcClass, cls_name, (ObjcClass,), merged_class_dict)

    return MetaObjcClass.__new__(MetaObjcClass, cls_name, (ObjcClass, ), class_dict)

