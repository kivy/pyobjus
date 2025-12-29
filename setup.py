from setuptools import setup, Extension
from os import environ, walk
from os.path import dirname, join, exists
import sys
import platform
from Cython.Distutils import build_ext

with open(join('pyobjus', '__init__.py')) as fd:
    VERSION = [
        x for x in fd.readlines()
        if x.startswith('__version__')
    ][0].split("'")[-2]

arch = environ.get('ARCH', platform.machine())

print("Pyobjus platform is {}".format(sys.platform))

files = ['pyobjus.pyx']


class PyObjusBuildExt(build_ext, object):

    def build_extensions(self):
        # create a configuration file for pyobjus (export the platform)
        config_pxi_fn = join(dirname(__file__), 'pyobjus', 'config.pxi')
        config_pxi_need_update = True
        config_pxi = 'DEF PLATFORM = "{}"\n'.format(sys.platform)
        config_pxi += 'DEF ARCH = "{}"\n'.format(arch)
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

if sys.platform == "ios":
    ios_ver = platform.ios_ver()
    ios_deps_path = join(dirname(__file__), "ios-deps-install")

    # Check if the ios-deps-install directory exists
    if not exists(ios_deps_path):
        raise RuntimeError(
            "iOS dependencies not found. Please run the .ci/build_ios_dependencies.sh script to build them."
        )

    ffi_lib_path = join(
        ios_deps_path,
        "iphonesimulator" if ios_ver.is_simulator else "iphoneos",
        arch,
    )
    library_dirs.append(join(ffi_lib_path, "lib"))
    include_dirs.append(join(ffi_lib_path, "include"))
    include_dirs.append(join(ffi_lib_path, "include", "ffi"))
    libraries.append('objc')

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
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'Programming Language :: Python :: 3.12',
        'Programming Language :: Python :: 3.13',
        'Programming Language :: Python :: 3.14',
        'Topic :: Software Development :: Libraries :: Application Frameworks'
    ],
)
