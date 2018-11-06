'''
Pyobjus
=======

.. note::

    This project has been mostly a POC, then evolved into a GSOC. It remain
    uncleaned in severals place. There is a time for discovery and testing, and
    another time for cleaning and make things readable.

    We now are trying to clean the code each time we dig in. Be gentle.

.. todo::

    - clean, clean, clean, clean
    - pep8 compliant, at least
    - reduce code overhead


Type documentation:

    https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html

'''

__all__ = (
    'ObjcChar', 'ObjcInt', 'ObjcShort', 'ObjcLong', 'ObjcLongLong', 'ObjcUChar',
    'ObjcUInt', 'ObjcUShort', 'ObjcULong', 'ObjcULongLong', 'ObjcFloat',
    'ObjcDouble', 'ObjcBool', 'ObjcBOOL', 'ObjcVoid', 'ObjcString',
    'ObjcClassInstance', 'ObjcClass', 'ObjcSelector', 'ObjcMethod',
    'MetaObjcClass', 'ObjcException', 'autoclass', 'selector', 'objc_py_types',
    'dereference', 'signature_types_to_list', 'dylib_manager', 'objc_c',
    'objc_i', 'objc_ui', 'objc_l', 'objc_ll', 'objc_f', 'objc_d', 'objc_b',
    'objc_str', 'objc_arr', 'objc_dict', 'dev_platform', 'CArray',
    'CArrayCount', 'protocol', 'convert_py_to_nsobject', 'symbol')

from cpython.version cimport PY_MAJOR_VERSION

include "config.pxi"
dev_platform = PLATFORM

include "common.pxi"
include "runtime.pxi"
include "ffi.pxi"
include "type_enc.pxi"
include "objc_cy_types.pxi"
include "pyobjus_types.pxi"
include "pyobjus_conversions.pxi"

import ctypes
from .debug import dprint
if PY_MAJOR_VERSION == 2:
    import objc_py_types
    from objc_py_types import Factory
    import dylib_manager
else:
    import pyobjus.objc_py_types as objc_py_types
    from .objc_py_types import Factory
    import pyobjus.dylib_manager as dylib_manager

# do the initialization!
pyobjc_internal_init()

cdef dict oclass_register = {}
cdef dict omethod_partial_register = {}
delegate_register = dict()


cdef pr(void *pointer):
    # convert a void* to a 0x... value
    return '0x%x' % <unsigned long>pointer


class MetaObjcClass(type):

    def __new__(meta, classname, bases, classDict):
        meta.resolve_class(classDict)
        if PY_MAJOR_VERSION == 2:
            classname = classname.encode("utf-8")
        tp = type.__new__(meta, classname, bases, classDict)

        if classDict['__objcclass__'] not in oclass_register:
            oclass_register[classDict['__objcclass__']] = {}

        # for every class we save class instance and class object to cache
        if ObjcClassHlp not in bases:
            oclass_register[classDict['__objcclass__']]['instance'] = tp
        else:
            oclass_register[classDict['__objcclass__']]['class'] = tp
        return tp

    @staticmethod
    def get_objcclass(name):
        return oclass_register.get(name)

    @classmethod
    def resolve_class(meta, classDict):
        # search the Objc class, and bind to our object
        if '__objcclass__' not in classDict:
            return ObjcException('__objcclass__ definition missing')

        cdef bytes __objcclass__ = classDict['__objcclass__']

        cdef ObjcClassStorage storage = ObjcClassStorage()
        storage.o_cls = <Class>objc_getClass(__objcclass__)
        if storage.o_cls == NULL:
            raise ObjcException('Unable to find class {0!r}'.format(
                __objcclass__))

        classDict['__cls_storage'] = storage

        cdef ObjcMethod om
        for name, value in classDict.iteritems():
            if isinstance(value, ObjcMethod):
                om = value
                if om.is_static:
                    om.set_resolve_info(<bytes>name, storage.o_cls, NULL)

        # FIXME do the static fields resolution


def selector(name):
    """Function for getting selector for given method name

    Args:
        name: method name
    Returns:
        ObjcSelector instance, which contains SEL pointer
    """
    osel = ObjcSelector()
    osel.selector = sel_registerName(name)
    dprint(pr(osel.selector), of_type="i")
    return osel


cdef class ObjcMethod(object):
    cdef bytes name
    cdef bytes signature
    cdef int is_static
    cdef object signature_return
    cdef object signature_current_args
    cdef object signature_args
    cdef object factory
    # this attribute is required for pyobjus varargs implementation
    cdef object return_type
    cdef object members
    cdef object main_cls_name
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
    cdef object objc_name

    def __cinit__(self, signature, objc_name, **kwargs):
        self.is_ready = 0
        self.f_result_type = NULL
        self.f_arg_types = NULL
        self.name = None
        self.selector = NULL
        self.selectors = NULL
        self.is_varargs = False

    def __dealloc__(self):
        # NOTE: Commented lines here cause seg fault if we uncomment them!
        # TODO: See that is the problem!!!
        self.is_ready = 0
        #if self.f_result_type != NULL:
        #    free(self.f_result_type)
        #    self.f_result_type = NULL
        if self.f_arg_types != NULL:
            free(self.f_arg_types)
            self.f_arg_types = NULL
        if self.f_result_type != NULL:
            if self.f_result_type.elements != NULL:
                free(self.f_result_type.elements)
                self.f_result_type.elements = NULL
            #free(self.f_result_type)
            #self.f_result_type = NULL
        # TODO: Memory management

    def __init__(self, bytes signature, bytes objc_name, **kwargs):
        super(ObjcMethod, self).__init__()
        self.signature = <bytes>signature
        self.signature_return, self.signature_args = parse_signature(signature)
        self.is_static = kwargs.get('static', False)
        self.name = kwargs.get('name')
        self.objc_name = objc_name
        self.factory = Factory()
        self.main_cls_name = kwargs.get('main_cls_name')

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
            self.name = name.replace(b"oclass", b"class")

        if self.signature_return[0].startswith((b'(', b'{')):
            sig = self.signature_return[0]
            self.return_type = sig[1:-1].split(b'=', 1)

        self.name = self.objc_name
        self.selector = sel_registerName(<bytes>self.name)
        self.o_cls = o_cls
        self.o_instance = o_instance

    cdef void ensure_method(self, signature_args) except *:
        if self.signature_current_args == signature_args:
            return
        self.signature_current_args = signature_args

        dprint('-' * 80)
        dprint('signature ensure_method -->', self.name, self.signature_return)

        ## signature tuple compression for carray
        # FIXME: might be broken, need to be tested again.
        tmp_sig = []
        arr_sig = b''

        for item in signature_args:
            if item[0].startswith(b'['):
                arr_sig += item[0] + item[1]
            elif item[0].endswith(b']'):
                arr_sig += item[0]
                tmp_sig.append((arr_sig, item[1], item[2]))
            else:
                tmp_sig.append(item)
        dprint('pre-zip signature: {}'.format(signature_args))
        dprint('array signature zip: {}'.format(tmp_sig))
        #self.signature_args = tmp_sig

        # resolve f_result_type
        if self.signature_return[0].startswith(b'('):
            self.f_result_type = type_encoding_to_ffitype(
                    self.signature_return[0], str_in_union=True)
        else:
            self.f_result_type = type_encoding_to_ffitype(
                    self.signature_return[0])

        # casting is needed here because otherwise we will get warning at compile
        cdef unsigned int num_args = <unsigned int>len(signature_args)
        cdef unsigned int size = sizeof(ffi_type) * num_args

        # allocate memory to hold ffi_type* of arguments
        if self.f_arg_types != NULL:
            free(self.f_arg_types)
            self.f_arg_types = NULL
        self.f_arg_types = <ffi_type **>malloc(size)
        if self.f_arg_types == NULL:
            raise MemoryError()

        # populate f_args_type array for FFI prep
        cdef int index = 0
        for arg in signature_args:
            if arg[0].startswith(b'('):
                raise ObjcException(
                    'Currently passing unions as arguments by '
                    'value is not supported in pyobjus!')
            dprint('argument ==>', arg, len(signature_args))
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
        dprint('-' * 80)
        dprint('__call__()', self.name, pr(self.o_cls), pr(self.o_instance))
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

        # check that we have at least the same number of arguments as the
        # signature want.
        if len(args) < len(self.signature_args) - 2:
            raise ObjcException('Not enough parameters for {}'.format(
                self.name))

        # allocate f_args
        f_args = <void **>malloc(sizeof(void *) * (2 + len(args)))
        if f_args == NULL:
            free(f_args)
            raise MemoryError('Unable to allocate f_args')

        # arg 0 and 1 are the instance and the method selector
        # for class methods, we need the class itself is theinstance
        if self.is_static:
            f_args[0] = &self.o_cls
            dprint(' - [0] static class instance {!r} (&{!r})'.format(
              pr(self.o_cls), pr(&self.o_cls)))
        else:
            f_args[0] = &self.o_instance
            dprint(' - [0] class instance {!r} (&{!r})'.format(
              pr(self.o_instance), pr(&self.o_instance)))


        f_args[1] = &self.selector
        dprint(' - selector is', pr(self.selector))

        cdef ObjcClassInstance ocl
        carray = False

        # populate the rest of f_args based on method signature
        signature_args = self.signature_args[:]
        for index, arg in enumerate(args):

            dprint("==", index, arg)

            if arg == CArrayCount:
                arg = 0
                carray = True

            # automatically expand the signature args based on the last
            # signature argument, to cover variables arguments (va_args)
            sig_index = index + 2
            if sig_index >= len(signature_args):
                sig_index = -1
                signature_args.append(signature_args[-1])

            sig, offset, attr = sig_full = signature_args[sig_index]
            arg_size = type_encoding_to_ffitype(sig).size

            # we already know the ffitype/size being used
            dprint("index {}: allocating {} bytes for arg: {!r}".format(
                    index, arg_size, arg))

            # cast the argument type based on method sig and store at val_ptr
            by_value = True
            if sig[0] == b'^':
                by_value = False
                sig = sig.split(b'^')[1]

            dprint('fargs[{}] = {}, {!r}'.format(index + 2, sig, arg))
            f_args[index + 2] = convert_py_arg_to_cy(
                    arg, sig, by_value, arg_size)
            dprint('pointer before ffi_call:', pr(f_args[index + 2]))

        # ensure that ffi method is correctly prepared for our current signature
        self.ensure_method(signature_args)
        dprint('--- really call {} with args {} (signature is {})'.format(
            self.name, args, signature_args))
        for index in range(len(signature_args)):
            dprint('   > {}: 0x{:x}'.format(index, <unsigned long>f_args[index]))

        # allocate the memory for the return value
        res_ptr = <id *>malloc(self.f_result_type.size)
        if res_ptr == NULL:
            raise MemoryError('Unable to allocate res_ptr')

        if self.signature_return[0][0] not in [b'(', b'{']:
            ffi_call(&self.f_cif, <void(*)()>objc_msgSend, res_ptr, f_args)

        else:
            # TODO FIXME NOTE: Currently this only work on x86_64 architecture and armv7 ios

            IF PLATFORM == 'darwin':
            # OSX -> X86_64
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
                if self.signature_return[0][0] in [b'{', b'('] and size_ret > 16:
                    stret = True

                if stret:
                    ffi_call(&self.f_cif, <void(*)()>objc_msgSend_stret, res_ptr, f_args)
                    fun_name = "objc_msgSend_stret"
                    del_res_ptr = False
                else:
                    ffi_call(&self.f_cif, <void(*)()>objc_msgSend, res_ptr, f_args)
                    fun_name = "objc_msgSend"
                dprint("x86_64 architecture {0} call".format(fun_name), of_type='i')

            ELIF PLATFORM == 'ios':
                IF ARCH == 'arm64':
                    ffi_call(&self.f_cif, <void(*)()>objc_msgSend, res_ptr, f_args)
                    dprint('ios(arm64) platform objc_msgSend call')
                ELSE:
                    ffi_call(&self.f_cif, <void(*)()>objc_msgSend_stret, res_ptr, f_args)
                    dprint('ios(armv7) platform objc_msgSend_stret call')

            ELSE:
                dprint("UNSUPPORTED ARCHITECTURE! Program will exit now...", of_type='e')
                raise SystemExit()


        cdef id ret_id
        cdef ObjcClassInstance cret
        cdef bytes bret

        sig = self.signature_return[0]
        dprint("return signature", self.signature_return[0], of_type="i")

        if sig == b'@':
            ret_id = (<id>res_ptr[0])
            if ret_id == self.o_instance:
                return self.p_class

        ret_py_val = convert_cy_ret_to_py(res_ptr, sig, self.f_result_type.size,
                members=kwargs.get('members'), objc_prop=False,
                main_cls_name=self.main_cls_name)

        if type(ret_py_val) == ObjcReferenceToType and carray == True:
            f_index = len(signature_args) - 1
            mm = ctypes.cast((<unsigned long *>f_args[f_index])[0], ctypes.POINTER(ctypes.c_uint32))
            ret_py_val.add_reference_return_value(mm.contents, CArrayCount)

        # free f_args
        for index, arg in enumerate(args):
            free(f_args[index + 2])
        free(f_args)

        return ret_py_val

registers = []
tmp_properties_keys = []

cdef objc_method_to_py(Method method, main_cls_name, static=True):
    ''' Function for making equvivalent Python object for some Method C type

    Args:
        method: Method which we want to convert
        main_cls_name: Name of class to which method belongs
        static: Is method static

    Returns:
        ObjcMethod instance
    '''

    cdef char* method_name = <char*>sel_getName(method_getName(method))
    cdef char* method_args = <char*>method_getTypeEncoding(method)
    cdef basestring py_name = (<bytes>method_name).replace(b":", b"_").decode("utf-8")

    return py_name, ObjcMethod(<bytes>method_args, method_name, static=static, main_cls_name=main_cls_name)

cdef class_get_methods(Class cls, static=False, main_cls_name=None):
    cdef unsigned int index, num_methods
    cdef dict methods = {}
    cdef Method* class_methods = class_copyMethodList(cls, &num_methods)
    main_cls_name = main_cls_name or class_getName(cls)
    for i in xrange(num_methods):
        py_name, converted_method = objc_method_to_py(class_methods[i], main_cls_name, static)
        if py_name not in tmp_properties_keys:
            methods[py_name] = converted_method
        else:
            methods['__getter__' + py_name] = converted_method
    free(class_methods)
    return methods

cdef class_get_static_methods(Class cls, main_cls_name=None):
    cdef Class meta_cls = <Class>object_getClass(<id>cls)
    return class_get_methods(meta_cls, True, main_cls_name=main_cls_name)

cdef class_get_partial_methods(Class cls, methods, class_methods=True):
    ''' Function for copying only limited number of methods for some class

    Args:
        cls: Class for which we want to copy methods
        methods: Python array containing list of methods to copy
        class_methods: Are methods what we want to copy class or instance type

    Returns:
        Dict with methods
    '''

    cdef Method objc_method
    cdef dict static_methods_dict = {}

    for method in methods:
        if class_methods:
            objc_method = class_getClassMethod(cls, sel_registerName(method))
            static = True
        else:
            objc_method = class_getInstanceMethod(cls, sel_registerName(method))
            static = False
        py_name, converted_method = objc_method_to_py(objc_method, class_getName(cls), static=static)

        if py_name not in tmp_properties_keys:
            static_methods_dict[py_name] = converted_method
        else:
            static_methods_dict['__getter__' + py_name] = converted_method
    return static_methods_dict

cdef bytes class_get_super_class_name(Class cls):
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
    return ObjcMethod(<bytes><char*>method_getTypeEncoding(m_cls), name, static=True, \
        main_cls_name=class_getName(cls))

cdef resolve_super_class_methods(Class cls, instance_methods=True):
    """ Getting super classes methods of some class

    Args:
        cls: Class for which we will try to get super methods

    Returns:
        A dict with super methods
    """
    cdef dict super_cls_methods_dict = {}
    cdef Class cls_super = class_getSuperclass(<Class>cls)
    cdef object main_cls_name = class_getName(cls)
    super_cls_name = object_getClassName(<id>cls_super)

    while super_cls_name != b"nil":
        if(instance_methods):
            super_cls_methods_dict.update(class_get_methods(cls_super))
        else:
            super_cls_methods_dict.update(class_get_static_methods(cls_super, main_cls_name=main_cls_name))

        super_cls_name = class_get_super_class_name(cls_super)
        cls_super = <Class>objc_getClass(super_cls_name)

    return super_cls_methods_dict

cdef get_class_proerties(Class cls):
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
        props_dict[name] = ObjcProperty(<unsigned long long>&properties[i], prop_attrs, <unsigned long long>&ivar, name)
    return props_dict

def check_copy_properties(cls_name):
    ''' Function for checking value of __copy_properties__ attribute

    Returns:
        True if user want to copy properties, or false if he doesn't want to do that.
        Value None is returned if object haven't __copy_properties__ attribute
    '''
    if cls_name in oclass_register:
        if oclass_register[cls_name].get('class') is not None:
            return oclass_register[cls_name].get('class').__copy_properties__
    return None

def autoclass(py_cls_name, **kwargs):
    cdef bytes cls_name
    if isinstance(py_cls_name, bytes):
      cls_name = <bytes>py_cls_name
      py_cls_name = py_cls_name.decode("utf-8")
    else:
      cls_name = <bytes>py_cls_name.encode("utf-8")

    new_instance = kwargs.get('new_instance', False)
    load_class_methods_dict = kwargs.get('load_class_methods')
    load_instance_methods_dict = kwargs.get('load_instance_methods')
    reset_autoclass = kwargs.get('reset_autoclass')
    if not new_instance and load_instance_methods_dict:
        omethod_partial_register[cls_name] = load_instance_methods_dict

    if reset_autoclass:
        # TODO: Find better solution here!
        # Problem is because in some cases class and instance are having different names,
        # so, if there way to return instance name for some class
        # In that case we will del only class and instance from oclass_register and omethod_partial_register
        oclass_register.clear()
        omethod_partial_register.clear()
    # if class or class instance is already in cache, return requested value
    if cls_name in oclass_register and load_class_methods_dict is None \
        and load_instance_methods_dict is None and cls_name not in omethod_partial_register:
        if (not new_instance and "class" in oclass_register[cls_name]):
            dprint("getting class from cache...", of_type='i')
            return oclass_register[cls_name]['class']
        elif (new_instance and "instance" in oclass_register[cls_name]):
            dprint('getting instance from cache...', of_type='i')
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

    properties_dict = {}
    if copy_properties:
        properties_dict = get_class_proerties(cls)
        global tmp_properties_keys
        tmp_properties_keys[:] = properties_dict.keys()

    cdef dict instance_methods
    cdef dict class_methods
    cdef dict class_dict = {'__objcclass__':  cls_name, '__copy_properties__': copy_properties}

    # if this isn't new instance of some class, retrieve only static methods
    if not new_instance:
        if not load_class_methods_dict:
            class_methods = class_get_static_methods(cls)
            class_dict.update(resolve_super_class_methods(cls, instance_methods=False))
        else:
            class_methods = class_get_partial_methods(cls, load_class_methods_dict)
        class_dict.update(class_methods)
    # otherwise retrieve instance methods
    else:
        if not load_instance_methods_dict:
            instance_methods = class_get_methods(cls)
            class_dict.update(resolve_super_class_methods(cls))
        else:
            instance_methods = class_get_partial_methods(cls, load_instance_methods_dict, class_methods=False)
        class_dict.update(instance_methods)
        # for some reason, if we don't override this instance method with class method, it won't work correctly
        if not load_instance_methods_dict:
            class_dict.update({'isKindOfClass_': get_class_method(cls, 'isKindOfClass:')})

    if "class" in class_dict:
        class_dict.update({'oclass': class_dict['class']})
        class_dict.pop("class", None)

    class_dict.update(properties_dict)

    if not new_instance:
        return MetaObjcClass.__new__(MetaObjcClass, py_cls_name, (ObjcClassInstance, ObjcClassHlp), class_dict)()

    return MetaObjcClass.__new__(MetaObjcClass, py_cls_name, (ObjcClassInstance,), class_dict)


# -----------------------------------------------------------------------------
# Delegate implementation
#
# Since ARM64 introduction (iOS 8), delegate implementation are using the
# "slow" path of objective-c.
# We are not able anymore to declare a variadic function for responding to any
# kind of selector, as the ARM64 convention call differ from other platform,
# and va_start/arg/end doesn't work on ARM64 as well.
#
# Instead, we are manually using forwardInvocation:, named as the "slow" path.
# Ref: http://arigrant.com/blog/2013/12/13/a-selector-left-unhandled
#
# The idea is, when there is no implementation of a selector on the target,
# objc will forward the call to a forwardInvocation: selector on the target,
# containing the original invocation and parameters in a NSInvocation.
# For pyobjus, it's separated in 3 steps:
# - respondsToSelector: > the target class must indicate which selector is
#                         implemented in Python
# - methodSignatureForSelector: > the target class must return a
#                                 NSMethodSignature for the selector
# - forwardInvocation: > and then, the message will be passed to it

cdef get_python_delegate_from_id(id self):
    # returns a python delegate class from an objc instance
    cdef ObjcClassInstance objc_delegate
    for py_obj, objc_delegate in delegate_register.iteritems():
        if objc_delegate.o_instance != self:
            continue
        return py_obj


cdef BOOL protocol_respondsToSelector(id self, SEL _cmd, SEL selector) with gil:
    # return True if a python delegate class responds to a specific selector
    delegate = get_python_delegate_from_id(self)
    if not delegate:
        return 0
    py_method_name = sel_getName(selector).replace(':', '_')
    return hasattr(delegate, py_method_name)


cdef id protocol_methodSignatureForSelector(id self, SEL _cmd, SEL selector) with gil:
    # returns a method signature for a specific selector, needed for the
    # fallback forwardInvocation:
    cdef ObjcClassInstance sig
    sig_name = "_sig_{}".format(sel_getName(selector))
    delegate = get_python_delegate_from_id(self)
    if not delegate:
        return NULL

    if not hasattr(delegate, sig_name):
        # we didn't find a cached method signature, so create a new one.
        sel_name = sel_getName(selector)
        py_method_name = sel_name.replace(':', '_')

        protocol_name = getattr(delegate, py_method_name).__protocol__
        d = objc_protocol_get_delegates(protocol_name)
        sigs = d.get(sel_name)

        NSMethodSignature = autoclass("NSMethodSignature")
        sig = NSMethodSignature.signatureWithObjCTypes_(sigs[-1])
        setattr(delegate, sig_name, sig)
    else:
        sig = getattr(delegate, sig_name)

    return sig.o_instance


cdef id protocol_forwardInvocation(id self, SEL _cmd, id invocation) with gil:
    # Implementation of dynamically added protocol instance method.
    # This function dispatches the protocol method call to the corresponded
    # Python method implementation. It also convert Objective C arguments to
    # corresponded python objects.

    dprint('-' * 80)
    dprint('protocol_forwardInvocation called from Objective-C')
    dprint('pfi: id={} invocation={}'.format(pr(self), pr(invocation)))

    # get the invocation object
    cdef ObjcClassInstance inv = convert_to_cy_cls_instance(invocation)
    cdef ObjcSelector target_selector = inv.selector
    _cmd = target_selector.selector
    signature = inv.methodSignature
    py_method_args = []

    dprint("pfi: invocation target selector: {}".format(sel_getName(_cmd)))
    dprint("pfi: number of arguments: {}".format(signature.numberOfArguments))
    cdef id c_arg
    cdef Class cls = object_getClass(self)
    cdef long i
    cls_name = class_getName(cls)
    for i in range(2, signature.numberOfArguments):
        tp = signature.getArgumentTypeAtIndex_(i)
        dprint("pfi: argument type at {}: {}".format(i, tp))
        arg_type = type_encoding_to_ffitype(tp[0])
        dprint('pfi: convert arg {} with type {}'.format(i, tp[0]))
        c_arg = NULL
        inv.getArgument_atIndex_(<unsigned long long>&c_arg, i)
        py_arg = convert_cy_ret_to_py(&c_arg, tp[0],
                                      <size_t>arg_type.size, members=None,
                                      objc_prop=False, main_cls_name=cls_name)
        py_method_args.append(py_arg)

    # Calls the protocol method defined in Python object.
    # search the delegate object in our database
    delegate = get_python_delegate_from_id(self)
    if delegate:
        py_method_name = sel_getName(_cmd).replace(':', '_')
        py_method = getattr(delegate, py_method_name)
        py_method(*py_method_args)


def protocol(protocol_name):
    '''Mark the method as part of the implementation of the `protocol_name`.
    For example::

        class Ble(object):

            @protocol('CBCentralManagerDelegate')
            def centralManagerDidUpdateState_(self, central):
                print 'central updated!'

    And you can use the instance of Ble when you need a CBCentralManagerDelegate
    delegate.
    '''
    def f(subf):
        def f2(*args, **kwargs):
            return subf(*args, **kwargs)
        f2.__protocol__ = protocol_name
        return f2
    return f


def objc_protocol_get_delegates(protocol_name):
    cdef objc_method_description* descs
    cdef Protocol *protocol
    cdef unsigned int num_descs
    cdef objc_method_description desc

    # try to find the protocol in the executable
    protocol = objc_getProtocol(protocol_name)
    dprint('  protocol found?', protocol != NULL)
    if protocol != NULL:
        delegates_types = {}
        # get non-required methods
        descs = protocol_copyMethodDescriptionList(
                protocol, NO, YES, &num_descs)
        for i in xrange(num_descs):
            desc = descs[i]
            selector = desc.name
            selector_name = sel_getName(selector)
            delegates_types[selector_name] = [desc.types, desc.types]
        free(descs)
        # get required methods
        descs = protocol_copyMethodDescriptionList(
                protocol, YES, YES, &num_descs)
        for i in xrange(num_descs):
            desc = descs[i]
            selector = desc.name
            selector_name = sel_getName(selector)
            delegates_types[selector_name] = [desc.types, desc.types]
        free(descs)
        return delegates_types

    # not found, try to search in the user-build protocols
    from .protocols import protocols
    if protocol_name in protocols:
        return protocols.get(protocol_name)


cdef ObjcClassInstance objc_create_delegate(py_obj):
    '''Converts Python delegate instance to Objective C delegate instance.

    This function dynamically creates a new Objective C class and adds
    desired protocol methods that implemented in the passed py_obj.

    The instance passed as `py_obj` must have at least one decorated method with
    :func:`protocol`, or an :class:`ObjcException` will be throw.

    :arg py_obj: The instance of Python delegate class.
    :returns: A python object of the corresponded Objective C delegate instance.
    '''
    if not isinstance(py_obj, object):
        raise ObjcException('Delegate must be an instantiated class')

    cls_name = py_obj.__class__.__name__

    # Returns the cached delegate instance if exists for the current py_obj
    # to release unused instances.
    if py_obj in delegate_register:
        return delegate_register[py_obj]

    # Creates an Objective C class inherited from NSObject and added protocol
    # methods implemented in py_obj.
    cdef Class superclass = <Class>objc_getClass(b'NSObject')
    cdef Class objc_cls = <Class>objc_allocateClassPair(
            superclass, cls_name, 0)
    cdef SEL selector
    cdef char* method_args
    cdef dict delegates = {}
    cdef int protocol_found = 0

    dprint('create delegate from {!r}'.format(py_obj))

    # XXX this was the code for older delegate creatieon
    # it doesn't do anything concrete except ensuring there is atleast one
    # protocol found, and that all the selector have a signature associated to
    # it.
    for funcname in dir(py_obj):
        func = getattr(py_obj, funcname)
        if not hasattr(func, '__protocol__'):
            continue
        protocol_found = 1

        protocol_name = func.__protocol__
        dprint('  - found a @protocol {} for {}'.format(
            protocol_name, funcname))

        d = delegates.get(protocol_name, None)
        if d is None:
            delegates[protocol_name] = d = objc_protocol_get_delegates(protocol_name)
        if d is None:
            raise ObjcException('Undeclared protocol {}'.format(protocol_name))

        selector_name = funcname.replace('_', ':')
        dprint('    search the selector {}'.format(selector_name))
        sigs = d.get(selector_name)
        if not sigs:
            dprint('    selector {} not found'.format(selector_name))
            dprint('-- list of available selector for {} --'.format(protocol_name))
            for val in d:
                dprint('  * {}'.format(val))
            raise ObjcException('Protocol {} does not have any selector named {}'.format(
                protocol_name, selector_name))

    if protocol_found == 0:
        raise ObjcException(
            "You've passed {!r} as delegate, but there is "
            "no @protocol methods declared.".format(
                py_obj))

    dprint('   register methodSignatureForSelector:')
    class_addMethod(
        objc_cls, sel_registerName("methodSignatureForSelector:"),
        <IMP>&protocol_methodSignatureForSelector, "@@::")
    dprint('   register forwardInvocation:')
    class_addMethod(
        objc_cls, sel_registerName("forwardInvocation:"),
        <IMP>&protocol_forwardInvocation, "v@:@")
    dprint('   register respondsToSelector:')
    class_addMethod(
        objc_cls, sel_registerName("respondsToSelector:"),
        <IMP>&protocol_respondsToSelector, "v@::")

    objc_registerClassPair(objc_cls)

    cdef dict class_dict = {'__objcclass__':  cls_name,
                            '__copy_properties__': False}
    # Loads alloc and init method for instantiate the delegate class.
    class_dict.update(class_get_partial_methods(objc_cls, ['alloc']))
    class_dict.update(class_get_partial_methods(objc_cls, ['init'], False))
    # Loads created protocol methods.
    # XXX as a delegate, i don't think python need an access to it directly.
    #class_dict.update(class_get_methods(objc_cls))

    if "class" in class_dict:
        class_dict.update({'oclass': class_dict['class']})
        class_dict.pop("class", None)

    meta_object_cls = MetaObjcClass.__new__(MetaObjcClass, cls_name,
                                            (ObjcClassInstance,),
                                            class_dict)
    cdef ObjcClassInstance objc_instance = meta_object_cls.alloc().init()
    delegate_register[py_obj] = objc_instance

    return objc_instance

def symbol(name, clsname):
    # search a symbol from loaded binaries
    try:
        addr = ctypes.c_void_p.in_dll(ctypes.pythonapi, name).value
    except ValueError:
        return None

    cdef ObjcClassInstance cret
    cret = autoclass(clsname)(noinstance=True)
    cret.instanciate_from(<id>addr, retain=0)
    return cret
