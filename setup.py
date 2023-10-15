from setuptools import setup, Extension
from os import environ, walk
from os.path import dirname, join, exists
import sys
import platform
from distutils.command.build_ext import build_ext

with open(join('pyobjus', '__init__.py')) as fd:
    VERSION = [
        x for x in fd.readlines()
        if x.startswith('__version__')
    ][0].split("'")[-2]

dev_platform = sys.platform
kivy_ios_root = environ.get('KIVYIOSROOT', None)
arch = environ.get('ARCH', platform.machine())
if kivy_ios_root is not None:
    dev_platform = 'ios'

print("Pyobjus platform is {}".format(dev_platform))

# OSX
files = []
if dev_platform == 'darwin':
    files = ['pyobjus.pyx']
# iOS
elif dev_platform == 'ios':
    files = ['pyobjus.c']


class PyObjusBuildExt(build_ext, object):

    def __new__(cls, *a, **kw):
        # Note how this class is declared as a subclass of distutils
        # build_ext as the Cython version may not be available in the
        # environment it is initially started in. However, if Cython
        # can be used, setuptools will bring Cython into the environment
        # thus its version of build_ext will become available.
        # The reason why this is done as a __new__ rather than through a
        # factory function is because there are distutils functions that check
        # the values provided by cmdclass with issublcass, and so it would
        # result in an exception.
        # The following essentially supply a dynamically generated subclass
        # that mix in the cython version of build_ext so that the
        # functionality provided will also be executed.
        if dev_platform != 'ios':
            from Cython.Distutils import build_ext as cython_build_ext
            build_ext_cls = type(
                'PyObjusBuildExt', (PyObjusBuildExt, cython_build_ext), {})
            return super(PyObjusBuildExt, cls).__new__(build_ext_cls)
        else:
            return super(PyObjusBuildExt, cls).__new__(cls)

    def build_extensions(self):
        # create a configuration file for pyobjus (export the platform)
        config_pxi_fn = join(dirname(__file__), 'pyobjus', 'config.pxi')
        config_pxi_need_update = True
        config_pxi = 'DEF PLATFORM = "{}"\n'.format(dev_platform)
        config_pxi += 'DEF ARCH = "{}"\n'.format(arch)
        if dev_platform == 'ios':
            cython3 = False # Assume Cython 0.29, which is what we use for kivy-ios (ATM)
        else:
            import Cython
            cython3 = Cython.__version__.startswith('3.')
        config_pxi += f"DEF PYOBJUS_CYTHON_3 = {cython3}"
        if exists(config_pxi_fn):
            with open(config_pxi_fn) as fd:
                config_pxi_need_update = fd.read() != config_pxi
        if config_pxi_need_update:
            with open(config_pxi_fn, 'w') as fd:
                fd.write(config_pxi)

        super().build_extensions()


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

data_allowed_ext = (
    'readme', 'py', 'wav', 'png', 'jpg', 'svg', 'json', 'avi', 'gif', 'txt',
    'ttf', 'obj', 'mtl', 'kv', 'mpg', 'glsl', 'zip', 'h', 'm', 'md',
)


def tree(source, allowed_ext=data_allowed_ext, tree_name='share/pyobjus-'):
    found = {}

    for root, subfolders, files in walk(source):
        for fn in files:
            ext = fn.split('.')[-1].lower()
            if ext not in allowed_ext:
                continue
            filename = join(root, fn)
            directory = '%s%s' % (tree_name, dirname(filename))
            if directory not in found:
                found[directory] = []
            found[directory].append(filename)
    return found


# create the extension
setup(
    name='pyobjus',
    version=VERSION,
    packages=['pyobjus', 'pyobjus.consts'],
    ext_package='pyobjus',
    data_files=[
        item
        for data in [
            list(tree('examples').items()),
            list(tree('objc_classes', tree_name='objc_classes/').items())
        ]
        for item in data
    ],
    cmdclass={'build_ext': PyObjusBuildExt},
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
    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Natural Language :: English',
        'Operating System :: MacOS',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'Programming Language :: Python :: 3.12',
        'Topic :: Software Development :: Libraries :: Application Frameworks'
    ],
)
