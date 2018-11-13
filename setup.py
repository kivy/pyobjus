from distutils.core import setup, Extension
from os import environ
from os.path import dirname, join, exists
import sys
import subprocess
import platform
from setup_sdist import SETUP_KWARGS

dev_platform = sys.platform
kivy_ios_root = environ.get('KIVYIOSROOT', None)
arch = environ.get('ARCH', platform.machine())
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

# create a configuration file for pyobjus (export the platform)
config_pxi_fn = join(dirname(__file__), 'pyobjus', 'config.pxi')
config_pxi_need_update = True
config_pxi = 'DEF PLATFORM = "{}"\n'.format(dev_platform)
config_pxi += 'DEF ARCH = "{}"'.format(arch)
if exists(config_pxi_fn):
    with open(config_pxi_fn) as fd:
        config_pxi_need_update = fd.read() != config_pxi
if config_pxi_need_update:
    with open(config_pxi_fn, 'w') as fd:
        fd.write(config_pxi)

# if dev_platform` == 'ios':
#     subprocess.`call(['find', '.', '-name', '*.pyx', '-exec', 'cython', '{}', ';'])

libraries = ['ffi']
library_dirs = []
extra_compile_args = []
extra_link_args = []
include_dirs = []
depends = [join('pyobjus', x) for x in (
    'common.pxi',
    'config.pxi',
    'debug.pxi',
    'pyobjus_conversions.pxi',
    'pyobjus_types.pxi',
    'type_enc.pxi',
    'pyobjus.pyx')]

# create the extension
setup(
    cmdclass={'build_ext': build_ext},
    ext_modules=[
        Extension(
            'pyobjus', [join('pyobjus', x) for x in files],
            depends=depends,
            libraries=libraries,
            library_dirs=library_dirs,
            include_dirs=include_dirs,
            extra_link_args=extra_link_args
        )
    ],
    **SETUP_KWARGS
)
