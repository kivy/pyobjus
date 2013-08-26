from distutils.core import setup, Extension
from os import environ
from os.path import dirname, join
import sys

platform = sys.platform
kivy_ios_root = environ.get('KIVYIOSROOT', None)
if kivy_ios_root is not None:
    platform = 'ios'

if platform == 'darwin':
    try:
        from Cython.Distutils import build_ext
    except ImportError:
        raise
    files = ['pyobjus.pyx']
elif platform == 'ios':
    from distutils.command.build_ext import build_ext
    files = ['pyobjus.c']

print "pl"*100
print platform

libraries = ['ffi']
library_dirs = []
extra_compile_args = []
extra_link_args = []
include_dirs = []

# create the extension
setup(name='pyobjus',
        version='1.0',
        cmdclass={'build_ext': build_ext},
        packages=['pyobjus'],
        ext_package='pyobjus',
        ext_modules=[
        Extension(
            'pyobjus', [join('pyobjus', x) for x in files],
            libraries=libraries,
            library_dirs=library_dirs,
            include_dirs=include_dirs,
            extra_link_args=extra_link_args)
        ]
     )
