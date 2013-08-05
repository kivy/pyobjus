from pyobjus import autoclass
from pyobjus.dylib_manager import load_framework, make_dylib, load_dylib, INCLUDE

load_framework(INCLUDE.AppKit)
# this is loaded by default
load_framework(INCLUDE.Foundation)
# if you run this on osx, it will throw ObjcException, because this is iOS framework
# load_framework(INCLUDE.UIKit)

# If framework this you want to load is not present with this quick load method,
# you can load it by providing path to .framework
# load_framework('/path/to/framework')

# with this function pyobjus will make .dylib for us
make_dylib('objc_lib.m', frameworks=['Foundation'], options=['-current_version', '1.0'])
# after he made it, we can load .dylib into out program
load_dylib('objc_lib.dylib')
# and we can use classes from loaded .dylib
ObjcClass = autoclass('ObjcClass')
# and call methods of loaded classes
ObjcClass.alloc().init().printFromObjectiveC()
