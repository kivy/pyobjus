'''
Type documentation: https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
'''

__all__ = ('ObjcChar', 'ObjcInt', 'ObjcShort', 'ObjcLong', 'ObjcLongLong', 'ObjcUChar', 'ObjcUInt', 
        'ObjcUShort', 'ObjcULong', 'ObjcULongLong', 'ObjcFloat', 'ObjcDouble', 'ObjcBool', 'ObjcBOOL', 'ObjcVoid', 
        'ObjcString', 'ObjcClassInstance', 'ObjcClass', 'ObjcSelector', 'ObjcMethod', 'ObjcInt', 
        'ObjcFloat', 'MetaObjcClass', 'ObjcException', 'autoclass', 'selector', 'objc_py_types', 
        'dereference', 'signature_types_to_list')

include "common.pxi"
include "runtime.pxi"
include "ffi.pxi"
include "type_enc.pxi"
include "objc_cy_types.pxi"
include "pyobjus_types.pxi"
include "pyobjus_conversions.pxi"

from debug import dprint
import ctypes
import objc_py_types
from objc_py_types import Factory

# do the initialization!
pyobjc_internal_init()

cdef pr(void *pointer):
    # convert a void* to a 0x... value
    return '0x%x' % <unsigned long>pointer

cdef dict oclass_register = {}

class MetaObjcClass(type):
    def __new__(meta, classname, bases, classDict):
        meta.resolve_class(classDict)
        tp = type.__new__(meta, classname, bases, classDict)
        
        if(classDict['__objcclass__'] not in oclass_register):
            oclass_register[classDict['__objcclass__']] = {}

        # for every class we save class instance and class object to cache
        if(ObjcClassHlp not in bases):
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

cdef class ObjcMethod(object):
    cdef bytes name
    cdef bytes signature
    cdef int is_static
    cdef object signature_return
    cdef object signature_args
    cdef object factory
    # this attribute is required for pyobjus varargs implementation
    cdef object signature_default_args
    cdef object return_type
    cdef object members
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
        if self.f_result_type != NULL:
            if self.f_result_type.elements != NULL:
                free(self.f_result_type.elements)
                self.f_result_type.elements = NULL
            free(self.f_result_type)
            self.f_result_type = NULL

    def __init__(self, signature, **kwargs):
        super(ObjcMethod, self).__init__()
        self.signature = <bytes>signature
        self.signature_return, self.signature_args = parse_signature(signature)
        self.is_static = kwargs.get('static', False)
        self.name = kwargs.get('name')
        self.factory = Factory()

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

        if self.signature_return[0][0] in ['(', '{']:
            sig = self.signature_return[0]
            self.return_type = sig[1:-1].split('=', 1)

        self.name = self.name or name.replace("_", ":")
        self.selector = sel_registerName(<bytes>self.name)
        self.o_cls = o_cls
        self.o_instance = o_instance

    cdef void ensure_method(self) except *:
        if self.is_ready:
            return

        dprint('-' * 80)
        dprint('signature ensure_method -->', self.name, self.signature_return)
        
        # resolve f_result_type 
        if self.signature_return[0][0] == '(':
            self.f_result_type = type_encoding_to_ffitype(self.signature_return[0], str_in_union=True)
        else:
            self.f_result_type = type_encoding_to_ffitype(self.signature_return[0])

        # casting is needed here because otherwise we will get warning at compile
        cdef unsigned int num_args = <unsigned int>len(self.signature_args)
        cdef unsigned int size = sizeof(ffi_type) * num_args
        # allocate memory to hold ffi_type* of arguments 
        self.f_arg_types = <ffi_type **>malloc(size)
        if self.f_arg_types == NULL:
            raise MemoryError()

        # populate f_args_type array for FFI prep
        cdef int index = 0
        for arg in self.signature_args:
            if arg[0][0] == '(':
                raise ObjcException("Currently passing unions as arguments by value isn't supported in pyobjus!")
            dprint("argument ==>", arg, len(self.signature_args))
            self.f_arg_types[index] = type_encoding_to_ffitype(arg[0])
            index = index + 1

        # FFI PREP 
        cdef ffi_status f_status
        f_status = ffi_prep_cif(&self.f_cif, FFI_DEFAULT_ABI,
                num_args, self.f_result_type, self.f_arg_types)
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
        if 'members' in kwargs:
            self.members = kwargs['members']

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

        cdef id* res_ptr
        cdef object del_res_ptr = True
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

        cdef ObjcClassInstance ocl
        f_index = 1

        # populate the rest of f_args based on method signature
        for index in range(2, len(self.signature_args)):
            # argument passed to call
            arg = args[index-2]
            # we already know the ffitype/size being used
            dprint("index {}: allocating {} bytes for arg: {!r}".format(
                    index, self.f_arg_types[index][0].size, arg))

            # cast the argument type based on method sig and store at val_ptr
            sig, offset, attr = self.signature_args[index]
            
            by_value = True
            if sig[0][0] == '^':
                by_value = False
                sig = sig.split('^')[1]
            
            dprint("fargs[{0}] = {1}, {2!r}".format(index, sig, arg))
            f_index += 1
            f_args[f_index] = convert_py_arg_to_cy(arg, sig, by_value, self.f_arg_types[index][0].size)
            dprint('pointer before ffi_call:', pr(f_args[f_index]))

        res_ptr = <id*>malloc(self.f_result_type.size)
        
        if self.signature_return[0][0] not in ['(', '{']:
            ffi_call(&self.f_cif, <void(*)()>objc_msgSend, res_ptr, f_args)
        else:
            # TODO FIXME NOTE: Currently this only work on x86_64 architecture
            # We need add cases for powerPC 32bit and 64bit, and IA-32 architecture

            IF UNAME_MACHINE == "x86_64":
            # From docs: If the type has class MEMORY, then the caller provides space for the return
            # value and passes the address of this storage in %rdi as if it were the ﬁrst
            # argument to the function. In effect, this address becomes a “hidden” ﬁrst
            # argument.

            # If the size of an object is larger than two eightbytes, or in C++, 
            # is a nonPOD structure or union type, or contains unaligned ﬁelds, it has class MEMORY
            # SOURCE: http://www.uclibc.org/docs/psABI-x86_64.pdf
                fun_name = ""
                if self.return_type[0] == '?':
                    met_sig = self.return_type[1]
                else:
                    met_sig = None

                obj_ret = self.factory.find_object(self.return_type)
                size_ret = ctypes.sizeof(obj_ret)

                stret = False
                if self.signature_return[0][0] in ['{', '('] and size_ret > 16:
                    stret = True
                
                if stret:
                    ffi_call(&self.f_cif, <void(*)()>objc_msgSend_stret, res_ptr, f_args)
                    fun_name = "objc_msgSend_stret"
                    del_res_ptr = False
                else:
                    ffi_call(&self.f_cif, <void(*)()>objc_msgSend, res_ptr, f_args)
                    fun_name = "objc_msgSend"
                dprint("x86_64 architecture {0} call".format(fun_name), type='i')
            ELSE:
                dprint("UNSUPPORTED ARCHITECTURE! Program will exit now...", type='e')
                raise SystemExit()

        if self.is_varargs:
            self._reset_method_attributes()

        cdef id ret_id
        cdef ObjcClassInstance cret
        cdef bytes bret

        sig = self.signature_return[0]
        dprint("return signature", self.signature_return[0], type="i")
        
        if sig == '@':
            ret_id = (<id>res_ptr[0])
            if ret_id == self.o_instance:
                return self.p_class
        
        ret_py_val = convert_cy_ret_to_py(res_ptr, sig, self.f_result_type.size, members=self.members) 
        
        return ret_py_val

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

cdef get_class_method(Class cls, char *name):
    ''' Function for getting class method for given Class
    
    Args:
        cls: Class for which we will look up for method
        name: name of method

    Returns:
        ObjcMethod instance
    '''
    cdef Method m_cls = class_getClassMethod(cls, sel_registerName(name))
    return ObjcMethod(<bytes><char*>method_getTypeEncoding(m_cls), static=True)

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

cdef get_class_ivars(Class cls):
    ''' Function for getting a list of properties of some objective c class
    
    Args:
        cls: Class which properties we want to obtain
    Returns:
        List of ObjcProperty objects. Native objc property will be converted to ObjcProperty Python type
    '''
    cdef unsigned int num_props
    cdef dict props_dict = {}
    cdef objc_property_t *properties = class_copyPropertyList(cls, &num_props)
    cdef const char* prop_attrs
    cdef Ivar ivar
    cdef void **out_val = NULL

    for i in range(num_props):
        prop_attrs = property_getAttributes(properties[i])
        name = property_getName(properties[i])
        ivar = class_getInstanceVariable(cls, <char*>name)
        props_dict[name] = ObjcProperty(<unsigned long long>&properties[i], prop_attrs, <unsigned long long>&ivar)
    return props_dict

def check_copy_properties(cls_name):
    if oclass_register[cls_name].get('class') is not None:
        return oclass_register[cls_name].get('class').__copy_properties__
    return None

def autoclass(cls_name, **kwargs):

    new_instance = kwargs.get('new_instance', False)
    # if class or class instance is already in cache, return requested value
    if cls_name in oclass_register:
        if not new_instance and "class" in oclass_register[cls_name]:
            dprint("getting class from cache...", type='i')
            return oclass_register[cls_name]['class']
        elif new_instance and "instance" in oclass_register[cls_name]:
            dprint('getting instance from cache...', type='i')
            return oclass_register[cls_name]['instance']

    # Resolving does user want to copy properties of class, or it doesn't
    # TODO:  This need to be tested more!
    if cls_name in oclass_register.keys():
        copy_properties = check_copy_properties(cls_name)
        if copy_properties is None:
            copy_properties = check_copy_properties(class_get_super_class_name(<Class>objc_getClass(cls_name)))
            if copy_properties is None:
                copy_properties = True
    else:
        copy_properties = kwargs.get('copy_properties', True)

    cdef Class cls = <Class>objc_getClass(cls_name)
    cdef Class cls_super

    cdef dict instance_methods = class_get_methods(cls)
    cdef dict class_methods = class_get_static_methods(cls)
    cdef dict class_dict = {'__objcclass__':  cls_name, '__copy_properties__': copy_properties}

    # if this isn't new instance of some class, retrieve only static methods
    if not new_instance:
        class_dict.update(resolve_super_class_methods(cls, instance_methods=False))
        class_dict.update(class_methods)
    # otherwise retrieve instance methods
    else:
        class_dict.update(resolve_super_class_methods(cls))
        class_dict.update(instance_methods)
        # for some reason, if we don't override this instance method with class method, it won't work correctly
        class_dict.update({'isKindOfClass_': get_class_method(cls, 'isKindOfClass:')})

    if "class" in class_dict:
        class_dict.update({'oclass': class_dict['class']})
        class_dict.pop("class", None)

    if copy_properties:
        class_dict.update(get_class_ivars(cls))

    if not new_instance:
        return MetaObjcClass.__new__(MetaObjcClass, cls_name, (ObjcClassInstance, ObjcClassHlp), class_dict)()

    return MetaObjcClass.__new__(MetaObjcClass, cls_name, (ObjcClassInstance,), class_dict)
