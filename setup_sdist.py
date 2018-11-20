'''
Setup.py only for creating a source distributions.

This file holds all the common setup.py keyword arguments between the source
distribution and the ordinary setup.py for binary distribution. Running this
instead of the default setup.py will create a GitHub-like archive with setup.py
meant for installing via pip.
'''

# pylint: disable=import-error,no-name-in-module
from distutils.core import setup
from os import walk
from os.path import join, dirname


with open(join('pyobjus', '__init__.py')) as fd:
    VERSION = [
        x for x in fd.readlines()
        if x.startswith('__version__')
    ][0].split("'")[-2]

data_allowed_ext = (
    'readme', 'py', 'wav', 'png', 'jpg', 'svg', 'json', 'avi', 'gif', 'txt',
    'ttf', 'obj', 'mtl', 'kv', 'mpg', 'glsl', 'zip', 'h', 'm'
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

SETUP_KWARGS = {
    'name': 'pyobjus',
    'version': VERSION,
    'packages': ['pyobjus', 'pyobjus.consts'],
    'py_modules': ['setup'],
    'ext_package': 'pyobjus',
    'data_files': [
        item
        for data in [
            list(tree('examples').items()),
            list(tree('objc_classes', tree_name='objc_classes/').items())
        ]
        for item in data
    ],
    'classifiers': [
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Natural Language :: English',
        'Operating System :: MacOS',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Topic :: Software Development :: Libraries :: Application Frameworks'
    ]
}

if __name__ == '__main__':
    setup(**SETUP_KWARGS)
