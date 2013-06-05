from distutils.core import setup, Extension
from os import environ
from os.path import dirname, join
import sys

from Cython.Distutils import extension


files = ['pyobjus.pyx']
libraries = ["ffi"]
library_dirs = []
extra_compile_args = []
extra_link_args = []
include_dirs = []

# detect cython
try:
    from Cython.Distutils import build_ext
except ImportError:
    raise

# create the extension
setup(name='pyobjus',
        version='1.0',
        cmdclass={'build_ext': build_ext},
        packages=['pyobjus'],
        ext_package='pyobjus',
        ext_modules=[
        Extension(
            'pyobjus', [join('pyobjus', x) for x in files],
            pyrex_gdb=True,
            libraries=libraries,
            library_dirs=library_dirs,
            include_dirs=include_dirs,
            extra_link_args=extra_link_args)
        ]
     )


