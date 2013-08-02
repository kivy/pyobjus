import os
import ctypes
import pyobjus
from objc_py_types import enum
from debug import dprint

def load_dylib(path, usr_path=True):
    ''' Function for loading dynamic library with ctypes

    Args:
        path: Path to user defined library
        abs_path: If setted to True, pyobjus will load library with absolute path provided by user -> path arg
        Otherwise it will look in /objc_usr_classes dir, which is in pyobjus root dir

    Note:
        This isn't finished, only started implementation!
    '''

    # LOADING USER DEFINED CLASS (dylib) FROM /objc_usr_classes/ DIR #
    if not usr_path:
        if os.getcwd().split('/')[-1] != 'pyobjus':
            os.chdir('..')
            while os.getcwd().split('/')[-1] != 'pyobjus':
                os.chdir('..')
        root_pyobjus = os.getcwd()
        usrlib_dir = root_pyobjus + '/objc_usr_classes/' + path
        ctypes.CDLL(usrlib_dir)
    else:
        ctypes.CDLL(path)

def make_dylib(path):
    pass

frameworks = dict(
    Foundation = '/System/Library/Frameworks/Foundation.framework',
    AppKit = '/System/Library/Frameworks/AppKit.framework',
    UIKit = '/System/Library/Frameworks/UIKit.framework',
    CoreGraphich = '/System/Library/Frameworks/CoreGraphics.framework',
    CoreData = '/System/Library/Frameworks/CoreData.framework'
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
            dprint("Framework {0} succesufully loaded!".format(framework), type='d')
    except:
        raise pyobjus.ObjcException('Error while loading {0} framework'.format(framework))
