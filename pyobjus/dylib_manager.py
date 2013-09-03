import os
import ctypes
import pyobjus
from subprocess import call
from objc_py_types import enum
from debug import dprint

def load_dylib(path, **kwargs):
    ''' Function for loading dynamic library with ctypes

    Args:
        path: Path to user defined library
        abs_path: If setted to True, pyobjus will load library with absolute path provided by user -> path arg
        Otherwise it will look in /objc_usr_classes dir, which is in pyobjus root dir

    Note:
        Work in progress
    '''

    # LOADING USER DEFINED CLASS (dylib) FROM /objc_usr_classes/ DIR #
    usr_path = kwargs.get('usr_path', True)
    if not usr_path:
        if os.getcwd().split('/')[-1] != 'pyobjus':
            os.chdir('..')
            while os.getcwd().split('/')[-1] != 'pyobjus':
                os.chdir('..')
        root_pyobjus = os.getcwd()
        objc_test_dir = os.path.join(root_pyobjus, 'objc_classes', 'test')
        ctypes.CDLL(os.path.join(objc_test_dir, path))
    else:
        ctypes.CDLL(path)
    dprint("Dynamic library {0} loaded".format(path))

def make_dylib(path, **kwargs):
    ''' Function for making .dylib from some .m file

    Args:
        path: Path to some .m file which we want to convert to .dylib

    Note:
        Work in progress
    '''
    frameworks = kwargs.get('frameworks', None)
    out = kwargs.get('out', None)
    additional_opts = kwargs.get('options', None)

    if not out:
        out = '.'.join([os.path.splitext(path)[0], 'dylib'])
    arg_list = ["clang", path, "-o", out, "-dynamiclib"]
    if additional_opts is not None:
        arg_list = arg_list + additional_opts
    if frameworks:
        for framework in frameworks:
            arg_list.append('-framework')
            arg_list.append(framework)
    call(arg_list)

frameworks = dict(
    Foundation = '/System/Library/Frameworks/Foundation.framework',
    AppKit = '/System/Library/Frameworks/AppKit.framework',
    UIKit = '/System/Library/Frameworks/UIKit.framework',
    CoreGraphich = '/System/Library/Frameworks/CoreGraphics.framework',
    CoreData = '/System/Library/Frameworks/CoreData.framework',
    CoreMotion = '/System/Library/Frameworks/CoreMotion.framework'
    # TODO: Add others common frameworks!
)

INCLUDE = enum('pyobjus_include', **frameworks)

def load_framework(framework):
    ''' Function for loading frameworks

    Args:
        framework: Framework to load

    Raises:
        ObjcException if it can't load framework
    '''
    NSBundle = pyobjus.autoclass('NSBundle')
    ns_framework = pyobjus.autoclass('NSString').stringWithUTF8String_(framework)
    bundle = NSBundle.bundleWithPath_(ns_framework)
    try:
        if bundle.load():
            dprint("Framework {0} succesufully loaded!".format(framework))
    except:
        raise pyobjus.ObjcException('Error while loading {0} framework'.format(framework))
