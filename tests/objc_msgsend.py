import ctypes
import ctypes.util
import sys

_objc_path = ctypes.util.find_library('objc') if sys.platform == 'darwin' else None
OBJC = None
if _objc_path:
    OBJC = ctypes.cdll.LoadLibrary(_objc_path)
    OBJC.sel_registerName.restype = ctypes.c_void_p
    OBJC.sel_registerName.argtypes = [ctypes.c_char_p]


def msg_send(restype, target, sel_name, *args):
    """Call objc_msgSend directly, bypassing pyobjus. Pointer-sized args only.

    target and args may be pyobjus objects or raw addresses.
    """
    sel = OBJC.sel_registerName(
        sel_name.encode('utf8') if isinstance(sel_name, str) else sel_name)
    argtypes = [ctypes.c_void_p, ctypes.c_void_p] + [
        ctypes.c_void_p] * len(args)
    fn = ctypes.CFUNCTYPE(restype, *argtypes)(('objc_msgSend', OBJC))
    call_args = [target.get_address() if hasattr(target, 'get_address')
                 else target, sel]
    for a in args:
        call_args.append(a.get_address() if hasattr(a, 'get_address') else a)
    return fn(*call_args)
