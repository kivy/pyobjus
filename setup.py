from distutils.core import setup, Extension
from os import environ
from os.path import dirname, join
import sys
import subprocess

def line_prepender(filename, line):
    with open(filename,'r+') as f:
        platform_defined = f.readline().split('=', 1)[0].strip() == 'dev_platform'
        if not platform_defined:
            f.seek(0, 0)
            content = f.read()
            f.seek(0, 0)
            f.write(line.rstrip('\r\n') + '\n' + content)

dev_platform = sys.platform
kivy_ios_root = environ.get('KIVYIOSROOT', None)
if kivy_ios_root is not None:
    dev_platform = 'ios'

# OSX
if dev_platform == 'darwin':
    try:
        from Cython.Distutils import build_ext
    except ImportError:
        raise
    files = ['pyobjus.pyx']
# iOS
elif dev_platform == 'ios':
    from distutils.command.build_ext import build_ext
    files = ['pyobjus.c']

# append info about platform on first line of pyobjus.pyx
line_prepender('pyobjus/pyobjus.pyx', 'dev_platform = "{0}"'.format(dev_platform))

if dev_platform == 'ios':
    subprocess.call(['find', '.', '-name', '*.pyx', '-exec', 'cython', '{}', ';'])

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
