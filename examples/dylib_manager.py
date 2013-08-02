from pyobjus import autoclass
from pyobjus.dylib_manager import load_framework, INCLUDE

load_framework(INCLUDE.AppKit)
# this is loaded by default
load_framework(INCLUDE.Foundation)
# if you run this on osx, it will throw ObjcException, because this is iOS framework
# load_framework(INCLUDE.UIKit)

# If framework this you want to load is not present with this quick load method,
# you can load it by providing path to .framework
# load_framework('/path/to/framework')
