'''
Tools to allow reading const ObjC values. See pyobjus.consts.corebluetooth for
an example of usage.

Under normal circumstances, this is just a convoluted way to generate a class
with attributes containing the default values.

But with 'PYOBJUS_DEV' in the environment, this will instead automatically
generate an ObjC source file, defining a class with getter methods returning
the requested values. That source will then be built using make_dylib, loaded
via load_dylib, and wrapped to provide the same interface as the normal class.

In addition, a report will be printed to the console showing the values from
the generated class::

    ObjC Const Report - CBAdvertisementDataKeys
    ===========================================
    LocalName = (NSString*)'kCBAdvDataLocalName'
    ManufacturerData = (NSString*)'kCBAdvDataManufacturerData'
    ServiceUUIDs = (NSString*)'kCBAdvDataServiceUUIDs'

This is done to provide the values so that the defaults can be set
appropriately for release.

Note that this has only been tested with NSString* values, and may need
adjustment to work with other types.
'''
from __future__ import print_function, absolute_import

from os import makedirs, environ
from os.path import expanduser, join, exists, getmtime
from hashlib import md5

from pyobjus import autoclass
from ..dylib_manager import make_dylib, load_dylib

try:
    from six import with_metaclass
except ImportError:
    def with_metaclass(meta, *bases):
        """Create a base class with a metaclass."""
        # This requires a bit of explanation: the basic idea is to make a dummy
        # metaclass for one level of class instantiation that replaces itself with
        # the actual metaclass.
        class metaclass(meta):

            def __new__(cls, name, this_bases, d):
                return meta(name, bases, d)
        return type.__new__(metaclass, 'temporary_class', (), {})


const_m_template = '''\
{imports}

@interface {name} : NSObject
@end

@implementation {name}

{props}
@end
'''

const_m_import_template = '#import <{0}/{0}.h>'

const_m_prop_template = '''\
+ ({type}) get{key} {{
    return {const};
}}
'''


def load_consts(name, frameworks=None, properties=None):
    frameworks = ['Foundation'] + (frameworks or [])
    properties = properties or {}

    keys = []
    consts = {}
    types = {}
    defaults = {}
    for k, v in properties.items():
        keys.append(k)
        consts[k], types[k], defaults[k] = v

    if 'PYOBJUS_DEV' in environ:
        libdir = expanduser('~/.pyobjus/libs')
        if not exists(libdir):
            makedirs(libdir)

        src_file = join(libdir, name + '.src')
        m_file = join(libdir, name + '.m')
        dylib_file = join(libdir, name + '.dylib')

        src_data = md5(str((name, frameworks, consts))).digest()
        force_rebuild = True
        if exists(src_file):
            with open(src_file) as f:
                prev_src_data = f.read()
            if src_data == prev_src_data:
                force_rebuild = False

        if (force_rebuild or not exists(dylib_file) or
                getmtime(dylib_file) < getmtime(src_file)):
            with open(src_file, 'w') as f:
                f.write(src_data)

            with open(m_file, 'w') as f:
                imports = '\n'.join([const_m_import_template.format(fw)
                                     for fw in frameworks])
                props = '\n'.join([const_m_prop_template.format(type=types[k],
                                                                key=k,
                                                                const=consts[k])
                                   for k in keys])
                f.write(const_m_template.format(imports=imports, name=name,
                                                props=props))

            try:
                make_dylib(m_file, frameworks=frameworks)
            except Exception:
                # might just not be writable, in which case if the file
                # exists we can load it below, otherwise load_dylib()
                # will throw an exception anyway
                print('failed to make dylib -', name)

        try:
            load_dylib(dylib_file)
            objc_class = autoclass(name)

            class wrapper(object):
                def __getattr__(self, item):
                    try:
                        value = getattr(objc_class, 'get' + item)
                    except AttributeError:
                        return object.__getattribute__(self, item)
                    else:
                        value = value()
                        try:
                            if hasattr(value, 'cString'):
                                return value.cString()
                            elif hasattr(value, 'floatValue'):
                                return value.floatValue()
                        except Exception:
                            pass
                        return value
            wrapper.__name__ = name
            rv = wrapper()

            print('ObjC Const Report -', name)
            print('=' * (len(name) + 20))
            for k in keys:
                try:
                    v = repr(getattr(rv, k))
                except Exception as e:
                    v = str(e)
                print('{} = ({}){}'.format(k, types[k], v))
            print()

            return rv
        except Exception:
            # we don't care what the exception was, just use the defaults
            print('failed to load dylib -', name)

    return type(name, (object,), defaults)()


class Const(object):
    def __init__(self, name, default='', type='NSString*'):
        self.spec = name, type, default


class ObjcConstMeta(type):
    def __new__(cls, name, bases, dct):
        if name == 'ObjcConstType':
            return super(ObjcConstMeta, cls).__new__(cls, name, bases, dct)

        frameworks = []
        props = {}
        for k, v in dct.items():
            if k == 'frameworks':
                frameworks = v
            elif isinstance(v, Const):
                props[k] = v.spec

        rv = load_consts(name, frameworks, props)
        rv.__doc__ = dct.get('__doc__', '')
        return rv


class ObjcConstType(with_metaclass(ObjcConstMeta)):
    __abstract__ = True

    frameworks = []

