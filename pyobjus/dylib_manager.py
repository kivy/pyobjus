import os
import ctypes

def load_usr_lib(path, usr_path=True):
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
